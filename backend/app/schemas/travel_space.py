"""
Travel Space Schemas for Pydantic models
"""
from pydantic import BaseModel, Field, field_validator
from typing import List, Optional, Dict, Any
from datetime import datetime, date
from enum import Enum


class TravelSpaceStatus(str, Enum):
    FORMING = "forming"      # Accepting join requests
    ACTIVE = "active"        # Trip in progress
    COMPLETED = "completed"
    CANCELLED = "cancelled"


class MembershipStatus(str, Enum):
    PENDING = "pending"
    APPROVED = "approved"
    REJECTED = "rejected"
    LEFT = "left"


class TravelSpaceCreate(BaseModel):
    name: str = Field(..., min_length=3, max_length=100)
    description: Optional[str] = None
    destination: str
    start_date: date
    end_date: date
    image_url: Optional[str] = None
    tag: Optional[str] = None
    is_public: bool = True

    @field_validator('end_date')
    @classmethod
    def end_date_after_start_date(cls, v, info):
        if 'start_date' in info.data and v <= info.data['start_date']:
            raise ValueError('end_date must be after start_date')
        return v


class TravelSpaceResponse(BaseModel):
    id: str
    name: str
    description: Optional[str]
    destination: str
    creator_id: str
    creator_name: Optional[str] = None
    member_ids: List[str]
    member_count: int
    pending_member_ids: List[str]
    image_url: Optional[str]
    tag: Optional[str]
    shared_itinerary: Optional[Dict[str, Any]]
    created_at: datetime
    updated_at: datetime
    is_public: bool

    class Config:
        from_attributes = True


class TravelSpaceListItem(BaseModel):
    id: str
    name: str
    destination: str
    image_url: Optional[str]
    tag: Optional[str]
    member_count: int
    created_at: datetime


class JoinRequestResponse(BaseModel):
    success: bool
    message: str
    pending_members: List[str]