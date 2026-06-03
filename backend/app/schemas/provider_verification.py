"""
Provider Verification Schemas - For API response types
"""
from pydantic import BaseModel
from typing import Optional, List, Dict, Any
from datetime import datetime


class SourceVerificationDetail(BaseModel):
    earned: float
    max: float
    passed: bool
    details: Optional[Dict[str, Any]] = None


class VerificationReport(BaseModel):
    provider_id: str
    provider_name: str
    verified_at: str
    overall_score: float
    verification_level: str
    total_earned: float
    total_max: float
    source_scores: Dict[str, SourceVerificationDetail]
    checks_passed: List[str]
    checks_failed: List[str]
    warnings: List[str]
    recommendations: List[str]


class ProviderWithVerification(BaseModel):
    user_id: str
    full_name: str
    username: str
    email: str
    avatar_url: Optional[str] = None
    verification_score: float
    verification_level: str
    service_type: Optional[str] = None
    rating: float = 0
    review_count: int = 0