from sqlalchemy import Column, Integer, String, Float, DateTime, Boolean, JSON, Enum as SQLEnum, ForeignKey, Text
from sqlalchemy.orm import relationship
from datetime import datetime
import enum

from database import Base


class TravelSpaceStatus(str, enum.Enum):
    FORMING = "forming"  # Accepting applications
    ACTIVE = "active"    # Trip in progress
    COMPLETED = "completed"
    CANCELLED = "cancelled"


class MembershipStatus(str, enum.Enum):
    PENDING = "pending"      # Applied, waiting for votes
    APPROVED = "approved"    # Accepted by majority vote
    REJECTED = "rejected"    # Rejected by votes
    ACTIVE = "active"        # Confirmed and paid
    LEFT = "left"           # Member left the group


class VoteType(str, enum.Enum):
    APPROVE = "approve"
    REJECT = "reject"
    ABSTAIN = "abstain"


class TravelSpace(Base):
    """Democratic group travel space"""
    __tablename__ = "travel_spaces"

    id = Column(Integer, primary_key=True, index=True)
    
    # Basic info
    name = Column(String(255), nullable=False)
    description = Column(Text, nullable=True)
    destination = Column(String(255), nullable=False)
    
    # Trip details
    start_date = Column(DateTime, nullable=False)
    end_date = Column(DateTime, nullable=False)
    itinerary_id = Column(Integer, ForeignKey("itineraries.id"), nullable=True)
    
    # Group configuration
    min_members = Column(Integer, default=2, nullable=False)
    max_members = Column(Integer, default=10, nullable=False)
    current_members = Column(Integer, default=1, nullable=False)  # Creator counts
    
    # Safety & governance
    voting_threshold = Column(Float, default=0.6, nullable=False)  # 60% to approve
    require_verification = Column(Boolean, default=True, nullable=False)
    women_only = Column(Boolean, default=False, nullable=False)
    
    # Requirements
    min_age = Column(Integer, default=18, nullable=False)
    max_age = Column(Integer, nullable=True)
    languages = Column(JSON, nullable=True)  # ["English", "Arabic"]
    interests = Column(JSON, nullable=True)
    
    # Status
    status = Column(SQLEnum(TravelSpaceStatus), default=TravelSpaceStatus.FORMING, nullable=False)
    is_public = Column(Boolean, default=True, nullable=False)
    
    # Creator
    creator_id = Column(Integer, index=True, nullable=False)  # FK to users later
    
    # Timestamps
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)
    activated_at = Column(DateTime, nullable=True)
    
    # Relationships
    memberships = relationship("TravelSpaceMembership", back_populates="space", cascade="all, delete-orphan")
    votes = relationship("MembershipVote", back_populates="space", cascade="all, delete-orphan")


class TravelSpaceMembership(Base):
    """Membership in a travel space"""
    __tablename__ = "travel_space_memberships"

    id = Column(Integer, primary_key=True, index=True)
    
    space_id = Column(Integer, ForeignKey("travel_spaces.id"), nullable=False)
    user_id = Column(Integer, index=True, nullable=False)
    
    # Application
    application_message = Column(Text, nullable=True)
    compatibility_score = Column(Float, nullable=True)  # AI-calculated
    
    # Status
    status = Column(SQLEnum(MembershipStatus), default=MembershipStatus.PENDING, nullable=False)
    
    # Voting results
    votes_for = Column(Integer, default=0, nullable=False)
    votes_against = Column(Integer, default=0, nullable=False)
    votes_needed = Column(Integer, nullable=True)
    
    # Role in group
    is_creator = Column(Boolean, default=False, nullable=False)
    role = Column(String(50), default="member", nullable=False)  # member, admin
    
    # Timestamps
    applied_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    decided_at = Column(DateTime, nullable=True)
    joined_at = Column(DateTime, nullable=True)
    
    # Relationships
    space = relationship("TravelSpace", back_populates="memberships")
    votes_received = relationship("MembershipVote", back_populates="membership", cascade="all, delete-orphan")


class MembershipVote(Base):
    """Vote on a membership application"""
    __tablename__ = "membership_votes"

    id = Column(Integer, primary_key=True, index=True)
    
    space_id = Column(Integer, ForeignKey("travel_spaces.id"), nullable=False)
    membership_id = Column(Integer, ForeignKey("travel_space_memberships.id"), nullable=False)
    voter_id = Column(Integer, index=True, nullable=False)
    
    vote = Column(SQLEnum(VoteType), nullable=False)
    reason = Column(Text, nullable=True)
    
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    
    # Relationships
    space = relationship("TravelSpace", back_populates="votes")
    membership = relationship("TravelSpaceMembership", back_populates="votes_received")