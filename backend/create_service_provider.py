"""
Script to inject a service provider into MongoDB for testing/demo purposes
Usage: python create_service_provider.py
"""

import os
import sys
from datetime import datetime
from dotenv import load_dotenv
import bcrypt
from pymongo import MongoClient
from bson import ObjectId

# Load environment variables
load_dotenv()

MONGODB_URI = os.getenv("MONGODB_URI", "mongodb+srv://***:***@smarexplorers.v9hduix.mongodb.net/?appName=SmarExplorers")
DATABASE_NAME = os.getenv("MONGODB_DB_NAME", "smartexplorers")


def hash_password(password: str) -> str:
    """Hash a password using bcrypt"""
    return bcrypt.hashpw(password.encode("utf-8"), bcrypt.gensalt()).decode("utf-8")


def create_service_provider():
    """Create a service provider in MongoDB"""

    # Connection details
    print("🔗 Connecting to MongoDB...")
    try:
        client = MongoClient(MONGODB_URI, serverSelectionTimeoutMS=5000)
        db = client[DATABASE_NAME]
        users_collection = db["users"]
        print("✅ Connected to MongoDB successfully")
    except Exception as e:
        print(f"❌ Failed to connect to MongoDB: {e}")
        return False

    # Service provider details
    email = "provider@smartexplorers.com"
    username = "tour_guide_demo"
    password = "Provider123!"
    full_name = "Ahmed Hassan"
    service_type = "tour_guide"

    # Check if user already exists
    existing = users_collection.find_one({"email": email})
    if existing:
        print(f"⚠️  User with email '{email}' already exists")
        return False

    # Create service provider document
    service_provider = {
        "_id": ObjectId(),
        "account_type": "service_provider",
        "email": email,
        "username": username,
        "hashed_password": hash_password(password),
        "phone_number": "+966501234567",
        "full_name": full_name,
        "profile_picture_url": None,
        "avatar_url": None,
        "bio": "Experienced tour guide in Saudi Arabia with 10+ years of experience",
        "email_verified": True,
        "phone_verified": True,
        "identity_verified": True,
        "verified_flag": True,
        "verification_date": datetime.utcnow(),
        "rating": 4.8,
        "review_count": 125,
        "member_since": datetime.utcnow(),
        "is_active": True,
        "is_banned": False,
        "ban_reason": None,
        "service_type": service_type,
        "location": {
            "city": "Riyadh",
            "country": "Saudi Arabia",
            "latitude": 24.7136,
            "longitude": 46.6753
        },
        "languages": ["Arabic", "English", "French"],
        "certifications": [
            "Guide License",
            "First Aid Certified",
            "Cultural Heritage Expert"
        ],
        "availability": {
            "monday": {"start": "09:00", "end": "18:00"},
            "tuesday": {"start": "09:00", "end": "18:00"},
            "wednesday": {"start": "09:00", "end": "18:00"},
            "thursday": {"start": "09:00", "end": "18:00"},
            "friday": {"start": "14:00", "end": "22:00"},
            "saturday": {"start": "09:00", "end": "18:00"},
            "sunday": {"start": "09:00", "end": "18:00"}
        },
        "price_per_hour": 150,
        "created_at": datetime.utcnow(),
        "updated_at": datetime.utcnow()
    }

    # Insert into database
    try:
        result = users_collection.insert_one(service_provider)
        print("✅ Service Provider Created Successfully!")
        print(f"\n📋 Login Details:")
        print(f"   Email: {email}")
        print(f"   Password: {password}")
        print(f"   Username: {username}")
        print(f"   Account Type: service_provider")
        print(f"   Service Type: {service_type}")
        print(f"   Name: {full_name}")
        print(f"\n🆔 MongoDB ID: {result.inserted_id}")
        return True
    except Exception as e:
        print(f"❌ Failed to create service provider: {e}")
        return False
    finally:
        client.close()


if __name__ == "__main__":
    print("=" * 60)
    print("  SmartExplorers - Service Provider Injection Script")
    print("=" * 60)
    print()

    success = create_service_provider()
    sys.exit(0 if success else 1)
