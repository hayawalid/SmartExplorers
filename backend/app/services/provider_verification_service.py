"""
Provider Verification Service - Manages 8-source verification scoring
Tracks verification status for each provider and calculates total score
Used for ranking recommendations
"""
from typing import Dict, Any, Optional, List
from datetime import datetime
from bson import ObjectId

from app.services.cross_validation_service import cross_validation_service
from app.mongodb import mongodb


class ProviderVerificationService:
    """
    Manages the 8 verification sources for service providers:
    1. Location verification (15 points max)
    2. Business existence (10 points max)
    3. Social media presence (10 points max)
    4. Review analysis (15 points max)
    5. Duplicate check (10 points max)
    6. Phone location match (5 points max)
    7. Business hours (5 points max)
    8. License validity (10 points max)
    
    Total possible: 80 points → normalized to 0-100 score
    """
    
    # Maximum points per verification source
    MAX_POINTS = {
        "location_verification": 15,
        "business_existence": 10,
        "social_media": 10,
        "review_analysis": 15,
        "duplicate_check": 10,
        "phone_location": 5,
        "business_hours": 5,
        "license_validity": 10
    }
    
    def __init__(self):
        """Initialize - uses global mongodb connection"""
        self.db = None
    
    async def _get_db(self):
        """Get MongoDB database instance"""
        if self.db is None:
            self.db = mongodb.db
        if self.db is None:
            raise RuntimeError("MongoDB not connected — call connect_to_mongo() before verifying")
        return self.db
    
    async def verify_provider_complete(
        self,
        provider_id: str,
        provider_data: Optional[Dict] = None
    ) -> Dict[str, Any]:
        """
        Run complete 8-source verification for a provider
        Stores results and calculates total score
        
        Args:
            provider_id: The provider's user ID (string)
            provider_data: Optional pre-fetched provider data
            
        Returns:
            Verification report with total score and source-specific results
        """
        db = await self._get_db()
        
        # Fetch provider if not provided
        if provider_data is None:
            provider_data = await self._get_provider_by_id(provider_id, db)
        
        if not provider_data:
            return {"error": f"Provider {provider_id} not found"}
        
        # Run cross-validation (already has all 8 checks)
        validation_result = await cross_validation_service.verify_service_provider(
            provider_data=provider_data,
            db=db
        )
        
        # Calculate scores for each source
        source_scores = {}
        total_earned = 0
        total_max = 0
        
        detailed_results = validation_result.get("detailed_results", {})
        
        # Source 1: Location Verification (15 max)
        loc_result = detailed_results.get("location_verification", {})
        loc_score = loc_result.get("score", 0)
        source_scores["location_verification"] = {
            "earned": loc_score,
            "max": self.MAX_POINTS["location_verification"],
            "passed": loc_result.get("passed", False),
            "details": {
                "distance_meters": loc_result.get("distance_meters"),
                "coordinate_match": loc_result.get("coordinate_match", False),
                "business_found_nearby": loc_result.get("business_found_nearby", False),
                "confidence": loc_result.get("confidence", "unknown")
            }
        }
        total_earned += loc_score
        total_max += self.MAX_POINTS["location_verification"]
        
        # Source 2: Business Existence (10 max)
        bus_result = detailed_results.get("business_existence", {})
        bus_score = bus_result.get("score", 0)
        source_scores["business_existence"] = {
            "earned": bus_score,
            "max": self.MAX_POINTS["business_existence"],
            "passed": bus_result.get("passed", False),
            "details": {
                "osm_id": bus_result.get("osm_id"),
                "has_phone": bus_result.get("has_phone", False),
                "has_website": bus_result.get("has_website", False),
                "has_hours": bus_result.get("has_hours", False),
                "osm_url": bus_result.get("osm_url")
            }
        }
        total_earned += bus_score
        total_max += self.MAX_POINTS["business_existence"]
        
        # Source 3: Social Media (10 max)
        soc_result = detailed_results.get("social_media", {})
        soc_score = soc_result.get("score", 0)
        source_scores["social_media"] = {
            "earned": soc_score,
            "max": self.MAX_POINTS["social_media"],
            "passed": soc_result.get("passed", False),
            "details": soc_result.get("platforms", {})
        }
        total_earned += soc_score
        total_max += self.MAX_POINTS["social_media"]
        
        # Source 4: Review Analysis (15 max)
        rev_result = detailed_results.get("review_analysis", {})
        rev_score = rev_result.get("score", 0)
        source_scores["review_analysis"] = {
            "earned": rev_score,
            "max": self.MAX_POINTS["review_analysis"],
            "passed": rev_result.get("passed", False),
            "details": {
                "review_count": rev_result.get("review_count", 0),
                "average_rating": rev_result.get("average_rating", 0),
                "sentiment": rev_result.get("sentiment", "unknown"),
                "authenticity_score": rev_result.get("authenticity_score", 0),
                "red_flags": rev_result.get("red_flags", []),
                "verification_penalties": rev_result.get("verification_penalties", []),
            }
        }
        total_earned += rev_score
        total_max += self.MAX_POINTS["review_analysis"]
        
        # Source 5: Duplicate Check (10 max)
        dup_result = detailed_results.get("duplicate_check", {})
        dup_score = dup_result.get("score", 0)
        source_scores["duplicate_check"] = {
            "earned": dup_score,
            "max": self.MAX_POINTS["duplicate_check"],
            "passed": dup_result.get("passed", False),
            "critical": dup_result.get("critical", False),
            "details": {
                "duplicates_found": dup_result.get("duplicates_found", 0),
                "duplicate_details": dup_result.get("duplicate_details", {})
            }
        }
        total_earned += dup_score
        total_max += self.MAX_POINTS["duplicate_check"]
        
        # Source 6: Phone Location Match (5 max)
        phone_result = detailed_results.get("phone_location", {})
        phone_score = phone_result.get("score", 0)
        source_scores["phone_location"] = {
            "earned": phone_score,
            "max": self.MAX_POINTS["phone_location"],
            "passed": phone_result.get("passed", True),
            "details": {
                "phone_area_code": phone_result.get("phone_area_code"),
                "expected_codes": phone_result.get("expected_codes", []),
                "matches": phone_result.get("matches", True)
            }
        }
        total_earned += phone_score
        total_max += self.MAX_POINTS["phone_location"]
        
        # Source 7: Business Hours (5 max)
        hours_result = detailed_results.get("business_hours", {})
        hours_score = hours_result.get("score", 0)
        source_scores["business_hours"] = {
            "earned": hours_score,
            "max": self.MAX_POINTS["business_hours"],
            "passed": hours_result.get("passed", True),
            "details": {
                "issues": hours_result.get("issues", [])
            }
        }
        total_earned += hours_score
        total_max += self.MAX_POINTS["business_hours"]
        
        # Source 8: License Validity (10 max)
        lic_result = detailed_results.get("license_validity", {})
        lic_score = lic_result.get("score", 0)
        source_scores["license_validity"] = {
            "earned": lic_score,
            "max": self.MAX_POINTS["license_validity"],
            "passed": lic_result.get("passed", False),
            "details": {
                "message": lic_result.get("message", ""),
                "license_number": lic_result.get("license_number")
            }
        }
        total_earned += lic_score
        total_max += self.MAX_POINTS["license_validity"]
        
        # ----------------------------------------------------------------
        # Cross-penalty: review complaints reduce the relevant check scores
        # If reviews say phone/location/hours/license is bad, penalize those
        # source scores directly (in addition to the review score penalty)
        # ----------------------------------------------------------------
        rev_details = source_scores["review_analysis"]["details"]
        raw_penalties = detailed_results.get("review_analysis", {}).get("verification_penalties", {})

        # verification_penalties from _analyze_reviews is a dict {flag: 0-1}
        # but after processing it becomes a list of strings like "bad_phone (-2pts)"
        # Re-fetch the raw dict from the Groq result via the stored details
        # We stored triggered_penalties as strings; re-parse them to apply cross-penalties
        triggered = rev_details.get("verification_penalties", [])

        def _has_penalty(flag_prefix: str) -> bool:
            return any(p.startswith(flag_prefix) for p in triggered)

        # bad_phone → reduce phone_location score by up to 3 pts
        if _has_penalty("bad_phone"):
            reduction = min(source_scores["phone_location"]["earned"], 3)
            source_scores["phone_location"]["earned"] = max(0, source_scores["phone_location"]["earned"] - reduction)
            source_scores["phone_location"]["passed"] = source_scores["phone_location"]["earned"] >= 3
            total_earned -= reduction

        # bad_location → reduce location_verification score by up to 5 pts
        if _has_penalty("bad_location"):
            reduction = min(source_scores["location_verification"]["earned"], 5)
            source_scores["location_verification"]["earned"] = max(0, source_scores["location_verification"]["earned"] - reduction)
            source_scores["location_verification"]["passed"] = source_scores["location_verification"]["earned"] >= 5
            total_earned -= reduction

        # bad_hours → reduce business_hours score by up to 3 pts
        if _has_penalty("bad_hours"):
            reduction = min(source_scores["business_hours"]["earned"], 3)
            source_scores["business_hours"]["earned"] = max(0, source_scores["business_hours"]["earned"] - reduction)
            source_scores["business_hours"]["passed"] = source_scores["business_hours"]["earned"] >= 3
            total_earned -= reduction

        # scam_reports → reduce business_existence score by up to 5 pts
        if _has_penalty("scam_reports"):
            reduction = min(source_scores["business_existence"]["earned"], 5)
            source_scores["business_existence"]["earned"] = max(0, source_scores["business_existence"]["earned"] - reduction)
            source_scores["business_existence"]["passed"] = source_scores["business_existence"]["earned"] >= 5
            total_earned -= reduction

        # license_issues → reduce license_validity score by up to 4 pts
        if _has_penalty("license_issues"):
            reduction = min(source_scores["license_validity"]["earned"], 4)
            source_scores["license_validity"]["earned"] = max(0, source_scores["license_validity"]["earned"] - reduction)
            source_scores["license_validity"]["passed"] = source_scores["license_validity"]["earned"] >= 5
            total_earned -= reduction

        # bad_social_media → reduce social_media score by up to 4 pts
        if _has_penalty("bad_social_media"):
            reduction = min(source_scores["social_media"]["earned"], 4)
            source_scores["social_media"]["earned"] = max(0, source_scores["social_media"]["earned"] - reduction)
            source_scores["social_media"]["passed"] = source_scores["social_media"]["earned"] >= 3
            total_earned -= reduction

        # Recalculate overall after cross-penalties
        total_earned = max(0, total_earned)

        # Calculate overall score (0-100)
        overall_score = (total_earned / total_max) * 100 if total_max > 0 else 0
        
        # Determine verification level
        if overall_score >= 80:
            verification_level = "trusted"
        elif overall_score >= 60:
            verification_level = "verified"
        elif overall_score >= 40:
            verification_level = "standard"
        else:
            verification_level = "basic"
        
        # Compile final report
        verification_report = {
            "provider_id": provider_id,
            "provider_name": provider_data.get("full_name", provider_data.get("business_name", "Unknown")),
            "verified_at": datetime.utcnow().isoformat(),
            "overall_score": round(overall_score, 1),
            "verification_level": verification_level,
            "total_earned": total_earned,
            "total_max": total_max,
            "source_scores": source_scores,
            "checks_passed": validation_result.get("checks_passed", []),
            "checks_failed": validation_result.get("checks_failed", []),
            "warnings": validation_result.get("warnings", []),
            "recommendations": validation_result.get("recommendations", [])
        }
        
        # Store in database
        await self._store_verification_result(provider_id, verification_report, db)
        
        return verification_report
    
    async def _get_provider_by_id(self, provider_id: str, db) -> Optional[Dict]:
        """Fetch provider data from MongoDB"""
        try:
            # Try ObjectId
            try:
                obj_id = ObjectId(provider_id)
                user = await db[mongodb.USERS].find_one({"_id": obj_id})
            except:
                user = await db[mongodb.USERS].find_one({"_id": provider_id})
            
            if not user:
                return None
            
            # Get service provider profile
            profile = await db[mongodb.SERVICE_PROVIDER_PROFILES].find_one({"user_id": str(user["_id"])})
            
            # Merge data — profile fields take priority over user fields
            # phone_number is stored as "phone_number" in both user and profile docs;
            # cross_validation_service reads it under the key "phone"
            phone_value = (
                (profile.get("phone_number") if profile else None)
                or user.get("phone_number")
                or user.get("phone")
            )
            result = {
                "_id": str(user["_id"]),
                "email": user.get("email"),
                "full_name": user.get("full_name"),
                "business_name": (profile.get("business_name") if profile else None) or user.get("business_name") or user.get("full_name"),
                "phone": phone_value,
                "phone_number": phone_value,
                "address": profile.get("address") if profile else None,
                "city": profile.get("city") if profile else None,
                "latitude": profile.get("latitude") if profile else None,
                "longitude": profile.get("longitude") if profile else None,
                "business_license": profile.get("business_license_number") if profile else None,
                "facebook_url": profile.get("facebook_url") if profile else None,
                "instagram_username": profile.get("instagram_username") if profile else None,
                "business_hours": profile.get("business_hours") if profile else {},
                "verified_flag": user.get("verified_flag", False),
                "account_type": user.get("account_type", "service_provider")
            }
            
            # Add provider profile if exists
            if profile:
                result["provider_profile"] = profile
            
            return result
            
        except Exception as e:
            print(f"Error fetching provider {provider_id}: {e}")
            return None
    
    async def _store_verification_result(self, provider_id: str, report: Dict, db):
        """Store verification result in MongoDB"""
        collection = db.provider_verifications
        
        # Update or insert
        await collection.update_one(
            {"provider_id": provider_id},
            {"$set": {
                "verification_report": report,
                "overall_score": report["overall_score"],
                "verification_level": report["verification_level"],
                "verified_at": report["verified_at"],
                "updated_at": datetime.utcnow().isoformat()
            }},
            upsert=True
        )
        
        # Also update service provider profile with verification score
        await db[mongodb.SERVICE_PROVIDER_PROFILES].update_one(
            {"user_id": provider_id},
            {"$set": {
                "verification_score": report["overall_score"],
                "verification_level": report["verification_level"],
                "last_verified_at": report["verified_at"]
            }}
        )
    
    async def get_provider_verification(self, provider_id: str) -> Optional[Dict]:
        """Get stored verification for a provider"""
        db = await self._get_db()
        collection = db.provider_verifications
        result = await collection.find_one({"provider_id": provider_id})
        
        if result:
            result.pop("_id", None)
            return result.get("verification_report")
        return None
    

    async def get_all_verified_providers(
        self,
        min_score: float = 0,
        limit: int = 100
    ) -> List[Dict]:
        """
        Get all providers with their verification scores
        Sorted by score descending (highest first)
        """
        db = await self._get_db()
        
        # First, get all service provider users
        service_providers = await db[mongodb.USERS].find({
            "account_type": "service_provider",
            "is_active": True
        }).to_list(length=limit * 2)
        
        results = []
        
        for user in service_providers:
            user_id = str(user["_id"])
            
            # Get verification data
            verification = await db.provider_verifications.find_one({"provider_id": user_id})
            verification_score = verification.get("overall_score", 0) if verification else 0
            
            # Skip if below min_score
            if verification_score < min_score:
                continue
            
            # Get provider profile
            profile = await db[mongodb.SERVICE_PROVIDER_PROFILES].find_one(
                {"user_id": user_id}
            )
            
            results.append({
                "user_id": user_id,
                "full_name": user.get("full_name"),
                "username": user.get("username"),
                "email": user.get("email"),
                "avatar_url": user.get("avatar_url"),
                "verification_score": verification_score,
                "verification_level": verification.get("verification_level", "unverified") if verification else "unverified",
                "profile": profile,
                "service_type": profile.get("service_type") if profile else None,
                "rating": profile.get("rating", 0) if profile else 0,
                "review_count": profile.get("review_count", 0) if profile else 0
            })
        
        # Sort by verification score descending
        results.sort(key=lambda x: x.get("verification_score", 0), reverse=True)
        
        return results[:limit]

    async def get_recommended_providers(
        self,
        limit: int = 20,
        service_type: Optional[str] = None,
        min_score: float = 0
    ) -> List[Dict]:
        """
        Get recommended service providers sorted by verification score
        Higher score = more trusted = higher recommendation
        """
        providers = await self.get_all_verified_providers(min_score=min_score, limit=limit)
        
        # Filter by service type if specified
        if service_type:
            providers = [
                p for p in providers
                if p.get("service_type") == service_type
            ]
        
        # Already sorted by verification_score descending
        return providers


# Global instance
provider_verification_service = ProviderVerificationService()