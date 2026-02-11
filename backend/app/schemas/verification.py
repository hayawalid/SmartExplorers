"""
Pydantic schemas for identity verification
"""
from pydantic import BaseModel, Field, field_validator
from typing import Optional
from datetime import datetime
from enum import Enum


class VerificationStatus(str, Enum):
    PENDING = "pending"
    APPROVED = "approved"
    REJECTED = "rejected"
    FLAGGED = "flagged"
    EXPIRED = "expired"


class VerificationMethod(str, Enum):
    NATIONAL_ID = "national_id"
    PASSPORT = "passport"
    DRIVERS_LICENSE = "drivers_license"


class VerificationSubmitRequest(BaseModel):
    """Request to submit identity verification"""
    verification_method: VerificationMethod
    document_number: str = Field(..., min_length=5, max_length=50)
    full_name: str = Field(..., min_length=2, max_length=200)
    date_of_birth: str = Field(..., pattern=r'^\d{4}-\d{2}-\d{2}$')
    nationality: Optional[str] = Field(None, max_length=100)


class VerificationResponse(BaseModel):
    """Public response for verification status"""
    id: int
    user_id: int
    verification_method: VerificationMethod
    status: VerificationStatus
    face_match_passed: bool
    face_match_confidence: Optional[float] = None
    is_fraudulent: bool
    fraud_reason: Optional[str] = None
    submitted_at: datetime
    verified_at: Optional[datetime] = None
    expires_at: Optional[datetime] = None
    
    class Config:
        from_attributes = True


class VerificationDetailResponse(BaseModel):
    """Detailed verification response (admin only)"""
    id: int
    user_id: int
    verification_method: VerificationMethod
    status: VerificationStatus
    document_number: str
    full_name: str
    date_of_birth: str
    nationality: Optional[str] = None
    face_match_confidence: Optional[float] = None
    face_match_threshold: float
    face_match_passed: bool
    is_fraudulent: bool
    fraud_reason: Optional[str] = None
    submitted_at: datetime
    verified_at: Optional[datetime] = None
    
    class Config:
        from_attributes = True


class VerificationApprovalRequest(BaseModel):
    """Admin approval/rejection request"""
    approved: bool
    notes: Optional[str] = Field(None, max_length=1000)


class VerificationStatsResponse(BaseModel):
    """Verification statistics"""
    total_submissions: int
    pending: int
    approved: int
    rejected: int
    flagged: int
    fraud_rate: float