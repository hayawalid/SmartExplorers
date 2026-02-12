"""app/api/matching.py

Smart Matching API (MongoDB-integrated).

Aligned with the rest of the SmartExplorers backend:
- Uses the shared MongoDB connection from app/mongodb.py (NO new AsyncIOMotorClient here)
- Uses mongodb collection constants (mongodb.USERS, mongodb.TRAVELER_PROFILES, etc.)
- Endpoints access DB the same way as other routers (db = get_database())
"""

from __future__ import annotations

import os
from datetime import datetime
from typing import Any, Dict, List, Optional

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field

from app.mongodb import get_database, mongodb
from app.services.smart_matching_engine import MatchResult, SmartMatchingEngine


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


# ==================== Matching Engine Instance ====================


matching_engine = SmartMatchingEngine(openai_api_key=os.getenv("OPENAI_API_KEY"))

# Flag to track if model is trained
_model_trained = False


# ==================== Helper Functions ====================


async def fetch_all_users(db) -> List[Dict[str, Any]]:
    """Fetch all active, non-banned users with their profiles embedded."""
    users: List[Dict[str, Any]] = []

    cursor = db[mongodb.USERS].find({"is_active": True, "is_banned": False})

    async for user in cursor:
        user_id = str(user["_id"])
        account_type = user.get("account_type")

        user_dict: Dict[str, Any] = {
            "_id": user_id,
            "email": user.get("email"),
            "username": user.get("username"),
            "full_name": user.get("full_name"),
            "account_type": account_type,
            "verified_flag": user.get("verified_flag", False),
            "profile_picture_url": user.get("profile_picture_url"),
            "bio": user.get("bio"),
            "travel_dates": [],  # not implemented in schema yet
        }

        if account_type == "traveler":
            profile = await db[mongodb.TRAVELER_PROFILES].find_one({"user_id": user_id})
            if profile:
                profile_dict = dict(profile)
                profile_dict.pop("_id", None)
                profile_dict.pop("user_id", None)
                user_dict["profile"] = profile_dict
        else:
            profile = await db[mongodb.SERVICE_PROVIDER_PROFILES].find_one({"user_id": user_id})
            if profile:
                profile_dict = dict(profile)
                profile_dict.pop("_id", None)
                profile_dict.pop("user_id", None)
                user_dict["provider_profile"] = profile_dict

        users.append(user_dict)

    return users


async def fetch_user_by_email(db, email: str) -> Optional[Dict[str, Any]]:
    """Fetch a single active user (by email) with embedded profile."""
    user = await db[mongodb.USERS].find_one({"email": email, "is_active": True})
    if not user:
        return None

    user_id = str(user["_id"])
    account_type = user.get("account_type")

    user_dict: Dict[str, Any] = {
        "_id": user_id,
        "email": user.get("email"),
        "username": user.get("username"),
        "full_name": user.get("full_name"),
        "account_type": account_type,
        "verified_flag": user.get("verified_flag", False),
        "profile_picture_url": user.get("profile_picture_url"),
        "bio": user.get("bio"),
        "travel_dates": [],
    }

    if account_type == "traveler":
        profile = await db[mongodb.TRAVELER_PROFILES].find_one({"user_id": user_id})
        if profile:
            profile_dict = dict(profile)
            profile_dict.pop("_id", None)
            profile_dict.pop("user_id", None)
            user_dict["profile"] = profile_dict
    else:
        profile = await db[mongodb.SERVICE_PROVIDER_PROFILES].find_one({"user_id": user_id})
        if profile:
            profile_dict = dict(profile)
            profile_dict.pop("_id", None)
            profile_dict.pop("user_id", None)
            user_dict["provider_profile"] = profile_dict

    return user_dict


def match_result_to_response(match: MatchResult, user_dict: Dict[str, Any]) -> MatchResponseItem:
    """Convert internal MatchResult + user dict to the API response model."""
    return MatchResponseItem(
        user_id=user_dict.get("_id", ""),
        email=match.matched_user_id,  # engine stores matched user's email here
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
        cluster_id=int(match.cluster_id),
        profile_picture_url=user_dict.get("profile_picture_url"),
        bio=user_dict.get("bio"),
    )


# ==================== API Endpoints ====================


@router.post("/train", summary="Train or retrain the clustering model")
async def train_matching_model(request: TrainClusterRequest):
    """Train or retrain K-means clustering model using current users in MongoDB."""
    global _model_trained
    db = get_database()

    try:
        users = await fetch_all_users(db)

        if len(users) < request.n_clusters:
            raise HTTPException(
                status_code=400,
                detail=(
                    f"Not enough users ({len(users)}) to create {request.n_clusters} clusters. "
                    f"Need at least {request.n_clusters} users."
                ),
            )

        cluster_labels = matching_engine.train_clusters(users, n_clusters=request.n_clusters)
        _model_trained = True

        return {
            "success": True,
            "message": f"Model trained successfully with {len(users)} users",
            "n_users": len(users),
            "n_clusters": request.n_clusters,
            "cluster_distribution": {
                f"cluster_{i}": int((cluster_labels == i).sum()) for i in range(request.n_clusters)
            },
        }

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Training failed: {str(e)}")


@router.post("/find-matches", response_model=MatchResponse, summary="Find matches for a user")
async def find_matches(request: MatchRequest):
    """Find best matches for a given user."""
    global _model_trained
    db = get_database()

    if not _model_trained:
        raise HTTPException(
            status_code=400,
            detail="Matching model not trained. Please call POST /api/matching/train first.",
        )

    try:
        target_user = await fetch_user_by_email(db, request.user_email)
        if not target_user:
            raise HTTPException(status_code=404, detail=f"User {request.user_email} not found")

        # Rule: providers cannot request matching
        if target_user.get("account_type") == "service_provider":
            raise HTTPException(
                status_code=400,
                detail=(
                    "Service providers cannot seek matches with travelers. "
                    "Only travelers can match with service providers."
                ),
            )

        all_users = await fetch_all_users(db)

        candidates: List[Dict[str, Any]] = []
        for user in all_users:
            if user.get("email") == request.user_email:
                continue

            account_type = user.get("account_type")
            if account_type == "traveler" and not request.include_travelers:
                continue
            if account_type == "service_provider" and not request.include_providers:
                continue

            candidates.append(user)

        travel_dates = None
        if request.travel_dates:
            travel_dates = [
                {"start_date": td.start_date, "end_date": td.end_date} for td in request.travel_dates
            ]

        matches = matching_engine.find_matches(
            target_user=target_user,
            candidate_users=candidates,
            travel_dates=travel_dates,
            top_k=request.top_k,
        )

        statistics = matching_engine.get_match_statistics(matches)

        match_responses: List[MatchResponseItem] = []
        for match in matches:
            user_dict = next((u for u in all_users if u.get("email") == match.matched_user_id), None)
            if user_dict:
                match_responses.append(match_result_to_response(match, user_dict))

        return MatchResponse(
            target_user=request.user_email,
            total_matches=len(match_responses),
            matches=match_responses,
            statistics=statistics,
        )

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Matching failed: {str(e)}")


@router.get("/user-cluster/{email}", summary="Get cluster assignment for a user")
async def get_user_cluster(email: str):
    """Get the cluster assignment for a specific user."""
    global _model_trained
    db = get_database()

    if not _model_trained:
        raise HTTPException(
            status_code=400,
            detail="Matching model not trained. Please call POST /api/matching/train first.",
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
            "cluster_id": int(cluster_id),
        }

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get cluster: {str(e)}")


@router.get("/model-status", summary="Get matching model status")
async def get_model_status():
    """Get the current status of the matching model."""
    return {
        "trained": _model_trained,
        "n_clusters": matching_engine.n_clusters if _model_trained else None,
        "openai_available": matching_engine.openai_api_key is not None,
    }


@router.get("/health", summary="Health check endpoint")
async def health_check():
    """Simple health check endpoint."""
    return {"status": "healthy", "service": "Smart Matching API", "model_trained": _model_trained}


# ==================== Startup Function ====================


async def initialize_matching_system(db, n_clusters: int = 5):
    """Initialize the matching system on startup.

    Your main.py already does:
        db = mongodb.db
        await initialize_matching_system(db, n_clusters=5)
    """
    global _model_trained

    try:
        users = await fetch_all_users(db)

        if len(users) >= n_clusters:
            matching_engine.train_clusters(users, n_clusters=n_clusters)
            _model_trained = True
            print(f"✅ Matching system initialized with {len(users)} users and {n_clusters} clusters")
        else:
            print(
                f"⚠️  Not enough users ({len(users)}) to train matching model. Need at least {n_clusters}."
            )
            print("   The matching system will be available after calling POST /api/matching/train")

    except Exception as e:
        print(f"❌ Failed to initialize matching system: {e}")
        print("   The matching system will be available after calling POST /api/matching/train")