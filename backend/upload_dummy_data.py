import asyncio
import os
from datetime import datetime, timedelta
from motor.motor_asyncio import AsyncIOMotorClient
from passlib.context import CryptContext  # Ensure this is installed
from bson import ObjectId
import random
# Password hashing
# Change "hash_bcrypt" to "bcrypt"
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
# MongoDB connection
MONGODB_URI = "mongodb+srv://hayaadawy66_db_user:IrclengEMDTg443m@smartexplorers.5dz2fei.mongodb.net/"
DATABASE_NAME = "smartexplorers"

def hash_password(password: str) -> str:
    return pwd_context.hash(password)

def random_date(start_days_ago: int, end_days_ago: int = 0) -> datetime:
    start = datetime.now() - timedelta(days=start_days_ago)
    end = datetime.now() - timedelta(days=end_days_ago)
    delta = end - start
    random_seconds = random.randint(0, int(delta.total_seconds()))
    return start + timedelta(seconds=random_seconds)

# ==================== Updated Dummy Data (Local Paths) ====================

# Make sure these filenames match exactly what is in your static/avatars/ folder
DUMMY_USERS = [
    {
        "email": "sarah.johnson@email.com",
        "username": "sarah_explorer",
        "full_name": "Sarah Johnson",
        "avatar_url": "/static/avatars/sarah.jpg",
        "account_type": "traveler",
        "password": "Password123!"
    },
    {
        "email": "ahmed.hassan@email.com",
        "username": "ahmed_adventurer",
        "full_name": "Ahmed Hassan",
        "avatar_url": "/static/avatars/ahmed.jpg",
        "account_type": "traveler",
        "password": "Password123!"
    },
    {
        "email": "maria.garcia@email.com",
        "username": "maria_wanderer",
        "full_name": "Maria Garcia",
        "avatar_url": "/static/avatars/maria.jpg",
        "account_type": "traveler",
        "password": "Password123!"
    },
    {
        "email": "yuki.tanaka@email.com",
        "username": "yuki_traveler",
        "full_name": "Yuki Tanaka",
        "avatar_url": "/static/avatars/yuki.jpg",
        "account_type": "traveler",
        "password": "Password123!"
    },
    {
        "email": "david.oconnor@email.com",
        "username": "david_wheelchair",
        "full_name": "David O'Connor",
        "avatar_url": "/static/avatars/david.jpg",
        "account_type": "traveler",
        "password": "Password123!"
    },
    {
        "email": "fatima.ali@email.com",
        "username": "fatima_explorer",
        "full_name": "Fatima Ali",
        "avatar_url": "/static/avatars/fatima.jpg",
        "account_type": "traveler",
        "password": "Password123!"
    },
    {
        "email": "lars.nielsen@email.com",
        "username": "lars_backpacker",
        "full_name": "Lars Nielsen",
        "avatar_url": "/static/avatars/lars.jpg",
        "account_type": "traveler",
        "password": "Password123!"
    },
    {
        "email": "mohamed.guide@egypttours.com",
        "username": "mohamed_guide",
        "full_name": "Mohamed Ibrahim",
        "avatar_url": "/static/avatars/mohamed.jpg",
        "account_type": "service_provider",
        "password": "Password123!"
    }
]

# Make sure these filenames match exactly what is in your static/posts/ folder
SAMPLE_POSTS = [
    {
        "author_email": "sarah.johnson@email.com",
        "caption": "Finally here! The Pyramids of Giza are breathtaking. 🇪🇬✨",
        "location": "Giza",
        "images": [
            "/static/posts/pyramids_1.jpg"
            
        ]
    },
    {
        "author_email": "yuki.tanaka@email.com",
        "caption": "Golden hour at the Nile. 📸🌅",
        "location": "Nile River",
        "images": [
            "/static/posts/nile_1.jpg"
            
        ]
    }
]

async def upload_dummy_data():
    print("Connecting to MongoDB...")
    client = AsyncIOMotorClient(MONGODB_URI)
    db = client[DATABASE_NAME]
    
    # --- STEP 1: Update Users ---
    print("Updating user profiles with local paths...")
    for user_data in DUMMY_USERS:
        update_doc = {
            "$set": {
                "username": user_data["username"],
                "full_name": user_data["full_name"],
                "avatar_url": user_data["avatar_url"],
                "is_active": True,
                "updated_at": datetime.now()
            },
            "$setOnInsert": {
                "account_type": user_data["account_type"],
                "hashed_password": hash_password(user_data["password"]),
                "created_at": datetime.now()
            }
        }
        await db.users.update_one({"email": user_data["email"]}, update_doc, upsert=True)
        print(f"  ✓ Updated {user_data['username']}")

    # --- STEP 2: Update Posts ---
    print("\nUpdating posts with local image arrays...")
    for post_data in SAMPLE_POSTS:
        user = await db.users.find_one({"email": post_data["author_email"]})
        if user:
            post_filter = {"author_id": str(user["_id"]), "caption": post_data["caption"]}
            
            post_doc = {
                "$set": {
                    "location": post_data["location"],
                    "media_urls": post_data["images"], 
                    "media_type": "image",
                    "updated_at": datetime.now()
                },
                "$setOnInsert": {
                    "author_id": str(user["_id"]),
                    "created_at": datetime.now(),
                    "like_count": random.randint(10, 100)
                }
            }
            await db.posts.update_one(post_filter, post_doc, upsert=True)
            print(f"  ✓ Modified post for {post_data['author_email']}")

    print("\n" + "="*60)
    print("LOCAL DATA MODIFICATION COMPLETE!")
    print("="*60)
    client.close()

if __name__ == "__main__":
    asyncio.run(upload_dummy_data())