"""
MongoDB Configuration for SmartExplorers
"""
from motor.motor_asyncio import AsyncIOMotorClient
from pymongo import MongoClient
from typing import Optional
import os


class MongoDB:
    """MongoDB connection manager"""
    
    client: Optional[AsyncIOMotorClient] = None
    db = None
    
    # Database name
    DATABASE_NAME = "smartexplorers"
    
    # Collection names
    USERS = "users"
    TRAVELER_PROFILES = "traveler_profiles"
    SERVICE_PROVIDER_PROFILES = "service_provider_profiles"
    CONVERSATIONS = "conversations"
    USER_MEMORIES = "user_memories"
    SAFETY_PROFILES = "safety_profiles"
    EMERGENCY_CONTACTS = "emergency_contacts"
    PANIC_EVENTS = "panic_events"
    POSTS = "posts"
    STORIES = "stories"
    PHOTOS = "photos"
    REVIEWS = "reviews"
    SERVICE_LISTINGS = "service_listings"
    FAVORITES = "favorites"
    BOOKINGS = "bookings"
    USER_PREFERENCES = "user_preferences"
    ITINERARIES = "itineraries"
    PORTFOLIO_ITEMS = "portfolio_items"
    CREDENTIALS = "credentials"


# Global MongoDB instance
mongodb = MongoDB()


async def connect_to_mongo():
    """Connect to MongoDB"""
    # Get MongoDB URI from environment
    MONGO_URI = os.getenv("MONGODB_URI", "mongodb://localhost:27017")
    
    print(f"Connecting to MongoDB at {MONGO_URI}")
    
    # Create async client
    mongodb.client = AsyncIOMotorClient(MONGO_URI)
    mongodb.db = mongodb.client[mongodb.DATABASE_NAME]
    
    print(f"✓ Connected to MongoDB database: {mongodb.DATABASE_NAME}")
    
    # Create indexes
    await create_indexes()


async def close_mongo_connection():
    """Close MongoDB connection"""
    if mongodb.client:
        mongodb.client.close()
        print("✓ MongoDB connection closed")


async def create_indexes():
    """Create database indexes for better performance"""
    db = mongodb.db
    
    # Users indexes
    await db[mongodb.USERS].create_index("email", unique=True)
    await db[mongodb.USERS].create_index("username", unique=True)
    await db[mongodb.USERS].create_index("account_type")
    
    # Profiles indexes
    await db[mongodb.TRAVELER_PROFILES].create_index("user_id", unique=True)
    await db[mongodb.SERVICE_PROVIDER_PROFILES].create_index("user_id", unique=True)
    
    # Conversations indexes
    await db[mongodb.CONVERSATIONS].create_index("conversation_id", unique=True)
    await db[mongodb.CONVERSATIONS].create_index("user_id")
    await db[mongodb.CONVERSATIONS].create_index([("user_id", 1), ("is_active", 1)])
    
    # User memories index
    await db[mongodb.USER_MEMORIES].create_index("user_id", unique=True)
    
    # Safety indexes
    await db[mongodb.SAFETY_PROFILES].create_index("user_id", unique=True)
    await db[mongodb.EMERGENCY_CONTACTS].create_index("user_id")
    await db[mongodb.PANIC_EVENTS].create_index([("user_id", 1), ("timestamp", -1)])
    
    # Social indexes
    await db[mongodb.POSTS].create_index([("author_id", 1), ("created_at", -1)])
    await db[mongodb.POSTS].create_index("created_at")
    await db[mongodb.STORIES].create_index([("user_id", 1), ("expires_at", 1)])
    await db[mongodb.PHOTOS].create_index("user_id")
    await db[mongodb.REVIEWS].create_index([("author_id", 1), ("created_at", -1)])
    await db[mongodb.REVIEWS].create_index("provider_id")
    
    # Marketplace indexes
    await db[mongodb.SERVICE_LISTINGS].create_index([("category", 1), ("featured_flag", -1)])
    await db[mongodb.SERVICE_LISTINGS].create_index("provider_id")
    await db[mongodb.FAVORITES].create_index([("user_id", 1), ("listing_id", 1)], unique=True)
    await db[mongodb.BOOKINGS].create_index("user_id")
    await db[mongodb.BOOKINGS].create_index("provider_id")
    
    # Preferences index
    await db[mongodb.USER_PREFERENCES].create_index("user_id", unique=True)
    
    # Itineraries index
    await db[mongodb.ITINERARIES].create_index("user_id")
    
    # Portfolio & Credentials
    await db[mongodb.PORTFOLIO_ITEMS].create_index("provider_id")
    await db[mongodb.CREDENTIALS].create_index("provider_id")
    
    print("✓ MongoDB indexes created")


def get_database():
    """Get database instance (for dependency injection)"""
    return mongodb.db


# Synchronous client (for scripts/testing)
def get_sync_client():
    """Get synchronous MongoDB client"""
    MONGO_URI = os.getenv("MONGODB_URI", "mongodb://localhost:27017")
    return MongoClient(MONGO_URI)[mongodb.DATABASE_NAME]