"""
Verification Orchestrator - Central hub for all verification workflows
Combines identity verification, cross-validation, and fraud detection
"""
from typing import Dict, List, Any, Optional
from datetime import datetime
from enum import Enum
import asyncio

from .cross_validation_service import cross_validation_service
from .face_verification import face_verification_service
from .encryption import encryption_service
from app.config import settings


class VerificationTier(str, Enum):
    """Verification tiers with different requirements"""
    BASIC = "basic"         # Phone + Email
    STANDARD = "standard"   # Basic + ID + Selfie
    VERIFIED = "verified"   # Standard + Cross-validation (60+ score)
    TRUSTED = "trusted"     # Verified + Social media + Reviews (80+ score)


class VerificationOrchestrator:
    """
    Central orchestrator for all verification workflows
    
    Combines:
    1. Identity verification (Face + ID)
    2. Cross-validation (Location, Social, Reviews)
    3. Fraud detection (Duplicates, Patterns)
    4. Continuous monitoring
    """
    
    def __init__(self):
        """Initialize verification services"""
        self.cross_validator = cross_validation_service
        self.face_verifier = face_verification_service
        self.encryption = encryption_service
        
    async def verify_service_provider_complete(
        self,
        provider_data: Dict[str, Any],
        id_document_image: Optional[bytes] = None,
        selfie_image: Optional[bytes] = None,
        db=None
    ) -> Dict[str, Any]:
        """
        Complete verification workflow for service provider
        
        Args:
            provider_data: Provider information
            id_document_image: ID document photo (bytes)
            selfie_image: Live selfie (bytes)
            db: MongoDB database instance
            
        Returns:
            Complete verification report with tier and badges
        """
        
        verification_report = {
            "provider_id": provider_data.get("_id"),
            "timestamp": datetime.utcnow().isoformat(),
            "tier": VerificationTier.BASIC,
            "overall_score": 0.0,
            "badges": [],
            "verification_steps": {},
            "warnings": [],
            "next_steps": []
        }
        
        # ====================================================================
        # STEP 1: Basic Verification (Phone + Email)
        # ====================================================================
        
        basic_checks = {
            "phone_verified": provider_data.get("phone_verified", False),
            "email_verified": provider_data.get("email_verified", False),
        }
        
        verification_report["verification_steps"]["basic"] = basic_checks
        
        if all(basic_checks.values()):
            verification_report["tier"] = VerificationTier.BASIC
            verification_report["overall_score"] = 20.0
        else:
            missing = [k for k, v in basic_checks.items() if not v]
            verification_report["next_steps"].append(
                f"Complete basic verification: {', '.join(missing)}"
            )
            return verification_report
        
        # ====================================================================
        # STEP 2: Identity Verification (ID + Selfie + Face Match)
        # ====================================================================
        
        if id_document_image and selfie_image:
            print("\n" + "=" * 70)
            print("IDENTITY VERIFICATION")
            print("=" * 70)
            
            face_result = self.face_verifier.verify_faces(
                id_document_image,
                selfie_image
            )
            
            verification_report["verification_steps"]["identity"] = {
                "face_match_verified": face_result["verified"],
                "face_match_confidence": face_result["confidence"],
                "fraud_risk": face_result["fraud_risk"]
            }
            
            if face_result["verified"]:
                verification_report["tier"] = VerificationTier.STANDARD
                verification_report["overall_score"] = 40.0
                verification_report["badges"].append("identity_verified")
                
                print(f"Identity verified - Confidence: {face_result['confidence']:.2%}")
            else:
                verification_report["warnings"].append(
                    f"Face match failed - Confidence: {face_result['confidence']:.2%}"
                )
                verification_report["next_steps"].append(
                    "Resubmit ID and selfie with better lighting"
                )
                return verification_report
        else:
            verification_report["next_steps"].append(
                "Submit ID document and live selfie for identity verification"
            )
        
        # ====================================================================
        # STEP 3: Cross-Validation (Location, Business, Social Media)
        # ====================================================================
        
        if db:
            print("\n" + "=" * 70)
            print("CROSS-VALIDATION")
            print("=" * 70)
            
            cross_validation_result = await self.cross_validator.verify_service_provider(
                provider_data=provider_data,
                db=db
            )
            
            verification_report["verification_steps"]["cross_validation"] = cross_validation_result
            
            cv_score = cross_validation_result.get("overall_score", 0)
            verification_report["overall_score"] += cv_score * 0.6  # 60% weight
            
            print(f"\nCross-validation score: {cv_score:.1f}/100")
            
            total_score = verification_report["overall_score"]
            
            if total_score >= 80:
                verification_report["tier"] = VerificationTier.TRUSTED
                verification_report["badges"].extend([
                    "trusted_provider",
                    "safety_verified",
                    "business_verified"
                ])
            elif total_score >= 60:
                verification_report["tier"] = VerificationTier.VERIFIED
                verification_report["badges"].extend([
                    "verified_provider",
                    "location_verified"
                ])
            
            passed_checks = cross_validation_result.get("checks_passed", [])
            
            if "business_existence" in passed_checks:
                verification_report["badges"].append("google_verified")
            
            if "social_media" in passed_checks:
                verification_report["badges"].append("social_verified")
            
            if "review_analysis" in passed_checks:
                avg_rating = cross_validation_result.get("detailed_results", {}).get(
                    "review_analysis", {}
                ).get("average_rating", 0)
                
                if avg_rating >= 4.5:
                    verification_report["badges"].append("highly_rated")
                elif avg_rating >= 4.0:
                    verification_report["badges"].append("well_rated")
            
            verification_report["warnings"].extend(
                cross_validation_result.get("warnings", [])
            )
            verification_report["next_steps"].extend(
                cross_validation_result.get("recommendations", [])
            )
        
        # ====================================================================
        # STEP 4: Fraud Detection
        # ====================================================================
        
        fraud_indicators = self._detect_fraud_patterns(
            provider_data,
            verification_report
        )
        
        verification_report["verification_steps"]["fraud_detection"] = fraud_indicators
        
        if fraud_indicators.get("high_risk"):
            verification_report["warnings"].append(
                "FRAUD ALERT: " + fraud_indicators.get("reason", "Unknown")
            )
            verification_report["tier"] = VerificationTier.BASIC  # Downgrade
            verification_report["overall_score"] *= 0.5  # Penalize score
        
        # ====================================================================
        # FINAL REPORT
        # ====================================================================
        
        print("\n" + "=" * 70)
        print("VERIFICATION SUMMARY")
        print("=" * 70)
        print(f"Tier: {verification_report['tier'].value.upper()}")
        print(f"Overall Score: {verification_report['overall_score']:.1f}/100")
        print(f"Badges: {', '.join(verification_report['badges']) if verification_report['badges'] else 'None'}")
        print(f"Warnings: {len(verification_report['warnings'])}")
        print("=" * 70 + "\n")
        
        return verification_report
    
    async def verify_place_complete(
        self,
        place_data: Dict[str, Any]
    ) -> Dict[str, Any]:
        """
        Complete verification workflow for a place/location
        
        Args:
            place_data: Place information (name, address, coordinates)
            
        Returns:
            Place verification report with safety assessment
        """
        
        print("\n" + "=" * 70)
        print(f"VERIFYING PLACE: {place_data.get('name')}")
        print("=" * 70)
        
        # Cross-validate place
        place_verification = await self.cross_validator.verify_place(place_data)
        
        # Calculate trust score
        trust_score = 0.0
        
        if place_verification.get("exists"):
            trust_score += 30.0
        
        if place_verification.get("verified"):
            trust_score += 30.0
            
            if place_verification.get("confidence") == "high":
                trust_score += 10.0
        
        safety_score = place_verification.get("safety_score", 0.0)
        trust_score += safety_score * 0.3  # 30% weight
        
        # Determine badges
        badges = []
        
        if place_verification.get("exists"):
            badges.append("location_verified")
        
        if place_verification.get("verified"):
            badges.append("cross_verified")
        
        safety_level = place_verification.get("safety_level", "unknown")
        if safety_level == "high":
            badges.append("safe_for_tourists")
        
        accessibility_score = place_verification.get("accessibility_score", 0.0)
        if accessibility_score >= 70:
            badges.append("wheelchair_accessible")
        
        result = {
            "place_name": place_data.get("name"),
            "timestamp": datetime.utcnow().isoformat(),
            "exists": place_verification.get("exists", False),
            "verified": place_verification.get("verified", False),
            "trust_score": round(trust_score, 1),
            "safety_level": safety_level,
            "safety_score": round(safety_score, 1),
            "accessibility_score": round(accessibility_score, 1),
            "badges": badges,
            "sources": place_verification.get("sources", {}),
            "safety_notes": place_verification.get("safety_notes", []),
            "accessibility_features": place_verification.get("accessibility_features", [])
        }
        
        print(f"\nPlace Verification Complete")
        print(f"   Trust Score: {result['trust_score']}/100")
        print(f"   Safety Level: {result['safety_level'].upper()}")
        print(f"   Badges: {', '.join(badges)}")
        print("=" * 70 + "\n")
        
        return result
    
    def _detect_fraud_patterns(
        self,
        provider_data: Dict[str, Any],
        verification_report: Dict[str, Any]
    ) -> Dict[str, Any]:
        """
        Detect fraud patterns and suspicious behavior
        
        Checks:
        1. Duplicate accounts
        2. Suspicious contact info patterns
        3. Inconsistent data
        4. Red flags from reviews
        5. Failed checks combination
        """
        
        fraud_indicators = {
            "high_risk": False,
            "medium_risk": False,
            "risk_score": 0.0,
            "indicators": [],
            "reason": None
        }
        
        cross_val = verification_report.get("verification_steps", {}).get("cross_validation", {})
        duplicate_check = cross_val.get("detailed_results", {}).get("duplicate_check", {})
        
        if duplicate_check.get("duplicates_found", 0) > 0:
            fraud_indicators["high_risk"] = True
            fraud_indicators["risk_score"] += 50.0
            fraud_indicators["indicators"].append("duplicate_account_detected")
            fraud_indicators["reason"] = "Duplicate account detected in database"
            return fraud_indicators
        
        phone_location = cross_val.get("detailed_results", {}).get("phone_location", {})
        if not phone_location.get("matches", True):
            fraud_indicators["medium_risk"] = True
            fraud_indicators["risk_score"] += 15.0
            fraud_indicators["indicators"].append("phone_location_mismatch")
        
        business_check = cross_val.get("detailed_results", {}).get("business_existence", {})
        if not business_check.get("passed", False):
            fraud_indicators["medium_risk"] = True
            fraud_indicators["risk_score"] += 20.0
            fraud_indicators["indicators"].append("business_not_found")
        
        review_analysis = cross_val.get("detailed_results", {}).get("review_analysis", {})
        if review_analysis.get("red_flags"):
            fraud_indicators["medium_risk"] = True
            fraud_indicators["risk_score"] += 15.0
            fraud_indicators["indicators"].append("review_red_flags")
        
        authenticity = review_analysis.get("authenticity_score", 1.0)
        if authenticity < 0.5:
            fraud_indicators["high_risk"] = True
            fraud_indicators["risk_score"] += 30.0
            fraud_indicators["indicators"].append("fake_reviews_suspected")
            fraud_indicators["reason"] = f"Low review authenticity ({authenticity:.0%})"
        
        identity_check = verification_report.get("verification_steps", {}).get("identity", {})
        if identity_check.get("fraud_risk") == "high":
            fraud_indicators["high_risk"] = True
            fraud_indicators["risk_score"] += 40.0
            fraud_indicators["indicators"].append("face_match_fraud_risk")
            fraud_indicators["reason"] = "High fraud risk from face verification"
        
        if fraud_indicators["risk_score"] >= 50:
            fraud_indicators["high_risk"] = True
        elif fraud_indicators["risk_score"] >= 25:
            fraud_indicators["medium_risk"] = True
        
        return fraud_indicators
    
    async def continuous_monitoring(
        self,
        provider_id: str,
        db
    ) -> Dict[str, Any]:
        """
        Continuous monitoring of verified providers
        
        Checks:
        1. New negative reviews
        2. Social media deactivation
        3. License expiration
        4. Safety incidents
        """
        
        # TODO: Implement continuous monitoring (daily cron job)
        return {
            "provider_id": provider_id,
            "last_checked": datetime.utcnow().isoformat(),
            "status": "active",
            "alerts": []
        }
    
    def get_verification_badge_html(
        self,
        tier: VerificationTier,
        badges: List[str]
    ) -> str:
        """Generate HTML badge for display"""
        
        tier_config = {
            VerificationTier.BASIC: {
                "color": "#6B7280",
                "icon": "●",
                "label": "Basic"
            },
            VerificationTier.STANDARD: {
                "color": "#3B82F6",
                "icon": "✓",
                "label": "Verified"
            },
            VerificationTier.VERIFIED: {
                "color": "#10B981",
                "icon": "✓✓",
                "label": "Verified"
            },
            VerificationTier.TRUSTED: {
                "color": "#D4AF37",
                "icon": "★",
                "label": "Trusted"
            }
        }
        
        config = tier_config.get(tier, tier_config[VerificationTier.BASIC])
        
        badge_html = f"""
        <div style="
            display: inline-flex;
            align-items: center;
            background: {config['color']};
            color: white;
            padding: 4px 12px;
            border-radius: 12px;
            font-size: 12px;
            font-weight: 600;
        ">
            <span style="margin-right: 4px;">{config['icon']}</span>
            {config['label']}
        </div>
        """
        
        return badge_html.strip()


# Global instance
verification_orchestrator = VerificationOrchestrator()
