"""
Identity Verification Service - Main orchestrator with OCR
"""
from typing import Dict, Optional, Tuple
from datetime import datetime, timedelta
from sqlalchemy.orm import Session

from .encryption import encryption_service
from .face_verification import face_verification_service
from .ocr_service import ocr_service
from ..models.verification import (
    IdentityVerification, VerificationAuditLog,
    VerificationStatus, VerificationMethod
)


class IdentityVerificationService:
    """Main service for identity verification workflow with OCR"""
    
    def __init__(self):
        self.encryption = encryption_service
        self.face_verifier = face_verification_service
        self.ocr = ocr_service
        self.face_match_threshold = 0.70
    
    async def submit_verification(
        self,
        db: Session,
        user_id: int,
        verification_data: Dict,
        document_image: bytes,
        selfie_image: bytes,
        ip_address: Optional[str] = None,
        user_agent: Optional[str] = None
    ) -> Tuple[IdentityVerification, Dict]:
        """
        Submit new identity verification with OCR extraction
        
        Workflow:
        1. Extract text from ID using OCR
        2. Validate image quality
        3. Perform face matching (ID photo vs selfie)
        4. Encrypt sensitive data
        5. Store in database
        """
        
        # Check if user already has verification
        existing = db.query(IdentityVerification).filter(
            IdentityVerification.user_id == user_id
        ).first()
        
        if existing and existing.status in [VerificationStatus.APPROVED, VerificationStatus.PENDING]:
            raise ValueError(f"User already has {existing.status.value} verification")
        
        # ============================================
        # STEP 1: OCR - Extract text from ID card
        # ============================================
        print("\n" + "="*60)
        print("STEP 1: OCR Text Extraction")
        print("="*60)
        
        ocr_result = self.ocr.extract_text_from_id(document_image)
        
        if ocr_result.get("error"):
            print(f"⚠️  OCR Warning: {ocr_result['error']}")
        
        # Use OCR data if available, otherwise fallback to user input
        document_number = ocr_result.get("document_number") or verification_data.get('document_number')
        full_name = ocr_result.get("name") or verification_data.get('full_name')
        date_of_birth = ocr_result.get("date_of_birth") or verification_data.get('date_of_birth')
        nationality = ocr_result.get("nationality") or verification_data.get('nationality')
        
        print(f"\n📋 Extracted Data:")
        print(f"   Document Number: {document_number}")
        print(f"   Full Name: {full_name}")
        print(f"   Date of Birth: {date_of_birth}")
        print(f"   Nationality: {nationality}")
        print(f"   OCR Confidence: {ocr_result.get('confidence', 0):.2%}")
        
        # ============================================
        # STEP 2: Validate image quality
        # ============================================
        print("\n" + "="*60)
        print("STEP 2: Image Quality Validation")
        print("="*60)
        
        doc_quality = self.face_verifier.analyze_face_quality(document_image)
        if not doc_quality['suitable_for_verification']:
            raise ValueError(f"Document image issues: {', '.join(doc_quality['issues'])}")
        
        print(f"✓ Document image: OK")
        print(f"   Brightness: {doc_quality['brightness']}")
        print(f"   Sharpness: {doc_quality['sharpness']}")
        
        selfie_quality = self.face_verifier.analyze_face_quality(selfie_image)
        if not selfie_quality['suitable_for_verification']:
            raise ValueError(f"Selfie issues: {', '.join(selfie_quality['issues'])}")
        
        print(f"✓ Selfie image: OK")
        
        # ============================================
        # STEP 3: Face matching (ID photo vs Selfie)
        # ============================================
        print("\n" + "="*60)
        print("STEP 3: Face Matching (DeepFace)")
        print("="*60)
        
        face_result = self.face_verifier.verify_faces(
            document_image,
            selfie_image,
            threshold=self.face_match_threshold
        )
        
        print(f"\n👤 Face Match Results:")
        print(f"   Matched: {'✓ YES' if face_result['verified'] else '✗ NO'}")
        print(f"   Confidence: {face_result['confidence']:.2%}")
        print(f"   Fraud Risk: {face_result['fraud_risk'].upper()}")
        print(f"   Threshold: {face_result['threshold']:.2%}")
        
        # ============================================
        # STEP 4: Encrypt sensitive data
        # ============================================
        print("\n" + "="*60)
        print("STEP 4: Data Encryption")
        print("="*60)
        
        encrypted_doc_number = self.encryption.encrypt(str(document_number))
        encrypted_name = self.encryption.encrypt(str(full_name))
        encrypted_dob = self.encryption.encrypt(str(date_of_birth))
        encrypted_nationality = self.encryption.encrypt(
            str(nationality)
        ) if nationality else None
        
        print("✓ Document number encrypted")
        print("✓ Full name encrypted")
        print("✓ Date of birth encrypted")
        if nationality:
            print("✓ Nationality encrypted")
        
        # Create image paths (in production, store in S3)
        doc_image_path = f"verifications/{user_id}/document_{datetime.utcnow().timestamp()}.jpg"
        selfie_path = f"verifications/{user_id}/selfie_{datetime.utcnow().timestamp()}.jpg"
        
        encrypted_doc_path = self.encryption.encrypt(doc_image_path)
        encrypted_selfie_path = self.encryption.encrypt(selfie_path)
        
        # ============================================
        # STEP 5: Determine fraud status
        # ============================================
        is_fraudulent = False
        fraud_reason = None
        fraud_confidence = None
        
        if not face_result['verified']:
            is_fraudulent = True
            fraud_reason = f"Face match failed. Confidence: {face_result['confidence']:.2%}"
            fraud_confidence = 1.0 - face_result['confidence']
        elif face_result['fraud_risk'] == 'high':
            is_fraudulent = True
            fraud_reason = f"High fraud risk. Confidence: {face_result['confidence']:.2%}"
            fraud_confidence = 1.0 - face_result['confidence']
        
        # ============================================
        # STEP 6: Store in database
        # ============================================
        print("\n" + "="*60)
        print("STEP 6: Database Storage")
        print("="*60)
        
        verification = IdentityVerification(
            user_id=user_id,
            verification_method=VerificationMethod(verification_data['verification_method']),
            status=VerificationStatus.FLAGGED if is_fraudulent else VerificationStatus.PENDING,
            encrypted_document_number=encrypted_doc_number,
            encrypted_full_name=encrypted_name,
            encrypted_date_of_birth=encrypted_dob,
            encrypted_nationality=encrypted_nationality,
            encrypted_document_image_path=encrypted_doc_path,
            encrypted_selfie_image_path=encrypted_selfie_path,
            face_match_confidence=face_result['confidence'],
            face_match_threshold=self.face_match_threshold,
            face_match_passed=face_result['verified'],
            is_fraudulent=is_fraudulent,
            fraud_reason=fraud_reason,
            fraud_confidence=fraud_confidence,
            submission_ip=ip_address,
            user_agent=user_agent,
            expires_at=datetime.utcnow() + timedelta(days=365)
        )
        
        db.add(verification)
        db.flush()
        
        print(f"✓ Verification record created (ID: {verification.id})")
        print(f"   Status: {verification.status.value.upper()}")
        
        # Log submission
        audit_log = VerificationAuditLog(
            verification_id=verification.id,
            user_id=user_id,
            action="submitted",
            actor_role="user",
            details=f"Verification submitted. Face match: {face_result['verified']}. OCR confidence: {ocr_result.get('confidence', 0):.2%}",
            ip_address=ip_address,
            user_agent=user_agent
        )
        db.add(audit_log)
        
        db.commit()
        db.refresh(verification)
        
        print("✓ Audit log created")
        print("\n" + "="*60)
        print("✅ VERIFICATION COMPLETE")
        print("="*60 + "\n")
        
        return verification, {
            **face_result,
            "ocr_confidence": ocr_result.get('confidence', 0),
            "ocr_extracted": {
                "document_number": document_number,
                "name": full_name,
                "dob": date_of_birth,
                "nationality": nationality
            }
        }
    
    def get_verification_decrypted(
        self,
        db: Session,
        verification_id: int,
        requester_id: int,
        requester_role: str
    ) -> Optional[Dict]:
        """Get verification with decrypted data (admin only)"""
        if requester_role != "admin":
            raise PermissionError("Only admins can access decrypted data")
        
        verification = db.query(IdentityVerification).filter(
            IdentityVerification.id == verification_id
        ).first()
        
        if not verification:
            return None
        
        print(f"\n🔓 Decrypting verification #{verification_id}...")
        
        decrypted = {
            "id": verification.id,
            "user_id": verification.user_id,
            "verification_method": verification.verification_method.value,
            "status": verification.status.value,
            "document_number": self.encryption.decrypt(
                verification.encrypted_document_number,
                verification.encryption_key_version
            ),
            "full_name": self.encryption.decrypt(
                verification.encrypted_full_name,
                verification.encryption_key_version
            ),
            "date_of_birth": self.encryption.decrypt(
                verification.encrypted_date_of_birth,
                verification.encryption_key_version
            ),
            "nationality": self.encryption.decrypt(
                verification.encrypted_nationality,
                verification.encryption_key_version
            ) if verification.encrypted_nationality else None,
            "face_match_confidence": verification.face_match_confidence,
            "face_match_passed": verification.face_match_passed,
            "is_fraudulent": verification.is_fraudulent,
            "fraud_reason": verification.fraud_reason,
            "submitted_at": verification.submitted_at,
            "verified_at": verification.verified_at
        }
        
        print("✓ Data decrypted successfully")
        print(f"   Name: {decrypted['full_name']}")
        print(f"   ID Number: {decrypted['document_number']}")
        
        # Log access
        audit_log = VerificationAuditLog(
            verification_id=verification.id,
            user_id=verification.user_id,
            action="accessed",
            actor_id=requester_id,
            actor_role="admin",
            details="Decrypted data accessed"
        )
        db.add(audit_log)
        db.commit()
        
        return decrypted
    
    def approve_verification(
        self,
        db: Session,
        verification_id: int,
        admin_id: int,
        notes: Optional[str] = None
    ) -> IdentityVerification:
        """Approve a verification"""
        verification = db.query(IdentityVerification).filter(
            IdentityVerification.id == verification_id
        ).first()
        
        if not verification:
            raise ValueError("Verification not found")
        
        if verification.status == VerificationStatus.APPROVED:
            raise ValueError("Already approved")
        
        verification.status = VerificationStatus.APPROVED
        verification.verified_at = datetime.utcnow()
        verification.verified_by_admin_id = admin_id
        verification.admin_notes = notes
        
        audit_log = VerificationAuditLog(
            verification_id=verification.id,
            user_id=verification.user_id,
            action="approved",
            actor_id=admin_id,
            actor_role="admin",
            details=notes or "Approved"
        )
        db.add(audit_log)
        
        db.commit()
        db.refresh(verification)
        return verification
    
    def reject_verification(
        self,
        db: Session,
        verification_id: int,
        admin_id: int,
        reason: str
    ) -> IdentityVerification:
        """Reject a verification"""
        verification = db.query(IdentityVerification).filter(
            IdentityVerification.id == verification_id
        ).first()
        
        if not verification:
            raise ValueError("Verification not found")
        
        verification.status = VerificationStatus.REJECTED
        verification.verified_at = datetime.utcnow()
        verification.verified_by_admin_id = admin_id
        verification.admin_notes = reason
        
        audit_log = VerificationAuditLog(
            verification_id=verification.id,
            user_id=verification.user_id,
            action="rejected",
            actor_id=admin_id,
            actor_role="admin",
            details=reason
        )
        db.add(audit_log)
        
        db.commit()
        db.refresh(verification)
        return verification
    
    def get_verification_stats(self, db: Session) -> Dict:
        """Get verification statistics"""
        total = db.query(IdentityVerification).count()
        pending = db.query(IdentityVerification).filter(
            IdentityVerification.status == VerificationStatus.PENDING
        ).count()
        approved = db.query(IdentityVerification).filter(
            IdentityVerification.status == VerificationStatus.APPROVED
        ).count()
        rejected = db.query(IdentityVerification).filter(
            IdentityVerification.status == VerificationStatus.REJECTED
        ).count()
        flagged = db.query(IdentityVerification).filter(
            IdentityVerification.status == VerificationStatus.FLAGGED
        ).count()
        
        fraudulent = db.query(IdentityVerification).filter(
            IdentityVerification.is_fraudulent == True
        ).count()
        
        fraud_rate = (fraudulent / total * 100) if total > 0 else 0.0
        
        return {
            "total_submissions": total,
            "pending": pending,
            "approved": approved,
            "rejected": rejected,
            "flagged": flagged,
            "fraud_rate": round(fraud_rate, 2)
        }


# Global singleton
verification_service = IdentityVerificationService()