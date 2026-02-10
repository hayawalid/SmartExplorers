from sqlalchemy import Column, Integer, String, Float, DateTime, Boolean, JSON, Enum as SQLEnum, ForeignKey, Text
from sqlalchemy.orm import relationship
from datetime import datetime
import enum

from ..database import Base


class TripType(str, enum.Enum):
    CULTURAL = "cultural"
    ADVENTURE = "adventure"
    RELAXATION = "relaxation"
    RELIGIOUS = "religious"
    FAMILY = "family"
    PHOTOGRAPHY = "photography"


class SafetyLevel(str, enum.Enum):
    HIGH = "high"
    MEDIUM = "medium"
    LOW = "low"


class ItineraryStatus(str, enum.Enum):
    DRAFT = "draft"
    PENDING_APPROVAL = "pending_approval"
    APPROVED = "approved"
    REJECTED = "rejected"
    ACTIVE = "active"
    COMPLETED = "completed"


class Itinerary(Base):
    __tablename__ = "itineraries"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, index=True)  # Will be FK to users table later
    
    # Basic info
    title = Column(String(255), nullable=False)
    description = Column(Text, nullable=True)
    trip_type = Column(SQLEnum(TripType), nullable=False)
    
    # Dates
    start_date = Column(DateTime, nullable=False)
    end_date = Column(DateTime, nullable=False)
    total_days = Column(Integer, nullable=False)
    
    # Location
    start_location = Column(String(255), nullable=False)
    destinations = Column(JSON, nullable=False)  # List of cities
    
    # Budget
    budget_min = Column(Float, nullable=True)
    budget_max = Column(Float, nullable=True)
    
    # Requirements & preferences
    accessibility_requirements = Column(JSON, nullable=True)
    dietary_restrictions = Column(JSON, nullable=True)
    interests = Column(JSON, nullable=True)
    
    # Status
    status = Column(SQLEnum(ItineraryStatus), default=ItineraryStatus.PENDING_APPROVAL, nullable=False)
    
    # Safety
    safety_level = Column(SQLEnum(SafetyLevel), nullable=True)
    safety_score = Column(Float, nullable=True)
    safety_notes = Column(JSON, nullable=True)
    
    # AI recommendations
    ai_recommendations = Column(JSON, nullable=True)
    daily_plans = Column(JSON, nullable=True)
    
    # Timestamps
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)
    approved_at = Column(DateTime, nullable=True)
    
    # Relationships
    activities = relationship("ItineraryActivity", back_populates="itinerary", cascade="all, delete-orphan")


class ItineraryActivity(Base):
    __tablename__ = "itinerary_activities"

    id = Column(Integer, primary_key=True, index=True)
    itinerary_id = Column(Integer, ForeignKey("itineraries.id"), nullable=False)
    
    # Day and order
    day_number = Column(Integer, nullable=False)
    order_in_day = Column(Integer, nullable=False)
    
    # Activity details
    title = Column(String(255), nullable=False)
    description = Column(Text, nullable=True)
    location_name = Column(String(255), nullable=False)
    latitude = Column(Float, nullable=True)
    longitude = Column(Float, nullable=True)
    
    # Timing
    start_time = Column(String(5), nullable=True)  # HH:MM format
    end_time = Column(String(5), nullable=True)
    duration_minutes = Column(Integer, nullable=True)
    
    # Cost
    estimated_cost_min = Column(Float, nullable=True)
    estimated_cost_max = Column(Float, nullable=True)
    
    # Accessibility
    accessibility_friendly = Column(Boolean, default=True)
    wheelchair_accessible = Column(Boolean, default=False)
    
    # Safety
    safety_level = Column(SQLEnum(SafetyLevel), default=SafetyLevel.MEDIUM)
    safety_warnings = Column(JSON, nullable=True)
    recommended_for_solo = Column(Boolean, default=True)
    recommended_for_women = Column(Boolean, default=True)
    
    # Categorization
    category = Column(String(50), nullable=True)
    tags = Column(JSON, nullable=True)
    
    # Booking
    booking_required = Column(Boolean, default=False)
    booking_url = Column(String(500), nullable=True)
    
    # Timestamp
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    
    # Relationships
    itinerary = relationship("Itinerary", back_populates="activities")