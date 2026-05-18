"""
MongoDB Models using Pydantic
These are document schemas for MongoDB collections
"""
from pydantic import BaseModel, EmailStr, Field
from pydantic_core import core_schema
from typing import Optional, List, Dict, Any, Annotated
from datetime import datetime
from enum import Enum
from bson import ObjectId


# ==================== Custom Types ====================

class PyObjectId(ObjectId):
    """Custom ObjectId type for Pydantic v2"""
    @classmethod
    def __get_pydantic_core_schema__(cls, source_type: Any, handler: Any) -> core_schema.CoreSchema:
        return core_schema.no_info_after_validator_function(
            cls.validate,
            core_schema.union_schema([
                core_schema.is_instance_schema(ObjectId),
                core_schema.chain_schema([
                    core_schema.str_schema(),
                    core_schema.no_info_plain_validator_function(cls.validate),
                ]),
            ]),
        )

    @classmethod
    def validate(cls, v):
        if isinstance(v, ObjectId):
            return v
        if isinstance(v, str):
            if ObjectId.is_valid(v):
                return ObjectId(v)
        raise ValueError(f"Invalid ObjectId: {v}")


# ==================== Enums ====================

class AccountType(str, Enum):
    TRAVELER = "traveler"
    SERVICE_PROVIDER = "service_provider"


class Gender(str, Enum):
    MALE = "male"
    FEMALE = "female"
    OTHER = "other"
    PREFER_NOT_TO_SAY = "prefer_not_to_say"


class ServiceType(str, Enum):
    TOUR_GUIDE = "tour_guide"
    DRIVER = "driver"
    PHOTOGRAPHER = "photographer"
    INTERPRETER = "interpreter"
    LOCAL_EXPERT = "local_expert"


class VerificationStatus(str, Enum):
    PENDING = "pending"
    ID_CAPTURED = "id_captured"
    SELFIE_CAPTURED = "selfie_captured"
    VERIFIED = "verified"
    REJECTED = "rejected"


# ==================== User ====================

class UserModel(BaseModel):
    """
    User document - Main user collection
    From: account_type_screen.dart, sign in/sign up
    """
    id: Optional[PyObjectId] = Field(alias="_id", default=None)
    
    # Account Type
    account_type: AccountType
    
    # Authentication
    email: EmailStr
    username: str
    hashed_password: str
    phone_number: Optional[str] = None
    
    # Basic Info
    full_name: str
    profile_picture_url: Optional[str] = None
    avatar_url: Optional[str] = None
    bio: Optional[str] = None
    
    # Verification
    email_verified: bool = False
    phone_verified: bool = False
    identity_verified: bool = False
    verified_flag: bool = False
    verification_date: Optional[datetime] = None
    
    # Stats
    rating: float = 0.0
    review_count: int = 0
    member_since: datetime = Field(default_factory=datetime.now)
    
    # Account Status
    is_active: bool = True
    is_banned: bool = False
    ban_reason: Optional[str] = None
    
    # Timestamps
    created_at: datetime = Field(default_factory=datetime.now)
    updated_at: Optional[datetime] = None
    last_login: Optional[datetime] = None
    
    class Config:
        populate_by_name = True
        json_encoders = {ObjectId: str}
        json_schema_extra = {
            "example": {
                "account_type": "traveler",
                "email": "sarah@example.com",
                "username": "sarah_traveler",
                "full_name": "Sarah Johnson",
                "email_verified": True
            }
        }


# ==================== Traveler Profile ====================

class TravelerProfileModel(BaseModel):
    """
    Traveler profile document
    From: traveler_profile_setup_screen.dart
    """
    id: Optional[PyObjectId] = Field(alias="_id", default=None)
    user_id: str  # Reference to User._id
    
    # From traveler_profile_setup_screen.dart
    date_of_birth: Optional[datetime] = None
    country_of_origin: Optional[str] = None
    preferred_language: Optional[str] = None
    
    # Accessibility Needs (Boolean flags)
    wheelchair_access: bool = False
    visual_assistance: bool = False
    hearing_assistance: bool = False
    mobility_support: bool = False
    dietary_restrictions_flag: bool = False
    sensory_sensitivity: bool = False
    
    # Travel Interests (Array)
    travel_interests: List[str] = []
    # ["Ancient History", "Photography", "Adventure", "Food & Cuisine", ...]
    
    # From interactive_setup_screen.dart
    setup_interests: List[str] = []
    # ["History/Archaeology", "Adventure", "Culture & Arts", ...]
    
    # Additional
    nationality: Optional[str] = None
    languages_spoken: List[str] = []
    
    # Travel Preferences
    is_solo_traveler: bool = False
    first_time_egypt: bool = True
    traveling_alone: bool = False
    
    # Budget
    typical_budget_min: Optional[float] = None
    typical_budget_max: Optional[float] = None
    
    # Stats
    trips_count: int = 0
    reviews_count: int = 0
    photos_count: int = 0
    
    # Emergency Contact
    emergency_contact_name: Optional[str] = None
    emergency_contact_phone: Optional[str] = None
    emergency_contact_relationship: Optional[str] = None
    
    # Timestamps
    created_at: datetime = Field(default_factory=datetime.now)
    updated_at: Optional[datetime] = None
    
    class Config:
        populate_by_name = True
        json_encoders = {ObjectId: str}


# ==================== Service Provider Profile ====================

class ServiceProviderProfileModel(BaseModel):
    """
    Service provider profile document
    From: provider_profile_setup_screen.dart
    """
    id: Optional[PyObjectId] = Field(alias="_id", default=None)
    user_id: str  # Reference to User._id
    
    # Basic Info
    full_legal_name: str
    phone_number: Optional[str] = None
    bio: Optional[str] = None
    
    # Service Type
    service_type: ServiceType
    
    # Identity Verification
    verification_status: VerificationStatus = VerificationStatus.PENDING
    id_scan_url: Optional[str] = None
    selfie_url: Optional[str] = None
    id_scan_timestamp: Optional[datetime] = None
    selfie_timestamp: Optional[datetime] = None
    
    # Business Info
    business_name: Optional[str] = None
    business_license_number: Optional[str] = None
    
    # Location
    address: Optional[str] = None
    city: Optional[str] = None
    governorate: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    
    # Services
    services_offered: List[str] = []
    active_services: List[str] = []  # List of active service IDs from services collection
    services_count: int = 0  # Number of active services
    languages: List[str] = []
    
    # Pricing
    price_range_min: Optional[float] = None
    price_range_max: Optional[float] = None
    
    # Stats
    rating: float = 0.0
    review_count: int = 0
    completed_tours_count: int = 0
    
    # Verification
    verified_flag: bool = False
    safety_certified: bool = False
    
    # Contact
    business_phone: Optional[str] = None
    business_email: Optional[EmailStr] = None
    website: Optional[str] = None
    
    # Timestamps
    created_at: datetime = Field(default_factory=datetime.now)
    updated_at: Optional[datetime] = None
    
    class Config:
        populate_by_name = True
        json_encoders = {ObjectId: str}


# ==================== Service Offering ====================

class ServiceAvailabilityModel(BaseModel):
    """Service availability details"""
    days: List[str] = []  # ["Monday", "Tuesday", "Wednesday"]
    hours_start: Optional[str] = None  # "09:00"
    hours_end: Optional[str] = None  # "17:00"


class ServiceModel(BaseModel):
    """
    Service offering document
    Created dynamically by service providers
    """
    id: Optional[PyObjectId] = Field(alias="_id", default=None)
    
    # Reference
    provider_id: str  # Reference to User._id (service provider)
    
    # Service Details
    service_type: ServiceType  # tour_guide, driver, photographer, etc.
    service_name: str  # "Guided Nile Cruise", "Airport Transfer", etc.
    description: Optional[str] = None
    
    # Tags for discovery
    tags: List[str] = []  # ["history", "photography", "adventure"]
    cluster_keywords: List[str] = []  # Keywords for matching with traveler interests
    
    # Pricing
    price_min: Optional[float] = None
    price_max: Optional[float] = None
    currency: str = "EGP"
    
    # Availability
    availability: ServiceAvailabilityModel = Field(default_factory=ServiceAvailabilityModel)
    
    # Stats
    rating: float = 0.0
    reviews_count: int = 0
    bookings_count: int = 0
    
    # Status
    is_active: bool = True
    
    # Timestamps
    created_at: datetime = Field(default_factory=datetime.now)
    updated_at: Optional[datetime] = None
    
    class Config:
        populate_by_name = True
        json_encoders = {ObjectId: str}
        json_schema_extra = {
            "example": {
                "provider_id": "507f1f77bcf86cd799439011",
                "service_type": "tour_guide",
                "service_name": "Guided Nile Cruise",
                "description": "Scenic evening cruise on the Nile",
                "tags": ["history", "sightseeing", "photography"],
                "cluster_keywords": ["ancient_history", "photography", "culture"],
                "price_min": 50.0,
                "price_max": 150.0,
                "availability": {
                    "days": ["Monday", "Wednesday", "Friday"],
                    "hours_start": "18:00",
                    "hours_end": "22:00"
                }
            }
        }


# ==================== Conversation (Short-Term Memory) ====================

class ConversationModel(BaseModel):
    """
    Conversation document - Short-term memory
    From: ai_assistant_screen.dart, chat_models.dart
    """
    id: Optional[PyObjectId] = Field(alias="_id", default=None)
    conversation_id: str  # Unique conversation ID
    user_id: Optional[str] = None  # Reference to User._id
    
    # Conversation Info
    title: Optional[str] = None
    summary: Optional[str] = None
    
    # Messages array
    messages: List[Dict[str, Any]] = []
    # [{"role": "user", "content": "...", "timestamp": "..."}]
    
    # AI Suggestions
    last_suggestions: List[str] = []
    
    # User Context
    user_context: Optional[Dict[str, Any]] = None
    # {"first_time_egypt": true, "traveling_alone": true}
    
    # Stats
    message_count: int = 0
    last_message_at: Optional[datetime] = None
    
    # Status
    is_active: bool = True
    is_archived: bool = False
    
    # Timestamps
    created_at: datetime = Field(default_factory=datetime.now)
    updated_at: Optional[datetime] = None
    
    class Config:
        populate_by_name = True
        json_encoders = {ObjectId: str}


# ==================== User Memory (Long-Term Memory) ====================

class UserMemoryModel(BaseModel):
    """
    User memory document - Long-term memory
    AI learns and remembers user preferences
    """
    id: Optional[PyObjectId] = Field(alias="_id", default=None)
    user_id: str  # Reference to User._id
    
    # Learned from conversations
    learned_interests: List[str] = []
    learned_concerns: List[str] = []
    favorite_destinations: List[str] = []
    recent_topics: List[str] = []
    common_questions: List[str] = []
    
    # AI Personalization
    tone_preference: str = "friendly"  # "formal", "casual", "friendly"
    detail_level: str = "medium"  # "brief", "medium", "detailed"
    
    # User Context Flags
    first_time_egypt: bool = True
    traveling_alone: bool = False
    
    # Important Facts
    key_facts: Dict[str, Any] = {}
    # {"allergies": [...], "medical": [...]}
    
    # Stats
    total_conversations: int = 0
    total_messages: int = 0
    memory_last_updated: datetime = Field(default_factory=datetime.now)
    
    # Timestamps
    created_at: datetime = Field(default_factory=datetime.now)
    updated_at: Optional[datetime] = None
    
    class Config:
        populate_by_name = True
        json_encoders = {ObjectId: str}


# ==================== Safety ====================

class SafetyProfileModel(BaseModel):
    """Safety profile from safety_dashboard_screen.dart"""
    id: Optional[PyObjectId] = Field(alias="_id", default=None)
    user_id: str
    
    live_tracking_enabled: bool = False
    last_known_latitude: Optional[float] = None
    last_known_longitude: Optional[float] = None
    last_location_update: Optional[datetime] = None
    location_sharing_enabled: bool = False
    shared_with_contacts: List[str] = []
    
    created_at: datetime = Field(default_factory=datetime.now)
    updated_at: Optional[datetime] = None
    
    class Config:
        populate_by_name = True
        json_encoders = {ObjectId: str}


class EmergencyContactModel(BaseModel):
    """Emergency contact from safety_dashboard_screen.dart"""
    id: Optional[PyObjectId] = Field(alias="_id", default=None)
    user_id: str
    
    name: str
    relationship: str
    phone: str
    priority: int = 1
    
    created_at: datetime = Field(default_factory=datetime.now)
    
    class Config:
        populate_by_name = True
        json_encoders = {ObjectId: str}


class PanicEventModel(BaseModel):
    """Panic/SOS event from safety_dashboard_screen.dart"""
    id: Optional[PyObjectId] = Field(alias="_id", default=None)
    user_id: str
    
    timestamp: datetime = Field(default_factory=datetime.now)
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    status: str = "sent"  # "sent", "confirmed", "resolved"
    responded_at: Optional[datetime] = None
    responder_notes: Optional[str] = None
    
    class Config:
        populate_by_name = True
        json_encoders = {ObjectId: str}


# ==================== Social ====================

class PostModel(BaseModel):
    """Post from feed_screen.dart"""
    id: Optional[PyObjectId] = Field(alias="_id", default=None)
    author_id: str
    
    caption: Optional[str] = None
    location: Optional[str] = None
    media_type: str = "image"
    media_url: Optional[str] = None
    alt_text: Optional[str] = None
    
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    
    like_count: int = 0
    comment_count: int = 0
    share_count: int = 0
    view_count: int = 0
    
    is_promoted: bool = False
    is_public: bool = True
    is_flagged: bool = False
    
    time: datetime = Field(default_factory=datetime.now)
    created_at: datetime = Field(default_factory=datetime.now)
    
    class Config:
        populate_by_name = True
        json_encoders = {ObjectId: str}


# Continue with remaining models...
# (Story, Photo, Review, ServiceListing, Favorite, Booking, UserPreferences, Itinerary, etc.)