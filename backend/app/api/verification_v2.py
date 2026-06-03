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
# PROVIDER VERIFICATION ENDPOINTS (for Flutter app)
# ============================================================================

@router.get("/providers/{provider_id}")
async def get_provider_verification(
    provider_id: str,
    db=Depends(get_database)
):
    """
    Get provider verification data (simplified for Flutter app).
    Returns overall_score, verification_level, source_scores, etc.
    """
    from app.services.provider_verification_service import provider_verification_service
    
    try:
        # Check if provider exists
        provider = await db.service_provider_profiles.find_one({"user_id": provider_id})
        
        if not provider:
            raise HTTPException(status_code=404, detail="Provider not found")
        
        # Get existing verification data from provider profile
        verification_data = provider.get("verification", {})
        
        # Also get cross-validation service data if available
        source_scores = {}
        warnings = []
        recommendations = []
        
        # Try to get fresh cross-validation data
        try:
            from app.services.cross_validation_service import cross_validation_service
            cross_result = await cross_validation_service.verify_service_provider(
                provider_data=provider,
                db=db
            )
            if cross_result:
                overall_score = cross_result.get("overall_score", 0.0)
                verification_level = cross_result.get("verification_level", "basic")
                source_scores = cross_result.get("detailed_results", {})
                warnings = cross_result.get("warnings", [])
                recommendations = cross_result.get("recommendations", [])
            else:
                overall_score = verification_data.get("overall_score", 0.0)
                verification_level = verification_data.get("tier", "basic")
        except Exception as e:
            # Fallback to stored data
            overall_score = verification_data.get("overall_score", 0.0)
            verification_level = verification_data.get("tier", "basic")
        
        return {
            "provider_id": provider_id,
            "overall_score": overall_score,
            "verification_level": verification_level,
            "source_scores": source_scores,
            "warnings": warnings,
            "recommendations": recommendations,
            "provider_profile": {
                "business_name": provider.get("business_name"),
                "address": provider.get("address"),
                "city": provider.get("city"),
                "latitude": provider.get("latitude"),
                "longitude": provider.get("longitude"),
                "phone_number": provider.get("phone_number"),
                "facebook_url": provider.get("facebook_url"),
                "instagram_username": provider.get("instagram_username"),
                "business_license_number": provider.get("business_license_number"),
                "verification_status": provider.get("verification_status", "pending"),
                "id_name_match": provider.get("id_name_match", False),
                "face_verified": provider.get("face_verified", False),
            }
        }
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/providers/{provider_id}/verify")
async def trigger_provider_verification(
    provider_id: str,
    db=Depends(get_database)
):
    """
    Trigger fresh verification for a provider.
    Re-runs all 8 verification checks and returns updated scores.
    """
    from app.services.provider_verification_service import provider_verification_service
    
    try:
        # Check if provider exists
        provider = await db.service_provider_profiles.find_one({"user_id": provider_id})
        
        if not provider:
            raise HTTPException(status_code=404, detail="Provider not found")
        
        # Run verification
        report = await provider_verification_service.verify_provider_complete(
            provider_id=provider_id
        )
        
        if report.get("error"):
            raise HTTPException(status_code=404, detail=report["error"])
        
        return {
            "provider_id": provider_id,
            "overall_score": report.get("overall_score", 0),
            "verification_level": report.get("verification_level", "basic"),
            "source_scores": report.get("source_scores", {}),
            "warnings": report.get("warnings", []),
            "recommendations": report.get("recommendations", []),
            "provider_profile": {
                "business_name": provider.get("business_name"),
                "address": provider.get("address"),
                "city": provider.get("city"),
                "latitude": provider.get("latitude"),
                "longitude": provider.get("longitude"),
                "phone_number": provider.get("phone_number"),
                "facebook_url": provider.get("facebook_url"),
                "instagram_username": provider.get("instagram_username"),
                "business_license_number": provider.get("business_license_number"),
                "verification_status": report.get("verification_status", "pending"),
            }
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


# ============================================================================
# FACE VERIFICATION (Flutter app endpoint)
# ============================================================================

# ============================================================================
# PROVIDER BUSINESS INFO SUBMISSION (8-step scoring trigger)
# ============================================================================

class ProviderBusinessInfoRequest(BaseModel):
    """Provider fills in their business details to improve verification score."""
    business_name: Optional[str] = None
    address: Optional[str] = None
    city: Optional[str] = None
    latitude: Optional[float] = Field(None, ge=-90, le=90)
    longitude: Optional[float] = Field(None, ge=-180, le=180)
    phone: Optional[str] = None
    facebook_url: Optional[str] = None
    instagram_username: Optional[str] = None
    business_license: Optional[str] = None
    business_hours: Optional[dict] = None


@router.post("/providers/{provider_id}/submit-info")
async def submit_provider_business_info(
    provider_id: str,
    payload: ProviderBusinessInfoRequest,
    db=Depends(get_database),
):
    """
    Provider submits / updates their business information.
    Saves fields to their profile then triggers the 8-source re-verification
    so the score is recalculated immediately.
    """
    from app.mongodb import mongodb
    from app.services.provider_verification_service import provider_verification_service

    update_fields: dict = {}
    if payload.business_name is not None:
        update_fields["business_name"] = payload.business_name
    if payload.address is not None:
        update_fields["address"] = payload.address
    if payload.city is not None:
        update_fields["city"] = payload.city
    if payload.latitude is not None:
        update_fields["latitude"] = payload.latitude
    if payload.longitude is not None:
        update_fields["longitude"] = payload.longitude
    if payload.phone is not None:
        update_fields["phone_number"] = payload.phone
    if payload.facebook_url is not None:
        update_fields["facebook_url"] = payload.facebook_url
    if payload.instagram_username is not None:
        update_fields["instagram_username"] = payload.instagram_username
    if payload.business_license is not None:
        update_fields["business_license_number"] = payload.business_license
    if payload.business_hours is not None:
        update_fields["business_hours"] = payload.business_hours

    if update_fields:
        update_fields["updated_at"] = datetime.utcnow()
        await db[mongodb.SERVICE_PROVIDER_PROFILES].update_one(
            {"user_id": provider_id},
            {"$set": update_fields},
            upsert=True,
        )

    # Re-run the 8-source verification with the new data
    report = await provider_verification_service.verify_provider_complete(
        provider_id=provider_id
    )

    if report.get("error"):
        raise HTTPException(status_code=404, detail=report["error"])

    return {
        "success": True,
        "message": "Business info saved and verification score updated.",
        "overall_score": report.get("overall_score", 0),
        "verification_level": report.get("verification_level", "basic"),
        "source_scores": report.get("source_scores", {}),
    }


@router.post("/verify-faces")
async def verify_faces_endpoint(
    id_image: UploadFile = File(...),
    selfie_image: UploadFile = File(...),
):
    """
    Simple face verification endpoint called by the Flutter app.
    Accepts id_image and selfie_image, returns match result.
    """
    from app.services.face_verification import face_verification_service
    try:
        id_image_bytes = await id_image.read()
        selfie_image_bytes = await selfie_image.read()

        doc_validation = face_verification_service.validate_image_quality(id_image_bytes)
        if not doc_validation["valid"]:
            raise HTTPException(status_code=400, detail=f"ID image invalid: {doc_validation['reason']}")

        selfie_validation = face_verification_service.validate_image_quality(selfie_image_bytes)
        if not selfie_validation["valid"]:
            raise HTTPException(status_code=400, detail=f"Selfie invalid: {selfie_validation['reason']}")

        result = face_verification_service.verify_faces(id_image_bytes, selfie_image_bytes)

        return {
            "verified": result.get("verified", False),
            "confidence": result.get("confidence", 0.0),
            "passes_threshold": result.get("passes_threshold", False),
            "message": "Faces match" if result.get("passes_threshold") else "Faces do not match",
            "mock_mode": result.get("mock_mode", False),
        }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Verification failed: {str(e)}")

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Verification failed: {str(e)}")

@router.post("/verify-faces-with-name")
async def verify_faces_with_name_endpoint(
    id_image: UploadFile = File(...),
    selfie_image: UploadFile = File(...),
    provider_id: Optional[str] = Form(None),
    expected_name: Optional[str] = Form(None),
):
    """
    Face verification + OCR name matching.
    Compares the name on the ID document against the expected name
    (from onboarding). Saves id_name_match to the provider profile.
    """
    from app.services.face_verification import face_verification_service
    from app.services.ocr import ocr_service
    from app.mongodb import mongodb, get_database

    try:
        id_image_bytes = await id_image.read()
        selfie_image_bytes = await selfie_image.read()

        # Validate images
        doc_validation = face_verification_service.validate_image_quality(id_image_bytes)
        if not doc_validation["valid"]:
            raise HTTPException(status_code=400, detail=f"ID image invalid: {doc_validation['reason']}")

        selfie_validation = face_verification_service.validate_image_quality(selfie_image_bytes)
        if not selfie_validation["valid"]:
            raise HTTPException(status_code=400, detail=f"Selfie invalid: {selfie_validation['reason']}")

        # Face verification
        face_result = face_verification_service.verify_faces(id_image_bytes, selfie_image_bytes)

        # OCR name extraction
        ocr_data = ocr_service.extract_id_data(id_image_bytes, "national_id")
        ocr_name = ocr_data.get("full_name") or ""

        # Name match — simple normalised comparison
        name_matched = False
        if expected_name and ocr_name:
            def _norm(s: str) -> str:
                import re
                return re.sub(r"\s+", " ", s.strip().lower())
            name_matched = _norm(ocr_name) == _norm(expected_name)

        # Persist result to provider profile
        if provider_id:
            db = get_database()
            await db[mongodb.SERVICE_PROVIDER_PROFILES].update_one(
                {"user_id": provider_id},
                {
                    "$set": {
                        "verification_status": "verified" if face_result.get("passes_threshold") else "pending",
                        "face_verified": face_result.get("passes_threshold", False),
                        "id_name_match": name_matched,
                        "ocr_name": ocr_name,
                    }
                },
                upsert=True,
            )

        return {
            "verified": face_result.get("verified", False),
            "confidence": face_result.get("confidence", 0.0),
            "passes_threshold": face_result.get("passes_threshold", False),
            "message": "Faces match" if face_result.get("passes_threshold") else "Faces do not match",
            "mock_mode": face_result.get("mock_mode", False),
            "ocr_name": ocr_name,
            "expected_name": expected_name,
            "name_matched": name_matched,
        }

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Verification failed: {str(e)}")


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
