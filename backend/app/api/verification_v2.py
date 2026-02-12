"""
Verification API Endpoints (MongoDB-based)
Complete verification workflow for providers and places
"""
from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Form
from typing import Optional, List
from pydantic import BaseModel, Field
from datetime import datetime

from app.mongodb import get_database
from app.services.verification_orchestrator import (
    verification_orchestrator,
    VerificationTier
)
from app.services.cross_validation_service import cross_validation_service


router = APIRouter(prefix="/api/v1/verification", tags=["Verification"])


# ============================================================================
# REQUEST/RESPONSE MODELS
# ============================================================================

class ProviderVerificationRequest(BaseModel):
    """Service provider verification request"""
    business_name: str
    business_license: Optional[str] = None
    address: str
    city: str
    latitude: float = Field(..., ge=-90, le=90)
    longitude: float = Field(..., ge=-180, le=180)
    phone: str
    email: str
    phone_verified: bool = False
    email_verified: bool = False
    
    # Social media (optional)
    facebook_url: Optional[str] = None
    instagram_username: Optional[str] = None
    
    # Business hours (optional)
    business_hours: Optional[dict] = None
    
    # National ID (for duplicate check)
    national_id: Optional[str] = None


class PlaceVerificationRequest(BaseModel):
    """Place verification request"""
    name: str
    address: Optional[str] = None
    latitude: Optional[float] = Field(None, ge=-90, le=90)
    longitude: Optional[float] = Field(None, ge=-180, le=180)
    category: Optional[str] = None


class VerificationResponse(BaseModel):
    """Verification response"""
    success: bool
    message: str
    verification_report: dict
    timestamp: datetime = Field(default_factory=datetime.utcnow)


class CrossValidationResponse(BaseModel):
    """Cross-validation detailed response"""
    overall_score: float
    verification_level: str
    checks_passed: List[str]
    checks_failed: List[str]
    warnings: List[str]
    recommendations: List[str]
    detailed_results: dict


# ============================================================================
# SERVICE PROVIDER VERIFICATION
# ============================================================================

@router.post("/provider/complete", response_model=VerificationResponse)
async def verify_provider_complete(
    # Provider data
    provider_data: str = Form(..., description="JSON string of provider data"),
    
    # Identity verification images
    id_document: Optional[UploadFile] = File(None, description="ID document photo"),
    selfie: Optional[UploadFile] = File(None, description="Live selfie"),
    
    # Database
    db=Depends(get_database)
):
    """
    Complete service provider verification
    
    Workflow:
    1. Basic verification (phone + email)
    2. Identity verification (ID + selfie)
    3. Cross-validation (location, business, social, reviews)
    4. Fraud detection
    
    Returns verification tier and badges
    """
    
    try:
        import json
        provider_dict = json.loads(provider_data)
        
        # Read images if provided
        id_image_bytes = None
        selfie_image_bytes = None
        
        if id_document:
            id_image_bytes = await id_document.read()
        
        if selfie:
            selfie_image_bytes = await selfie.read()
        
        # Run complete verification
        verification_report = await verification_orchestrator.verify_service_provider_complete(
            provider_data=provider_dict,
            id_document_image=id_image_bytes,
            selfie_image=selfie_image_bytes,
            db=db
        )
        
        return VerificationResponse(
            success=True,
            message=f"Verification complete - Tier: {verification_report['tier'].value}",
            verification_report=verification_report
        )
        
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.post("/provider/cross-validate", response_model=CrossValidationResponse)
async def cross_validate_provider(
    provider_data: ProviderVerificationRequest,
    db=Depends(get_database)
):
    """
    Cross-validate service provider across multiple sources
    
    Sources:
    - Google Maps (location, business)
    - Facebook/Instagram (social media)
    - Reviews (Google, TripAdvisor)
    - Database (duplicates)
    - Phone area code validation
    - Business hours validation
    - License validation
    """
    
    try:
        provider_dict = provider_data.model_dump()
        
        result = await cross_validation_service.verify_service_provider(
            provider_data=provider_dict,
            db=db
        )
        
        return CrossValidationResponse(**result)
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/provider/{provider_id}/status")
async def get_provider_verification_status(
    provider_id: str,
    db=Depends(get_database)
):
    """Get current verification status for a provider"""
    
    try:
        provider = await db.service_provider_profiles.find_one({"_id": provider_id})
        
        if not provider:
            raise HTTPException(status_code=404, detail="Provider not found")
        
        verification_data = provider.get("verification", {})
        
        return {
            "provider_id": provider_id,
            "tier": verification_data.get("tier", "basic"),
            "overall_score": verification_data.get("overall_score", 0.0),
            "badges": verification_data.get("badges", []),
            "last_verified": verification_data.get("timestamp"),
            "warnings": verification_data.get("warnings", [])
        }
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# ============================================================================
# PLACE VERIFICATION
# ============================================================================

@router.post("/place/verify")
async def verify_place(
    place_data: PlaceVerificationRequest
):
    """
    Verify a place/location
    
    Sources:
    - Google Maps existence & details
    - TripAdvisor cross-reference (optional)
    - AI Safety risk assessment
    - Accessibility feature detection
    """
    
    try:
        place_dict = place_data.model_dump()
        result = await verification_orchestrator.verify_place_complete(place_dict)
        return result
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/place/batch-verify")
async def batch_verify_places(
    places: List[PlaceVerificationRequest]
):
    """Verify multiple places at once"""
    
    try:
        results = []
        
        for place_data in places:
            place_dict = place_data.model_dump()
            result = await verification_orchestrator.verify_place_complete(place_dict)
            results.append(result)
        
        return {
            "total": len(places),
            "verified": sum(1 for r in results if r.get("verified")),
            "results": results
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# ============================================================================
# VERIFICATION TOOLS (Individual Checks)
# ============================================================================

@router.post("/tools/verify-location")
async def verify_location(
    business_name: str,
    address: str,
    latitude: Optional[float] = None,
    longitude: Optional[float] = None
):
    """
    Verify business location exists using Google Maps Geocoding and Places API
    """
    
    try:
        provider_data = {
            "business_name": business_name,
            "address": address,
            "latitude": latitude,
            "longitude": longitude
        }
        
        result = await cross_validation_service._verify_location(provider_data)
        return result
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/tools/verify-social-media")
async def verify_social_media(
    facebook_url: Optional[str] = None,
    instagram_username: Optional[str] = None
):
    """Verify social media accounts exist and are active"""
    
    try:
        provider_data = {
            "facebook_url": facebook_url,
            "instagram_username": instagram_username
        }
        
        result = await cross_validation_service._verify_social_media(provider_data)
        return result
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/tools/analyze-reviews")
async def analyze_reviews(
    business_name: str,
    latitude: float,
    longitude: float
):
    """
    Analyze reviews from Google and other sources.
    Uses AI to detect sentiment, authenticity, red flags, and common themes.
    """
    
    try:
        provider_data = {
            "business_name": business_name,
            "latitude": latitude,
            "longitude": longitude
        }
        
        result = await cross_validation_service._analyze_reviews(provider_data)
        return result
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/tools/check-duplicates")
async def check_duplicates(
    phone: Optional[str] = None,
    email: Optional[str] = None,
    license_number: Optional[str] = None,
    national_id: Optional[str] = None,
    db=Depends(get_database)
):
    """Check for duplicate provider accounts"""
    
    try:
        provider_data = {
            "phone": phone,
            "email": email,
            "business_license": license_number,
            "national_id": national_id
        }
        
        result = await cross_validation_service._check_duplicates(provider_data, db)
        return result
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# ============================================================================
# VERIFICATION BADGES
# ============================================================================

@router.get("/badges/{tier}")
def get_verification_badge(tier: str):
    """Get HTML badge for verification tier"""
    
    try:
        tier_enum = VerificationTier(tier)
        badge_html = verification_orchestrator.get_verification_badge_html(
            tier=tier_enum,
            badges=[]
        )
        
        return {
            "tier": tier,
            "badge_html": badge_html
        }
        
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid verification tier")


# ============================================================================
# ADMIN ENDPOINTS
# ============================================================================

@router.get("/admin/stats")
async def get_verification_stats(
    db=Depends(get_database)
):
    """Get verification statistics (admin only)"""
    
    # TODO: Add admin auth
    
    try:
        pipeline = [
            {
                "$group": {
                    "_id": "$verification.tier",
                    "count": {"$sum": 1}
                }
            }
        ]
        
        tier_counts = await db.service_provider_profiles.aggregate(pipeline).to_list(length=10)
        total = await db.service_provider_profiles.count_documents({})
        verified = await db.service_provider_profiles.count_documents({
            "verification.tier": {"$in": ["verified", "trusted"]}
        })
        
        return {
            "total_providers": total,
            "verified_providers": verified,
            "verification_rate": (verified / total * 100) if total > 0 else 0.0,
            "tier_breakdown": tier_counts
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/admin/re-verify/{provider_id}")
async def re_verify_provider(
    provider_id: str,
    db=Depends(get_database)
):
    """Re-run verification for a provider (admin only)"""
    
    # TODO: Add admin auth
    
    try:
        provider = await db.service_provider_profiles.find_one({"_id": provider_id})
        
        if not provider:
            raise HTTPException(status_code=404, detail="Provider not found")
        
        result = await cross_validation_service.verify_service_provider(
            provider_data=provider,
            db=db
        )
        
        await db.service_provider_profiles.update_one(
            {"_id": provider_id},
            {
                "$set": {
                    "verification": result,
                    "verification_last_updated": datetime.utcnow()
                }
            }
        )
        
        return {
            "success": True,
            "message": "Re-verification complete",
            "result": result
        }
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
