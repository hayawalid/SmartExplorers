"""
Recommendations API - Returns service providers sorted by verification score
Higher verification score = higher recommendation
"""
from fastapi import APIRouter, Depends, HTTPException, Query
from typing import List, Dict, Any, Optional
from datetime import datetime

from app.services.provider_verification_service import provider_verification_service
from app.mongodb import get_database, mongodb

router = APIRouter(prefix="/api/v1/recommendations", tags=["recommendations"])


# Mock auth - replace with your real authentication
async def get_current_user():
    """Mock user authentication - replace with your actual auth"""
    return {"id": "test_user_id", "email": "test@example.com"}


@router.get("/providers")
async def get_recommended_providers(
    limit: int = Query(20, ge=1, le=100, description="Maximum number of recommendations"),
    min_score: float = Query(0, ge=0, le=100, description="Minimum verification score"),
    service_type: Optional[str] = Query(None, description="Filter by service type"),
    current_user: dict = Depends(get_current_user)
):
    """
    Get recommended service providers sorted by verification score.
    
    Higher verification score = more trusted = higher recommendation.
    
    Verification scoring (max 100 points):
    - Location verification: 15 points
    - Business existence: 10 points
    - Social media presence: 10 points
    - Review analysis: 15 points
    - Duplicate check: 10 points
    - Phone location match: 5 points
    - Business hours: 5 points
    - License validity: 10 points
    """
    
    # Get providers sorted by verification score
    providers = await provider_verification_service.get_recommended_providers(
        limit=limit,
        service_type=service_type,
        min_score=min_score
    )
    
    return {
        "status": "success",
        "total": len(providers),
        "providers": providers,
        "timestamp": datetime.utcnow().isoformat()
    }


@router.get("/providers/{provider_id}/verification")
async def get_provider_verification(
    provider_id: str
):
    """
    Get detailed verification report for a specific provider.
    Shows which verification sources are passed and the score.
    """
    
    # Check if we have stored verification
    verification = await provider_verification_service.get_provider_verification(provider_id)
    
    if not verification:
        # Run verification on-demand
        verification = await provider_verification_service.verify_provider_complete(
            provider_id=provider_id
        )
    
    if verification.get("error"):
        raise HTTPException(status_code=404, detail=verification["error"])
    
    return {
        "status": "success",
        "verification": verification
    }


@router.post("/providers/{provider_id}/verify")
async def verify_provider_now(
    provider_id: str,
    current_user: dict = Depends(get_current_user)
):
    """
    Manually trigger verification for a provider.
    Runs all 8 verification sources and updates their score.
    """
    
    verification = await provider_verification_service.verify_provider_complete(
        provider_id=provider_id
    )
    
    if verification.get("error"):
        raise HTTPException(status_code=404, detail=verification["error"])
    
    return {
        "status": "success",
        "message": f"Verification complete for {verification.get('provider_name')}",
        "verification_score": verification.get("overall_score"),
        "verification_level": verification.get("verification_level"),
        "details": verification
    }


@router.get("/stats")
async def get_verification_stats():
    """Get statistics about provider verification scores"""
    
    db = await provider_verification_service._get_db()
    
    # Get all providers with verification scores
    cursor = db[mongodb.SERVICE_PROVIDER_PROFILES].find({
        "verification_score": {"$exists": True}
    })
    
    scores = []
    async for profile in cursor:
        score = profile.get("verification_score", 0)
        if score > 0:
            scores.append(score)
    
    if not scores:
        return {
            "status": "success",
            "total_verified": 0,
            "average_score": 0,
            "highest_score": 0,
            "score_distribution": {
                "trusted_80_100": 0,
                "verified_60_79": 0,
                "standard_40_59": 0,
                "basic_20_39": 0,
                "unverified_0_19": 0
            }
        }
    
    distribution = {
        "trusted_80_100": len([s for s in scores if s >= 80]),
        "verified_60_79": len([s for s in scores if 60 <= s < 80]),
        "standard_40_59": len([s for s in scores if 40 <= s < 60]),
        "basic_20_39": len([s for s in scores if 20 <= s < 40]),
        "unverified_0_19": len([s for s in scores if s < 20])
    }
    
    return {
        "status": "success",
        "total_verified": len(scores),
        "average_score": round(sum(scores) / len(scores), 1),
        "highest_score": max(scores),
        "score_distribution": distribution
    }