from pydantic import BaseModel, Field, field_validator
from typing import Optional
from datetime import datetime
from enum import Enum


class VerificationMethod(str, Enum):
    NATIONAL_ID = "national_id"
    PASSPORT = "passport"
    DRIVERS_LICENSE = "drivers_license"


class VerificationStatus(str, Enum):
    PENDING = "pending"
    APPROVED = "approved"
    REJECTED = "rejected"
    FLAGGED = "flagged"
    EXPIRED = "expired"


class VerificationSubmitRequest(BaseModel):
    """Request schema for submitting identity verification"""
    verification_method: VerificationMethod
    
    # These will be extracted from OCR, but user can provide them
    document_number: Optional[str] = None
    full_name: Optional[str] = None
    date_of_birth: Optional[str] = None  # YYYY-MM-DD format
    nationality: Optional[str] = "Egyptian"
    
    @field_validator('date_of_birth')
    @classmethod
    def validate_dob(cls, v):
        if v:
            try:
                datetime.strptime(v, "%Y-%m-%d")
            except ValueError:
                raise ValueError("date_of_birth must be in YYYY-MM-DD format")
        return v


class VerificationResponse(BaseModel):
    """Response schema for verification status"""
    id: int
    user_id: int
    verification_method: VerificationMethod
    status: VerificationStatus
    
    # Face matching results (public)
    face_match_passed: bool
    face_match_confidence: Optional[float] = None
    
    # OCR confidence (public)
    ocr_confidence: Optional[float] = None
    
    # Fraud detection (public)
    is_fraudulent: bool
    fraud_reason: Optional[str] = None
    
    # Timestamps
    submitted_at: datetime
    verified_at: Optional[datetime] = None
    expires_at: Optional[datetime] = None
    
    # Status message
    message: Optional[str] = None
    
    class Config:
        from_attributes = True


class VerificationDetailResponse(VerificationResponse):
    """Detailed response with decrypted data (admin only)"""
    document_number: Optional[str] = None
    full_name: Optional[str] = None
    date_of_birth: Optional[str] = None
    nationality: Optional[str] = None
    gender: Optional[str] = None
    
    # Admin fields
    admin_notes: Optional[str] = None
    rejection_reason: Optional[str] = None
    verified_by_admin_id: Optional[int] = None


class VerificationApprovalRequest(BaseModel):
    """Request schema for admin approval/rejection"""
    approved: bool
    notes: Optional[str] = None
    rejection_reason: Optional[str] = None


class VerificationStatsResponse(BaseModel):
    """Statistics for admin dashboard"""
    total_submissions: int
    pending_count: int
    approved_count: int
    rejected_count: int
    flagged_count: int
    expired_count: int
    average_processing_time_hours: Optional[float] = None
    fraud_detection_rate: Optional[float] = None


class ImageValidationResponse(BaseModel):
    """Response for image quality validation"""
    valid: bool
    reason: Optional[str] = None
    width: Optional[int] = None
    height: Optional[int] = None
    file_size: Optional[int] = None
    brightness: Optional[float] = None


class FaceVerificationResult(BaseModel):
    """Face verification result"""
    verified: bool
    confidence: float
    passes_threshold: bool
    distance: Optional[float] = None
    model: Optional[str] = None
    error: Optional[str] = None


class OCRResult(BaseModel):
    """OCR extraction result"""
    document_type: str
    document_number: Optional[str] = None
    full_name: Optional[str] = None
    date_of_birth: Optional[str] = None
    nationality: Optional[str] = None
    gender: Optional[str] = None
    confidence: float
    raw_text: Optional[str] = None