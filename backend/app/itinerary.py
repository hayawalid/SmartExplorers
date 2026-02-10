from pydantic import BaseModel, Field, validator
from typing import List, Optional, Dict, Any
from datetime import datetime, date
from enum import Enum


class TripType(str, Enum):
    CULTURAL = "cultural"
    ADVENTURE = "adventure"
    RELAXATION = "relaxation"
    RELIGIOUS = "religious"
    FAMILY = "family"
    PHOTOGRAPHY = "photography"


class SafetyLevel(str, Enum):
    HIGH = "high"
    MEDIUM = "medium"
    LOW = "low"


class ItineraryStatus(str, Enum):
    DRAFT = "draft"
    PENDING_APPROVAL = "pending_approval"
    APPROVED = "approved"
    REJECTED = "rejected"
    ACTIVE = "active"
    COMPLETED = "completed"


class AccessibilityRequirement(BaseModel):
    wheelchair_accessible: bool = False
    visual_impairment_support: bool = False
    hearing_impairment_support: bool = False
    mobility_assistance: bool = False
    other: Optional[str] = None


class ItineraryGenerationRequest(BaseModel):
    trip_type: TripType
    start_date: date
    end_date: date
    start_location: str = Field(..., description="Starting point in Egypt (e.g., 'Cairo Airport')")
    destinations: List[str] = Field(..., min_items=1, description="List of cities/places to visit")
    
    # Preferences
    budget_min: Optional[float] = Field(None, ge=0)
    budget_max: Optional[float] = Field(None, ge=0)
    accessibility_requirements: Optional[AccessibilityRequirement] = None
    dietary_restrictions: List[str] = Field(default_factory=list)
    interests: List[str] = Field(default_factory=list)
    
    # Traveler info
    is_solo_traveler: bool = False
    is_woman_traveler: bool = False
    group_size: int = Field(1, ge=1, le=20)
    
    @validator('end_date')
    def end_date_must_be_after_start_date(cls, v, values):
        if 'start_date' in values and v <= values['start_date']:
            raise ValueError('end_date must be after start_date')
        return v


class ActivityCreate(BaseModel):
    day_number: int = Field(..., ge=1)
    order_in_day: int = Field(..., ge=1)
    title: str
    description: Optional[str] = None
    location_name: str
    latitude: Optional[float] = Field(None, ge=-90, le=90)
    longitude: Optional[float] = Field(None, ge=-180, le=180)
    start_time: Optional[str] = Field(None, regex=r'^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$')
    end_time: Optional[str] = None
    duration_minutes: Optional[int] = Field(None, ge=0)
    estimated_cost_min: Optional[float] = Field(None, ge=0)
    estimated_cost_max: Optional[float] = Field(None, ge=0)
    accessibility_friendly: bool = True
    wheelchair_accessible: bool = False
    safety_level: SafetyLevel = SafetyLevel.MEDIUM
    category: Optional[str] = None
    tags: List[str] = Field(default_factory=list)


class ActivityResponse(ActivityCreate):
    id: int
    itinerary_id: int
    safety_warnings: Optional[List[str]] = None
    recommended_for_solo: bool = True
    recommended_for_women: bool = True
    booking_required: bool = False
    booking_url: Optional[str] = None
    created_at: datetime

    class Config:
        from_attributes = True


class DailyPlan(BaseModel):
    day: int
    date: date
    title: str
    activities: List[ActivityResponse]
    total_cost_min: float = 0
    total_cost_max: float = 0
    safety_notes: List[str] = Field(default_factory=list)


class ItineraryResponse(BaseModel):
    id: int
    user_id: int
    title: str
    description: Optional[str] = None
    trip_type: TripType
    start_date: datetime
    end_date: datetime
    total_days: int
    start_location: str
    destinations: List[str]
    budget_min: Optional[float] = None
    budget_max: Optional[float] = None
    status: ItineraryStatus
    safety_level: Optional[SafetyLevel] = None
    safety_score: Optional[float] = None
    safety_notes: Optional[List[str]] = None
    ai_recommendations: Optional[Dict[str, Any]] = None
    daily_plans: Optional[List[Dict[str, Any]]] = None
    created_at: datetime
    updated_at: datetime
    approved_at: Optional[datetime] = None

    class Config:
        from_attributes = True


class ItineraryApprovalRequest(BaseModel):
    approved: bool
    feedback: Optional[str] = None


class SafetyValidationResponse(BaseModel):
    is_safe: bool
    safety_level: SafetyLevel
    safety_score: float
    warnings: List[str] = Field(default_factory=list)
    recommendations: List[str] = Field(default_factory=list)