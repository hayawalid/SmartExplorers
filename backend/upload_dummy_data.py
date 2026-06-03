import asyncio
import os
from datetime import datetime, timedelta
from motor.motor_asyncio import AsyncIOMotorClient
import bcrypt
from bson import ObjectId
import random
from dotenv import load_dotenv


load_dotenv()
load_dotenv(os.path.join(os.path.dirname(__file__), ".env"))
# MongoDB connection
MONGODB_URI = (
    os.getenv("MONGODB_URI")
    or os.getenv("MONGO_URI")
    or "mongodb+srv://hayaadawy66_db_user:IrclengEMDTg443m@smartexplorers.5dz2fei.mongodb.net/"
)
DATABASE_NAME = "smartexplorers"

def hash_password(password: str) -> str:
    return bcrypt.hashpw(password.encode("utf-8"), bcrypt.gensalt()).decode("utf-8")

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
        "bio": "Solo female traveler and photographer exploring Egypt",
        "verified_flag": True,
        "password": "Password123!"
    },
    {
        "email": "ahmed.hassan@email.com",
        "username": "ahmed_adventurer",
        "full_name": "Ahmed Hassan",
        "avatar_url": "/static/avatars/ahmed.jpg",
        "account_type": "traveler",
        "bio": "Budget-conscious traveler exploring Egypt",
        "verified_flag": True,
        "password": "Password123!"
    },
    {
        "email": "maria.garcia@email.com",
        "username": "maria_wanderer",
        "full_name": "Maria Garcia",
        "avatar_url": "/static/avatars/maria.jpg",
        "account_type": "traveler",
        "bio": "Accessibility advocate traveling with wheelchair",
        "verified_flag": True,
        "password": "Password123!"
    },
    {
        "email": "yuki.tanaka@email.com",
        "username": "yuki_traveler",
        "full_name": "Yuki Tanaka",
        "avatar_url": "/static/avatars/yuki.jpg",
        "account_type": "traveler",
        "bio": "Japanese photographer capturing the beauty of the Nile",
        "verified_flag": True,
        "password": "Password123!"
    },
    {
        "email": "david.oconnor@email.com",
        "username": "david_wheelchair",
        "full_name": "David O'Connor",
        "avatar_url": "/static/avatars/david.jpg",
        "account_type": "traveler",
        "bio": "Wheelchair user proving accessibility shouldn't limit adventure",
        "verified_flag": True,
        "password": "Password123!"
    },
    {
        "email": "fatima.ali@email.com",
        "username": "fatima_explorer",
        "full_name": "Fatima Ali",
        "avatar_url": "/static/avatars/fatima.jpg",
        "account_type": "traveler",
        "bio": "Female traveler focused on culture, safety, and photography",
        "verified_flag": True,
        "password": "Password123!"
    },
    {
        "email": "lars.nielsen@email.com",
        "username": "lars_backpacker",
        "full_name": "Lars Nielsen",
        "avatar_url": "/static/avatars/lars.jpg",
        "account_type": "traveler",
        "bio": "Budget backpacker looking for history and desert adventures",
        "verified_flag": True,
        "password": "Password123!"
    },
    {
        "email": "mohamed.guide@egypttours.com",
        "username": "mohamed_guide",
        "full_name": "Mohamed Ibrahim",
        "avatar_url": "/static/avatars/mohamed.jpg",
        "account_type": "service_provider",
        "bio": "Licensed Egyptologist guide with 15 years experience",
        "verified_flag": True,
        "password": "Password123!"
    }
    ,
    {
        "email": "amr.tours@desertsafaris.com",
        "username": "amr_desert",
        "full_name": "Amr El-Sayed",
        "avatar_url": "/static/avatars/amr.jpg",
        "account_type": "service_provider",
        "bio": "Experienced desert safari operator and local guide",
        "verified_flag": True,
        "password": "Password123!"
    },
    {
        "email": "layla.cairo@cairoutours.com",
        "username": "layla_cairo",
        "full_name": "Layla Kamal",
        "avatar_url": "/static/avatars/layla.jpg",
        "account_type": "service_provider",
        "bio": "Cultural experiences curator and small-group host",
        "verified_flag": True,
        "password": "Password123!"
    }
]


# Matching-specific profile data used by app/services/smart_matching_engine.py.
MATCHING_PROFILE_SEEDS = {
    "sarah.johnson@email.com": {
        "collection": "traveler_profiles",
        "doc": {
            "full_name": "Sarah Johnson",
            "phone_number": "+1-555-0101",
            "country_of_origin": "United States",
            "preferred_language": "English",
            "date_of_birth": datetime(1992, 3, 15),
            "gender": "female",
            "wheelchair_access": False,
            "visual_assistance": False,
            "hearing_assistance": False,
            "mobility_support": False,
            "dietary_restrictions_flag": False,
            "sensory_sensitivity": False,
            "travel_interests": ["Photography", "Ancient History", "Culture & Arts", "Beaches"],
            "setup_interests": ["Photography", "History/Archaeology", "Culture & Arts"],
            "languages_spoken": ["English", "Spanish"],
            "is_solo_traveler": True,
            "first_time_egypt": True,
            "typical_budget_min": 80,
            "typical_budget_max": 200,
            "bio": "Solo female traveler and photographer exploring Egypt",
            "verified_flag": True,
        },
    },
    "ahmed.hassan@email.com": {
        "collection": "traveler_profiles",
        "doc": {
            "full_name": "Ahmed Hassan",
            "phone_number": "+20-100-555-9999",
            "country_of_origin": "Egypt",
            "preferred_language": "Arabic",
            "date_of_birth": datetime(1995, 11, 3),
            "gender": "male",
            "wheelchair_access": False,
            "visual_assistance": False,
            "hearing_assistance": False,
            "mobility_support": False,
            "dietary_restrictions_flag": False,
            "sensory_sensitivity": False,
            "travel_interests": ["Ancient History", "Food & Cuisine", "Beaches"],
            "setup_interests": ["History/Archaeology", "Food & Cuisine"],
            "languages_spoken": ["Arabic", "English"],
            "is_solo_traveler": True,
            "first_time_egypt": False,
            "typical_budget_min": 30,
            "typical_budget_max": 80,
            "bio": "Budget-conscious traveler exploring Egypt",
            "verified_flag": True,
        },
    },
    "maria.garcia@email.com": {
        "collection": "traveler_profiles",
        "doc": {
            "full_name": "Maria Garcia",
            "phone_number": "+34-600-123456",
            "country_of_origin": "Spain",
            "preferred_language": "Spanish",
            "date_of_birth": datetime(1988, 2, 10),
            "gender": "female",
            "wheelchair_access": True,
            "visual_assistance": False,
            "hearing_assistance": False,
            "mobility_support": True,
            "dietary_restrictions_flag": True,
            "sensory_sensitivity": False,
            "travel_interests": ["Culture & Arts", "Ancient History", "Museums"],
            "setup_interests": ["Culture & Arts", "History/Archaeology"],
            "languages_spoken": ["Spanish", "English"],
            "is_solo_traveler": True,
            "first_time_egypt": True,
            "typical_budget_min": 120,
            "typical_budget_max": 280,
            "bio": "Accessibility advocate traveling with wheelchair",
            "verified_flag": True,
        },
    },
    "yuki.tanaka@email.com": {
        "collection": "traveler_profiles",
        "doc": {
            "full_name": "Yuki Tanaka",
            "phone_number": "+81-90-1234-5678",
            "country_of_origin": "Japan",
            "preferred_language": "Japanese",
            "date_of_birth": datetime(1990, 5, 20),
            "gender": "other",
            "wheelchair_access": False,
            "visual_assistance": False,
            "hearing_assistance": False,
            "mobility_support": False,
            "dietary_restrictions_flag": False,
            "sensory_sensitivity": False,
            "travel_interests": ["Photography", "Nature", "Ancient History", "Beaches"],
            "setup_interests": ["Photography", "Relaxation", "History/Archaeology"],
            "languages_spoken": ["Japanese", "English"],
            "is_solo_traveler": True,
            "first_time_egypt": False,
            "typical_budget_min": 80,
            "typical_budget_max": 200,
            "bio": "Japanese photographer capturing the beauty of the Nile",
            "verified_flag": True,
        },
    },
    "david.oconnor@email.com": {
        "collection": "traveler_profiles",
        "doc": {
            "full_name": "David O'Connor",
            "phone_number": "+44-7700-900123",
            "country_of_origin": "United Kingdom",
            "preferred_language": "English",
            "date_of_birth": datetime(1985, 9, 14),
            "gender": "male",
            "wheelchair_access": True,
            "visual_assistance": False,
            "hearing_assistance": False,
            "mobility_support": True,
            "dietary_restrictions_flag": False,
            "sensory_sensitivity": False,
            "travel_interests": ["Ancient History", "Culture & Arts", "Food & Cuisine"],
            "setup_interests": ["History/Archaeology", "Culture & Arts", "Food & Cuisine"],
            "languages_spoken": ["English"],
            "is_solo_traveler": True,
            "first_time_egypt": True,
            "typical_budget_min": 100,
            "typical_budget_max": 300,
            "bio": "Wheelchair user proving accessibility shouldn't limit adventure",
            "verified_flag": True,
        },
    },
    "fatima.ali@email.com": {
        "collection": "traveler_profiles",
        "doc": {
            "full_name": "Fatima Ali",
            "phone_number": "+20-100-555-4242",
            "country_of_origin": "Egypt",
            "preferred_language": "Arabic",
            "date_of_birth": datetime(1994, 6, 8),
            "gender": "female",
            "wheelchair_access": False,
            "visual_assistance": False,
            "hearing_assistance": False,
            "mobility_support": False,
            "dietary_restrictions_flag": False,
            "sensory_sensitivity": False,
            "travel_interests": ["Culture & Arts", "Photography", "Desert Safari", "Adventure"],
            "setup_interests": ["Culture & Arts", "Photography", "Adventure"],
            "languages_spoken": ["Arabic", "English", "French"],
            "is_solo_traveler": True,
            "first_time_egypt": False,
            "typical_budget_min": 90,
            "typical_budget_max": 260,
            "bio": "Female traveler focused on culture, safety, and photography",
            "verified_flag": True,
        },
    },
    "lars.nielsen@email.com": {
        "collection": "traveler_profiles",
        "doc": {
            "full_name": "Lars Nielsen",
            "phone_number": "+45-20-55-66-77",
            "country_of_origin": "Denmark",
            "preferred_language": "English",
            "date_of_birth": datetime(1991, 1, 30),
            "gender": "male",
            "wheelchair_access": False,
            "visual_assistance": False,
            "hearing_assistance": False,
            "mobility_support": False,
            "dietary_restrictions_flag": False,
            "sensory_sensitivity": False,
            "travel_interests": ["Adventure", "Nature", "Desert Safari", "Ancient History"],
            "setup_interests": ["Adventure", "Nature", "History/Archaeology"],
            "languages_spoken": ["English", "German"],
            "is_solo_traveler": True,
            "first_time_egypt": True,
            "typical_budget_min": 70,
            "typical_budget_max": 180,
            "bio": "Budget backpacker looking for history and desert adventures",
            "verified_flag": True,
        },
    },
    "mohamed.guide@egypttours.com": {
        "collection": "service_provider_profiles",
        "doc": {
            "full_legal_name": "Mohamed Ibrahim Hassan",
            "phone_number": "+20-100-555-1234",
            "bio": "Licensed Egyptologist with PhD from Cairo University",
            "service_type": "tour_guide",
            "verification_status": "verified",
            "business_name": "Pyramids Expert Tours",
            "business_license_number": "EG-TOUR-2024-1234",
            "address": "15 Pyramid Street, Giza, Cairo",
            "city": "Giza",
            "governorate": "Giza",
            "latitude": 29.9792,
            "longitude": 31.1342,
            "services_offered": ["Pyramid Tours", "Museum Tours", "Historical Site Visits", "Custom Itineraries"],
            "languages": ["Arabic", "English", "French", "German"],
            "price_range_min": 50,
            "price_range_max": 150,
            "rating": 4.9,
            "review_count": 127,
            "completed_tours_count": 342,
            "verified_flag": True,
            "safety_certified": True,
        },
    },
    "amr.tours@desertsafaris.com": {
        "collection": "service_provider_profiles",
        "doc": {
            "full_legal_name": "Amr El-Sayed",
            "phone_number": "+20-100-777-8888",
            "bio": "Expert desert safari operator, fluent in English and Arabic",
            "service_type": "desert_safari",
            "verification_status": "verified",
            "business_name": "Sahara Trails",
            "business_license_number": "EG-DS-2023-5678",
            "address": "Road to the Desert, Luxor",
            "city": "Luxor",
            "governorate": "Luxor",
            "latitude": 25.6872,
            "longitude": 32.6396,
            "services_offered": ["Desert Safari", "Camel Tours", "Stargazing Camps", "Custom Itineraries"],
            "languages": ["Arabic", "English"],
            "price_range_min": 40,
            "price_range_max": 200,
            "rating": 4.8,
            "review_count": 58,
            "completed_tours_count": 210,
            "verified_flag": True,
            "safety_certified": True,
        },
    },
    "layla.cairo@cairoutours.com": {
        "collection": "service_provider_profiles",
        "doc": {
            "full_legal_name": "Layla Kamal",
            "phone_number": "+20-122-555-3344",
            "bio": "Curates small-group cultural experiences in Cairo",
            "service_type": "cultural_host",
            "verification_status": "verified",
            "business_name": "Cairo Curations",
            "business_license_number": "EG-CC-2022-9987",
            "address": "Zamalek, Cairo",
            "city": "Cairo",
            "governorate": "Cairo",
            "latitude": 30.0444,
            "longitude": 31.2357,
            "services_offered": ["Walking Tours", "Museum Guides", "Home Dining Experiences"],
            "languages": ["Arabic", "English", "French"],
            "price_range_min": 30,
            "price_range_max": 120,
            "rating": 4.7,
            "review_count": 84,
            "completed_tours_count": 145,
            "verified_flag": True,
            "safety_certified": True,
        },
    },
}

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
        matching_seed = MATCHING_PROFILE_SEEDS.get(user_data["email"], {})
        update_doc = {
            "$set": {
                "username": user_data["username"],
                "full_name": user_data["full_name"],
                "avatar_url": user_data["avatar_url"],
                "bio": user_data.get("bio") or matching_seed.get("doc", {}).get("bio"),
                "verified_flag": user_data.get("verified_flag", True),
                "is_active": True,
                "is_banned": False,
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

    # --- STEP 2: Update matching profiles ---
    print("\nUpdating traveler and service provider profiles...")
    for email, seed in MATCHING_PROFILE_SEEDS.items():
        user = await db.users.find_one({"email": email})
        if not user:
            print(f"  ⚠️  Skipping {email} because the user record was not found")
            continue

        user_id = str(user["_id"])
        profile_doc = {
            **seed["doc"],
            "user_id": user_id,
            "updated_at": datetime.now(),
        }
        profile_doc.setdefault("created_at", datetime.now())

        if seed["collection"] == "traveler_profiles":
            await db.traveler_profiles.update_one(
                {"user_id": user_id},
                {"$set": profile_doc},
                upsert=True,
            )
        else:
            await db.service_provider_profiles.update_one(
                {"user_id": user_id},
                {"$set": profile_doc},
                upsert=True,
            )
        print(f"  ✓ Seeded matching profile for {email}")

    # --- STEP 3: Update Posts ---
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