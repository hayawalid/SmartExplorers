from pydantic import BaseModel, Field, field_validator
from typing import List, Optional, Dict, Any
from datetime import datetime, date
from enum import Enum


class TravelSpaceStatus(str, Enum):
    FORMING = "forming"
    ACTIVE = "active"
    COMPLETED = "completed"
    CANCELLED = "cancelled"


class MembershipStatus(str, Enum):
    PENDING = "pending"
    APPROVED = "approved"
    REJECTED = "rejected"
    ACTIVE = "active"
    LEFT = "left"


class VoteType(str, Enum):
    APPROVE = "approve"
    REJECT = "reject"
    ABSTAIN = "abstain"


class TravelSpaceCreate(BaseModel):
    name: str = Field(..., min_length=3, max_length=255)
    description: Optional[str] = None
    destination: str
    start_date: date
    end_date: date
    itinerary_id: Optional[int] = None
    
    # Group config
    min_members: int = Field(2, ge=2, le=20)
    max_members: int = Field(10, ge=2, le=20)
    voting_threshold: float = Field(0.6, ge=0.5, le=1.0)
    require_verification: bool = True
    women_only: bool = False
    
    # Requirements
    min_age: int = Field(18, ge=13, le=100)
    max_age: Optional[int] = Field(None, ge=13, le=100)
    languages: List[str] = Field(default_factory=list)
    interests: List[str] = Field(default_factory=list)
    is_public: bool = True
    
    @field_validator('end_date')
    @classmethod
    def end_date_must_be_after_start_date(cls, v, info):
        if 'start_date' in info.data and v <= info.data['start_date']:
            raise ValueError('end_date must be after start_date')
        return v
    
    @field_validator('max_members')
    @classmethod
    def max_must_be_greater_than_min(cls, v, info):
        if 'min_members' in info.data and v < info.data['min_members']:
            raise ValueError('max_members must be >= min_members')
        return v


class MembershipApplication(BaseModel):
    application_message: Optional[str] = Field(None, max_length=1000)


class MembershipVoteRequest(BaseModel):
    vote: VoteType
    reason: Optional[str] = Field(None, max_length=500)


class MembershipVoteResponse(BaseModel):
    id: int
    voter_id: int
    vote: VoteType
    reason: Optional[str]
    created_at: datetime
    
    class Config:
        from_attributes = True


class MembershipResponse(BaseModel):
    id: int
    space_id: int
    user_id: int
    application_message: Optional[str]
    compatibility_score: Optional[float]
    status: MembershipStatus
    votes_for: int
    votes_against: int
    votes_needed: Optional[int]
    is_creator: bool
    role: str
    applied_at: datetime
    decided_at: Optional[datetime]
    joined_at: Optional[datetime]
    votes_received: List[MembershipVoteResponse] = []
    
    class Config:
        from_attributes = True


class TravelSpaceResponse(BaseModel):
    id: int
    name: str
    description: Optional[str]
    destination: str
    start_date: datetime
    end_date: datetime
    itinerary_id: Optional[int]
    
    min_members: int
    max_members: int
    current_members: int
    
    voting_threshold: float
    require_verification: bool
    women_only: bool
    
    min_age: int
    max_age: Optional[int]
    languages: Optional[List[str]]
    interests: Optional[List[str]]
    
    status: TravelSpaceStatus
    is_public: bool
    creator_id: int
    
    created_at: datetime
    updated_at: datetime
    activated_at: Optional[datetime]
    
    memberships: List[MembershipResponse] = []
    
    class Config:
        from_attributes = True


class TravelSpaceListItem(BaseModel):
    """Lightweight response for listing"""
    id: int
    name: str
    destination: str
    start_date: datetime
    end_date: datetime
    current_members: int
    max_members: int
    status: TravelSpaceStatus
    women_only: bool
    languages: Optional[List[str]]
    created_at: datetime
    
    class Config:
        from_attributes = True


class VotingStatus(BaseModel):
    membership_id: int
    applicant_id: int
    total_votes: int
    votes_for: int
    votes_against: int
    votes_needed: int
    threshold_met: bool
    is_approved: bool
    is_rejected: bool