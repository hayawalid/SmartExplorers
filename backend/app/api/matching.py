"""
Database Integration and API Endpoints for Smart Matching System
Integrates with MongoDB and provides FastAPI endpoints
"""

from fastapi import APIRouter, HTTPException, Depends, Query
from typing import List, Dict, Any, Optional
from datetime import datetime
from motor.motor_asyncio import AsyncIOMotorClient, AsyncIOMotorDatabase
from pydantic import BaseModel, Field
import os

from app.services.smart_matching_engine import SmartMatchingEngine, MatchResult

from app.models.mongodb_models import UserModel, TravelerProfileModel, ServiceProviderProfileModel



# ==================== Pydantic Models for API ====================

class TravelDateRange(BaseModel):
    """Travel date range"""
    start_date: datetime
    end_date: datetime


class MatchRequest(BaseModel):
    """Request for finding matches"""
    user_email: str
    travel_dates: Optional[List[TravelDateRange]] = None
    top_k: int = Field(default=10, ge=1, le=50)
    include_providers: bool = True
    include_travelers: bool = True


class MatchResponseItem(BaseModel):
    """Single match result"""
    user_id: str
    email: str
    full_name: str
    account_type: str
    match_score: float
    match_reasons: List[str]
    common_interests: List[str]
    common_languages: List[str]
    common_dates: List[str]
    budget_compatibility: float
    safety_score: float
    demographics_bonus: float
    cluster_id: int
    profile_picture_url: Optional[str] = None
    bio: Optional[str] = None


class MatchResponse(BaseModel):
    """Response containing matches"""
    target_user: str
    total_matches: int
    matches: List[MatchResponseItem]
    statistics: Dict[str, Any]


class TrainClusterRequest(BaseModel):
    """Request to retrain clustering model"""
    n_clusters: int = Field(default=5, ge=2, le=20)


# ==================== Router ====================

router = APIRouter(prefix="/api/matching", tags=["Matching"])


# ==================== Database Dependency ====================

async def get_database() -> AsyncIOMotorDatabase:
    """Get MongoDB database connection"""
    mongodb_url = os.getenv("MONGODB_URL", "mongodb://localhost:27017")
    client = AsyncIOMotorClient(mongodb_url)
    db = client.travel_app
    return db


# ==================== Matching Engine Instance ====================

# Global matching engine instance
matching_engine = SmartMatchingEngine(
    openai_api_key=os.getenv("OPENAI_API_KEY")
)

# Flag to track if model is trained
_model_trained = False


# ==================== Helper Functions ====================

async def fetch_all_users(db: AsyncIOMotorDatabase) -> List[Dict[str, Any]]:
    """
    Fetch all users with their profiles from MongoDB
    
    Args:
        db: MongoDB database
        
    Returns:
        List of user dictionaries with embedded profiles
    """
    users = []
    
    # Fetch all users
    users_cursor = db.users.find({"is_active": True, "is_banned": False})
    
    async for user in users_cursor:
        user_dict = {
            "_id": str(user["_id"]),
            "email": user.get("email"),
            "username": user.get("username"),
            "full_name": user.get("full_name"),
            "account_type": user.get("account_type"),
            "verified_flag": user.get("verified_flag", False),
            "profile_picture_url": user.get("profile_picture_url"),
            "bio": user.get("bio"),
        }
        
        # Fetch profile based on account type
        if user["account_type"] == "traveler":
            profile = await db.traveler_profiles.find_one({"user_id": str(user["_id"])})
            if profile:
                # Convert MongoDB document to dict
                profile_dict = dict(profile)
                profile_dict.pop("_id", None)
                profile_dict.pop("user_id", None)
                user_dict["profile"] = profile_dict
        else:  # service_provider
            profile = await db.provider_profiles.find_one({"user_id": str(user["_id"])})
            if profile:
                profile_dict = dict(profile)
                profile_dict.pop("_id", None)
                profile_dict.pop("user_id", None)
                user_dict["provider_profile"] = profile_dict
        
        # Fetch travel dates if available (you may need to add this collection)
        # For now, we'll skip this as it's not in the schema
        user_dict["travel_dates"] = []
        
        users.append(user_dict)
    
    return users


async def fetch_user_by_email(db: AsyncIOMotorDatabase, email: str) -> Optional[Dict[str, Any]]:
    """
    Fetch a single user with profile by email
    
    Args:
        db: MongoDB database
        email: User email
        
    Returns:
        User dictionary with embedded profile or None
    """
    user = await db.users.find_one({"email": email, "is_active": True})
    
    if not user:
        return None
    
    user_dict = {
        "_id": str(user["_id"]),
        "email": user.get("email"),
        "username": user.get("username"),
        "full_name": user.get("full_name"),
        "account_type": user.get("account_type"),
        "verified_flag": user.get("verified_flag", False),
        "profile_picture_url": user.get("profile_picture_url"),
        "bio": user.get("bio"),
    }
    
    # Fetch profile
    if user["account_type"] == "traveler":
        profile = await db.traveler_profiles.find_one({"user_id": str(user["_id"])})
        if profile:
            profile_dict = dict(profile)
            profile_dict.pop("_id", None)
            profile_dict.pop("user_id", None)
            user_dict["profile"] = profile_dict
    else:
        profile = await db.provider_profiles.find_one({"user_id": str(user["_id"])})
        if profile:
            profile_dict = dict(profile)
            profile_dict.pop("_id", None)
            profile_dict.pop("user_id", None)
            user_dict["provider_profile"] = profile_dict
    
    # Fetch travel dates (add this when you implement the collection)
    user_dict["travel_dates"] = []
    
    return user_dict


def match_result_to_response(match: MatchResult, user_dict: Dict[str, Any]) -> MatchResponseItem:
    """
    Convert a MatchResult and user dict to API response format
    
    Args:
        match: MatchResult object
        user_dict: User dictionary
        
    Returns:
        MatchResponseItem for API response
    """
    return MatchResponseItem(
        user_id=user_dict.get("_id", ""),
        email=match.matched_user_id,
        full_name=user_dict.get("full_name", "Unknown"),
        account_type=user_dict.get("account_type", "unknown"),
        match_score=match.match_score,
        match_reasons=match.match_reasons,
        common_interests=match.common_interests,
        common_languages=match.common_languages,
        common_dates=match.common_dates,
        budget_compatibility=match.budget_compatibility,
        safety_score=match.safety_score,
        demographics_bonus=match.demographics_bonus,
        cluster_id=match.cluster_id,
        profile_picture_url=user_dict.get("profile_picture_url"),
        bio=user_dict.get("bio")
    )


# ==================== API Endpoints ====================

@router.post("/train", summary="Train or retrain the clustering model")
async def train_matching_model(
    request: TrainClusterRequest,
    db: AsyncIOMotorDatabase = Depends(get_database)
):
    """
    Train or retrain the K-means clustering model with all users in the database
    
    This should be called:
    - When the system first starts
    - Periodically (e.g., daily) to update clusters as users join
    - After significant user base changes
    """
    global _model_trained
    
    try:
        # Fetch all users
        users = await fetch_all_users(db)
        
        if len(users) < request.n_clusters:
            raise HTTPException(
                status_code=400,
                detail=f"Not enough users ({len(users)}) to create {request.n_clusters} clusters. Need at least {request.n_clusters} users."
            )
        
        # Train the model
        cluster_labels = matching_engine.train_clusters(users, n_clusters=request.n_clusters)
        
        _model_trained = True
        
        return {
            "success": True,
            "message": f"Model trained successfully with {len(users)} users",
            "n_users": len(users),
            "n_clusters": request.n_clusters,
            "cluster_distribution": {
                f"cluster_{i}": int((cluster_labels == i).sum()) 
                for i in range(request.n_clusters)
            }
        }
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Training failed: {str(e)}")


@router.post("/find-matches", response_model=MatchResponse, summary="Find matches for a user")
async def find_matches(
    request: MatchRequest,
    db: AsyncIOMotorDatabase = Depends(get_database)
):
    """
    Find the best matches for a given user
    
    The matching algorithm considers:
    - Shared interests
    - Common languages (REQUIRED - at least 1)
    - Travel date overlap
    - Budget compatibility (close budgets acceptable)
    - Safety scores
    - Demographics (nationality, age, accessibility needs)
    - Women-to-women priority matching
    
    Rules:
    - Service providers CANNOT be matched TO travelers (only travelers can match with providers)
    - Travelers can match with other travelers
    - At least 1 common language is required
    """
    global _model_trained
    
    # Check if model is trained
    if not _model_trained:
        raise HTTPException(
            status_code=400,
            detail="Matching model not trained. Please call POST /api/matching/train first."
        )
    
    try:
        # Fetch target user
        target_user = await fetch_user_by_email(db, request.user_email)
        
        if not target_user:
            raise HTTPException(status_code=404, detail=f"User {request.user_email} not found")
        
        # Check if service provider is trying to match with travelers
        if target_user.get("account_type") == "service_provider":
            raise HTTPException(
                status_code=400,
                detail="Service providers cannot seek matches with travelers. Only travelers can match with service providers."
            )
        
        # Fetch all candidate users
        all_users = await fetch_all_users(db)
        
        # Filter candidates based on request
        candidates = []
        for user in all_users:
            if user["email"] == request.user_email:
                continue  # Skip self
            
            account_type = user.get("account_type")
            
            if account_type == "traveler" and not request.include_travelers:
                continue
            
            if account_type == "service_provider" and not request.include_providers:
                continue
            
            candidates.append(user)
        
        # Convert travel dates to the format expected by the engine
        travel_dates = None
        if request.travel_dates:
            travel_dates = [
                {
                    "start_date": td.start_date,
                    "end_date": td.end_date
                }
                for td in request.travel_dates
            ]
        
        # Find matches
        matches = matching_engine.find_matches(
            target_user=target_user,
            candidate_users=candidates,
            travel_dates=travel_dates,
            top_k=request.top_k
        )
        
        # Get statistics
        statistics = matching_engine.get_match_statistics(matches)
        
        # Convert to response format
        match_responses = []
        for match in matches:
            # Find the full user dict for this match
            user_dict = next(
                (u for u in all_users if u["email"] == match.matched_user_id),
                None
            )
            
            if user_dict:
                match_responses.append(match_result_to_response(match, user_dict))
        
        return MatchResponse(
            target_user=request.user_email,
            total_matches=len(match_responses),
            matches=match_responses,
            statistics=statistics
        )
    
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Matching failed: {str(e)}")


@router.get("/user-cluster/{email}", summary="Get cluster assignment for a user")
async def get_user_cluster(
    email: str,
    db: AsyncIOMotorDatabase = Depends(get_database)
):
    """
    Get the cluster assignment for a specific user
    """
    global _model_trained
    
    if not _model_trained:
        raise HTTPException(
            status_code=400,
            detail="Matching model not trained. Please call POST /api/matching/train first."
        )
    
    try:
        user = await fetch_user_by_email(db, email)
        
        if not user:
            raise HTTPException(status_code=404, detail=f"User {email} not found")
        
        cluster_id = matching_engine._get_cluster(user)
        
        return {
            "email": email,
            "full_name": user.get("full_name"),
            "account_type": user.get("account_type"),
            "cluster_id": int(cluster_id)
        }
    
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get cluster: {str(e)}")


@router.get("/model-status", summary="Get matching model status")
async def get_model_status():
    """
    Get the current status of the matching model
    """
    return {
        "trained": _model_trained,
        "n_clusters": matching_engine.n_clusters if _model_trained else None,
        "openai_available": matching_engine.openai_api_key is not None
    }


@router.get("/health", summary="Health check endpoint")
async def health_check():
    """
    Simple health check endpoint
    """
    return {
        "status": "healthy",
        "service": "Smart Matching API",
        "model_trained": _model_trained
    }


# ==================== Startup Function ====================

async def initialize_matching_system(db: AsyncIOMotorDatabase, n_clusters: int = 5):
    """
    Initialize the matching system on startup
    
    Call this from your main FastAPI app startup
    
    Example:
        @app.on_event("startup")
        async def startup_event():
            db = await get_database()
            await initialize_matching_system(db)
    """
    global _model_trained
    
    try:
        users = await fetch_all_users(db)
        
        if len(users) >= n_clusters:
            matching_engine.train_clusters(users, n_clusters=n_clusters)
            _model_trained = True
            print(f"✅ Matching system initialized with {len(users)} users and {n_clusters} clusters")
        else:
            print(f"⚠️  Not enough users ({len(users)}) to train matching model. Need at least {n_clusters}.")
            print("   The matching system will be available after calling POST /api/matching/train")
    
    except Exception as e:
        print(f"❌ Failed to initialize matching system: {e}")
        print("   The matching system will be available after calling POST /api/matching/train")