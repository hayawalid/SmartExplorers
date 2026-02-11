from sqlalchemy import Boolean, Column, Integer, String, Float, JSON, DateTime
from sqlalchemy.sql import func
from app.database import Base

class User(Base):
    """User model with matching preferences"""
    __tablename__ = "users"
    
    id = Column(Integer, primary_key=True, index=True)
    email = Column(String(255), unique=True, index=True, nullable=False)
    
    # Profile
    age = Column(Integer)
    gender = Column(String(20))
    languages = Column(JSON)  # ["English", "Arabic"]
    interests = Column(JSON)  # ["history", "photography"]
    
    # Matching preferences
    travel_style = Column(String(50))
    travel_pace = Column(String(20))
    preferred_destinations = Column(JSON)
    budget_min = Column(Float)
    budget_max = Column(Float)
    accessibility_needs = Column(JSON)
    
    # Safety
    verified = Column(Boolean, default=False)
    safety_score = Column(Float, default=0.5)
    
    # Matching metadata
    interest_embedding = Column(JSON)  # Cached embedding
    last_match_update = Column(DateTime(timezone=True), server_default=func.now())
    
    # Timestamps
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())