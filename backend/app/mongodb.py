"""
MongoDB Configuration for SmartExplorers
Works with both SRV and standard connection strings
Windows-compatible with error handling
"""
from motor.motor_asyncio import AsyncIOMotorClient
from pymongo import MongoClient
from typing import Optional
from app.config import settings


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
    """
    Connect to MongoDB with error handling
    Works with both mongodb+srv:// and mongodb:// formats
    """
    MONGO_URI = settings.MONGODB_URI
    safe_uri = MONGO_URI
    if "@" in MONGO_URI and ":" in MONGO_URI:
        # Mask credentials in logs
        safe_uri = MONGO_URI.split("//")[0] + "//***:***@" + MONGO_URI.split("@")[-1]
    
    print(f"Connecting to MongoDB at {safe_uri}")
    
    try:
        # Create async client
        mongodb.client = AsyncIOMotorClient(
            MONGO_URI,
            serverSelectionTimeoutMS=30000  # 30 second timeout
        )
        mongodb.db = mongodb.client[mongodb.DATABASE_NAME]
        
        # Test the connection
        await mongodb.client.admin.command("ping")
        
        print(f"✓ Connected to MongoDB database: {mongodb.DATABASE_NAME}")
        
        # Create indexes
        await create_indexes()
        
    except Exception as e:
        error_msg = str(e)
        print("\n" + "="*60)
        print("❌ MongoDB Connection Failed")
        print("="*60)
        
        if "SSL" in error_msg or "TLS" in error_msg:
            print("\n🔍 SSL/TLS Error Detected")
            print("\nThis is a Windows compatibility issue with mongodb+srv://")
            print("\nFIX: Use standard connection string instead")
            print("  1. Run: python convert_connection_string.py")
            print("  2. Copy the output to your .env file")
            print("  3. Restart server")
            print("\nOR download MongoDB locally:")
            print("  https://www.mongodb.com/try/download/community")
        elif "Authentication" in error_msg:
            print("\n🔑 Authentication Error")
            print("  - Check username/password in .env")
            print("  - Verify database user permissions in Atlas")
        elif "timeout" in error_msg.lower() or "timed out" in error_msg.lower():
            print("\n⏱️  Connection Timeout")
            print("  1. Go to https://cloud.mongodb.com")
            print("  2. Network Access > Add IP Address")
            print("  3. Select 'Allow from Anywhere' (0.0.0.0/0)")
            print("  4. Wait 2 minutes, then restart")
        else:
            print(f"\n💡 Error: {error_msg}")
        
        print("\n✅ App will continue without MongoDB")
        print("   (API will work but data won't persist)")
        print("="*60 + "\n")
        
        mongodb.client = None
        mongodb.db = None


async def close_mongo_connection():
    """Close MongoDB connection"""
    if mongodb.client:
        mongodb.client.close()
        print("✓ MongoDB connection closed")


async def create_indexes():
    """Create database indexes for better performance"""
    if mongodb.db is None:
        print("⚠️  Skipping index creation (MongoDB not connected)")
        return
    
    try:
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
        
    except Exception as e:
        print(f"⚠️  Index creation warning: {e}")


def get_database():
    """Get database instance (for dependency injection)"""
    return mongodb.db


def get_sync_client():
    """
    Get synchronous MongoDB client (for scripts/testing)
    With error handling
    """
    MONGO_URI = settings.MONGODB_URI
    
    try:
        return MongoClient(
            MONGO_URI,
            serverSelectionTimeoutMS=30000
        )[mongodb.DATABASE_NAME]
    except Exception as e:
        error_msg = str(e)
        
        if "SSL" in error_msg or "TLS" in error_msg:
            print("\n⚠️  SSL Error in sync client")
            print("   Run: python convert_connection_string.py")
            print("   to fix the connection string\n")
        
        raise e