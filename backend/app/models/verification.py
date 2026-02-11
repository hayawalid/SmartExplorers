"""
Identity Verification Models
Stores encrypted verification data with privacy-first approach
"""
from sqlalchemy import Column, Integer, String, DateTime, Boolean, Float, Text, Enum as SQLEnum
from sqlalchemy.sql import func
from datetime import datetime
import enum

from ..database import Base


class VerificationStatus(str, enum.Enum):
    PENDING = "pending"
    APPROVED = "approved"
    REJECTED = "rejected"
    FLAGGED = "flagged"
    EXPIRED = "expired"


class VerificationMethod(str, enum.Enum):
    NATIONAL_ID = "national_id"
    PASSPORT = "passport"
    DRIVERS_LICENSE = "drivers_license"


class IdentityVerification(Base):
    """
    Stores encrypted identity verification data
    All sensitive data is encrypted at rest
    """
    __tablename__ = "identity_verifications"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, unique=True, index=True, nullable=False)
    
    # Verification details
    verification_method = Column(SQLEnum(VerificationMethod), nullable=False)
    status = Column(SQLEnum(VerificationStatus), default=VerificationStatus.PENDING, nullable=False)
    
    # Encrypted document data (encrypted with Fernet)
    encrypted_document_number = Column(Text, nullable=False)
    encrypted_full_name = Column(Text, nullable=False)
    encrypted_date_of_birth = Column(Text, nullable=False)
    encrypted_nationality = Column(Text, nullable=True)
    
    # Encrypted file paths
    encrypted_document_image_path = Column(Text, nullable=False)
    encrypted_selfie_image_path = Column(Text, nullable=False)
    
    # Face matching results (NOT encrypted - just metadata)
    face_match_confidence = Column(Float, nullable=True)
    face_match_threshold = Column(Float, default=0.7, nullable=False)
    face_match_passed = Column(Boolean, default=False, nullable=False)
    
    # Fraud flags
    is_fraudulent = Column(Boolean, default=False, nullable=False)
    fraud_reason = Column(Text, nullable=True)
    fraud_confidence = Column(Float, nullable=True)
    
    # Admin verification
    verified_by_admin_id = Column(Integer, nullable=True)
    admin_notes = Column(Text, nullable=True)
    
    # Timestamps
    submitted_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    verified_at = Column(DateTime, nullable=True)
    expires_at = Column(DateTime, nullable=True)
    
    # Metadata
    submission_ip = Column(String(45), nullable=True)
    user_agent = Column(String(500), nullable=True)
    encryption_key_version = Column(String(50), default="v1", nullable=False)
    
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)


class VerificationAuditLog(Base):
    """Audit trail for verification actions"""
    __tablename__ = "verification_audit_logs"

    id = Column(Integer, primary_key=True, index=True)
    verification_id = Column(Integer, index=True, nullable=False)
    user_id = Column(Integer, index=True, nullable=False)
    
    action = Column(String(50), nullable=False)
    actor_id = Column(Integer, nullable=True)
    actor_role = Column(String(50), nullable=True)
    
    details = Column(Text, nullable=True)
    ip_address = Column(String(45), nullable=True)
    user_agent = Column(String(500), nullable=True)
    
    timestamp = Column(DateTime, default=datetime.utcnow, nullable=False, index=True)