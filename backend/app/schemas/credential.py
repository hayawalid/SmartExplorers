"""
Credential Schemas for provider certifications
"""
from pydantic import BaseModel, Field
from typing import Optional
from datetime import date


class CredentialCreate(BaseModel):
    title: str = Field(..., max_length=200)
    issuer: str = Field(..., max_length=200)
    date_issued: date
    expiry_date: Optional[date] = None


class CredentialResponse(BaseModel):
    id: str
    provider_id: str
    title: str
    issuer: str
    date_issued: date
    expiry_date: Optional[date]
    certificate_url: str
    is_verified: bool
    created_at: datetime

    class Config:
        from_attributes = True


class CredentialUploadResponse(BaseModel):
    success: bool
    credential_id: str
    certificate_url: str