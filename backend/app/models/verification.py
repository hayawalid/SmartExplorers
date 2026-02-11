from sqlalchemy import Column, Integer, String, Float, DateTime, Boolean, Text, Enum as SQLEnum
from datetime import datetime, timedelta
import enum

from database import Base


class VerificationMethod(str, enum.Enum):
    NATIONAL_ID = "national_id"
    PASSPORT = "passport"
    DRIVERS_LICENSE = "drivers_license"


class VerificationStatus(str, enum.Enum):
    PENDING = "pending"
    APPROVED = "approved"
    REJECTED = "rejected"
    FLAGGED = "flagged"
    EXPIRED = "expired"


class IdentityVerification(Base):
    __tablename__ = "identity_verifications"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, unique=True, nullable=False, index=True)
    
    # Verification method
    verification_method = Column(SQLEnum(VerificationMethod), nullable=False)
    status = Column(SQLEnum(VerificationStatus), default=VerificationStatus.PENDING, nullable=False)
    
    # ENCRYPTED FIELDS (All sensitive data is encrypted using Fernet)
    encrypted_document_number = Column(Text, nullable=False)  # National ID / Passport number
    encrypted_full_name = Column(Text, nullable=False)
    encrypted_date_of_birth = Column(Text, nullable=False)
    encrypted_nationality = Column(Text, nullable=True)
    encrypted_gender = Column(Text, nullable=True)
    
    # Image paths (stored separately in S3, referenced here)
    encrypted_document_image_path = Column(Text, nullable=False)
    encrypted_selfie_image_path = Column(Text, nullable=False)
    
    # OCR Results (metadata, not sensitive)
    ocr_confidence = Column(Float, nullable=True)
    ocr_extracted_text = Column(Text, nullable=True)  # Full OCR text for debugging
    
    # Face Matching (metadata only, not sensitive)
    face_match_confidence = Column(Float, nullable=True)
    face_match_threshold = Column(Float, default=0.7)
    face_match_passed = Column(Boolean, default=False)
    face_match_distance = Column(Float, nullable=True)
    face_match_model = Column(String(50), nullable=True)
    
    # Fraud Detection
    is_fraudulent = Column(Boolean, default=False)
    fraud_reason = Column(Text, nullable=True)
    fraud_confidence = Column(Float, nullable=True)
    
    # Admin Review
    verified_by_admin_id = Column(Integer, nullable=True)
    admin_notes = Column(Text, nullable=True)
    rejection_reason = Column(Text, nullable=True)
    
    # Audit Trail
    submission_ip = Column(String(45), nullable=True)
    submission_user_agent = Column(String(500), nullable=True)
    encryption_key_version = Column(String(50), default='v1')
    
    # Timestamps
    submitted_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    verified_at = Column(DateTime, nullable=True)
    expires_at = Column(DateTime, nullable=True)  # Verification expires after 1 year
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)
    
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        # Set expiry to 1 year from submission
        if not self.expires_at:
            self.expires_at = datetime.utcnow() + timedelta(days=365)
    
    def is_expired(self) -> bool:
        """Check if verification has expired"""
        if self.expires_at:
            return datetime.utcnow() > self.expires_at
        return False


class VerificationAuditLog(Base):
    """Immutable audit log for all verification actions"""
    __tablename__ = "verification_audit_logs"

    id = Column(Integer, primary_key=True, index=True)
    verification_id = Column(Integer, nullable=False, index=True)
    user_id = Column(Integer, nullable=False)
    
    # Action details
    action = Column(String(50), nullable=False)  # submitted, approved, rejected, accessed, decrypted
    actor_id = Column(Integer, nullable=True)  # Admin who performed action
    actor_role = Column(String(50), nullable=True)  # admin, system, ml_model
    
    # Context
    details = Column(Text, nullable=True)  # JSON with action details
    ip_address = Column(String(45), nullable=True)
    user_agent = Column(String(500), nullable=True)
    
    # Timestamp (immutable)
    timestamp = Column(DateTime, default=datetime.utcnow, nullable=False)
    
    def __repr__(self):
        return f"<AuditLog {self.action} on verification {self.verification_id} at {self.timestamp}>"