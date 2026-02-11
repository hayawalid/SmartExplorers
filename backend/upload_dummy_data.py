"""
Dummy Data Generator for SmartExplorers MongoDB
Creates 10 users with complete profiles, conversations, posts, etc.
"""
import asyncio
from datetime import datetime, timedelta
from motor.motor_asyncio import AsyncIOMotorClient
from passlib.context import CryptContext
from bson import ObjectId
import random

# Password hashing
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

# MongoDB connection
MONGODB_URI = "mongodb+srv://hayaadawy66_db_user:IrclengEMDTg443m@smartexplorers.5dz2fei.mongodb.net/"
DATABASE_NAME = "smartexplorers"


# ==================== Helper Functions ====================

def hash_password(password: str) -> str:
    """Hash password"""
    return pwd_context.hash(password)


def random_date(start_days_ago: int, end_days_ago: int = 0) -> datetime:
    """Generate random datetime"""
    start = datetime.now() - timedelta(days=start_days_ago)
    end = datetime.now() - timedelta(days=end_days_ago)
    delta = end - start
    random_seconds = random.randint(0, int(delta.total_seconds()))
    return start + timedelta(seconds=random_seconds)


# ==================== Dummy Data ====================

DUMMY_USERS = [
    # Travelers (7 users)
    {
        "account_type": "traveler",
        "email": "sarah.johnson@email.com",
        "username": "sarah_explorer",
        "password": "Password123!",
        "full_name": "Sarah Johnson",
        "phone_number": "+1-555-0101",
        "bio": "Solo female traveler passionate about ancient history and photography. First time visiting Egypt!",
        "profile": {
            "date_of_birth": datetime(1995, 3, 15),
            "country_of_origin": "United States",
            "preferred_language": "English",
            "wheelchair_access": False,
            "visual_assistance": False,
            "hearing_assistance": False,
            "mobility_support": False,
            "dietary_restrictions_flag": True,
            "sensory_sensitivity": False,
            "travel_interests": ["Ancient History", "Photography", "Culture & Arts", "Food & Cuisine"],
            "setup_interests": ["History/Archaeology", "Photography", "Culture & Arts"],
            "nationality": "American",
            "languages_spoken": ["English", "Spanish"],
            "is_solo_traveler": True,
            "first_time_egypt": True,
            "traveling_alone": True,
            "typical_budget_min": 50,
            "typical_budget_max": 150,
            "trips_count": 12,
            "reviews_count": 8,
            "photos_count": 45
        }
    },
    {
        "account_type": "traveler",
        "email": "ahmed.hassan@email.com",
        "username": "ahmed_adventurer",
        "password": "Password123!",
        "full_name": "Ahmed Hassan",
        "phone_number": "+20-100-123-4567",
        "bio": "Egyptian local showing visitors the hidden gems of Cairo. Love adventure and food!",
        "profile": {
            "date_of_birth": datetime(1988, 7, 22),
            "country_of_origin": "Egypt",
            "preferred_language": "Arabic",
            "wheelchair_access": False,
            "visual_assistance": False,
            "hearing_assistance": False,
            "mobility_support": False,
            "dietary_restrictions_flag": False,
            "sensory_sensitivity": False,
            "travel_interests": ["Adventure", "Food & Cuisine", "Nature", "Desert Safari"],
            "setup_interests": ["Adventure", "Food & Cuisine", "Relaxation"],
            "nationality": "Egyptian",
            "languages_spoken": ["Arabic", "English", "French"],
            "is_solo_traveler": False,
            "first_time_egypt": False,
            "traveling_alone": False,
            "typical_budget_min": 30,
            "typical_budget_max": 80,
            "trips_count": 25,
            "reviews_count": 15,
            "photos_count": 78
        }
    },
    {
        "account_type": "traveler",
        "email": "maria.garcia@email.com",
        "username": "maria_wanderer",
        "password": "Password123!",
        "full_name": "Maria Garcia",
        "phone_number": "+34-600-123-456",
        "bio": "Spanish architect interested in Islamic architecture. Traveling with my family.",
        "profile": {
            "date_of_birth": datetime(1982, 11, 8),
            "country_of_origin": "Spain",
            "preferred_language": "Spanish",
            "wheelchair_access": False,
            "visual_assistance": False,
            "hearing_assistance": False,
            "mobility_support": False,
            "dietary_restrictions_flag": True,
            "sensory_sensitivity": False,
            "travel_interests": ["Culture & Arts", "Ancient History", "Photography"],
            "setup_interests": ["Culture & Arts", "History/Archaeology"],
            "nationality": "Spanish",
            "languages_spoken": ["Spanish", "English", "French"],
            "is_solo_traveler": False,
            "first_time_egypt": True,
            "traveling_alone": False,
            "typical_budget_min": 100,
            "typical_budget_max": 250,
            "trips_count": 18,
            "reviews_count": 12,
            "photos_count": 62
        }
    },
    {
        "account_type": "traveler",
        "email": "yuki.tanaka@email.com",
        "username": "yuki_traveler",
        "password": "Password123!",
        "full_name": "Yuki Tanaka",
        "phone_number": "+81-90-1234-5678",
        "bio": "Japanese photographer capturing the beauty of the Nile. Third visit to Egypt!",
        "profile": {
            "date_of_birth": datetime(1990, 5, 20),
            "country_of_origin": "Japan",
            "preferred_language": "Japanese",
            "wheelchair_access": False,
            "visual_assistance": False,
            "hearing_assistance": False,
            "mobility_support": False,
            "dietary_restrictions_flag": False,
            "sensory_sensitivity": False,
            "travel_interests": ["Photography", "Nature", "Ancient History", "Beaches"],
            "setup_interests": ["Photography", "Relaxation", "History/Archaeology"],
            "nationality": "Japanese",
            "languages_spoken": ["Japanese", "English"],
            "is_solo_traveler": True,
            "first_time_egypt": False,
            "traveling_alone": True,
            "typical_budget_min": 80,
            "typical_budget_max": 200,
            "trips_count": 32,
            "reviews_count": 20,
            "photos_count": 156
        }
    },
    {
        "account_type": "traveler",
        "email": "david.oconnor@email.com",
        "username": "david_wheelchair",
        "password": "Password123!",
        "full_name": "David O'Connor",
        "phone_number": "+44-7700-900123",
        "bio": "Wheelchair user proving accessibility shouldn't limit adventure. Sharing accessible travel tips!",
        "profile": {
            "date_of_birth": datetime(1985, 9, 14),
            "country_of_origin": "United Kingdom",
            "preferred_language": "English",
            "wheelchair_access": True,
            "visual_assistance": False,
            "hearing_assistance": False,
            "mobility_support": True,
            "dietary_restrictions_flag": False,
            "sensory_sensitivity": False,
            "travel_interests": ["Ancient History", "Culture & Arts", "Food & Cuisine"],
            "setup_interests": ["History/Archaeology", "Culture & Arts", "Food & Cuisine"],
            "nationality": "British",
            "languages_spoken": ["English"],
            "is_solo_traveler": True,
            "first_time_egypt": True,
            "traveling_alone": True,
            "typical_budget_min": 100,
            "typical_budget_max": 300,
            "trips_count": 15,
            "reviews_count": 22,
            "photos_count": 38
        }
    },
    {
        "account_type": "traveler",
        "email": "fatima.ali@email.com",
        "username": "fatima_explorer",
        "password": "Password123!",
        "full_name": "Fatima Ali",
        "phone_number": "+971-50-123-4567",
        "bio": "Emirati travel blogger. Love discovering new places and meeting locals.",
        "profile": {
            "date_of_birth": datetime(1998, 1, 30),
            "country_of_origin": "United Arab Emirates",
            "preferred_language": "Arabic",
            "wheelchair_access": False,
            "visual_assistance": False,
            "hearing_assistance": False,
            "mobility_support": False,
            "dietary_restrictions_flag": True,
            "sensory_sensitivity": False,
            "travel_interests": ["Shopping", "Food & Cuisine", "Culture & Arts", "Nightlife"],
            "setup_interests": ["Food & Cuisine", "Culture & Arts", "Relaxation"],
            "nationality": "Emirati",
            "languages_spoken": ["Arabic", "English"],
            "is_solo_traveler": False,
            "first_time_egypt": False,
            "traveling_alone": False,
            "typical_budget_min": 150,
            "typical_budget_max": 400,
            "trips_count": 28,
            "reviews_count": 35,
            "photos_count": 210
        }
    },
    {
        "account_type": "traveler",
        "email": "lars.nielsen@email.com",
        "username": "lars_backpacker",
        "password": "Password123!",
        "full_name": "Lars Nielsen",
        "phone_number": "+45-20-12-34-56",
        "bio": "Danish backpacker on a budget. Looking for authentic experiences!",
        "profile": {
            "date_of_birth": datetime(2000, 6, 5),
            "country_of_origin": "Denmark",
            "preferred_language": "English",
            "wheelchair_access": False,
            "visual_assistance": False,
            "hearing_assistance": False,
            "mobility_support": False,
            "dietary_restrictions_flag": False,
            "sensory_sensitivity": False,
            "travel_interests": ["Adventure", "Nature", "Food & Cuisine", "Desert Safari"],
            "setup_interests": ["Adventure", "Food & Cuisine"],
            "nationality": "Danish",
            "languages_spoken": ["Danish", "English", "German"],
            "is_solo_traveler": True,
            "first_time_egypt": True,
            "traveling_alone": True,
            "typical_budget_min": 20,
            "typical_budget_max": 50,
            "trips_count": 8,
            "reviews_count": 5,
            "photos_count": 23
        }
    },
    
    # Service Providers (3 users)
    {
        "account_type": "service_provider",
        "email": "mohamed.guide@egypttours.com",
        "username": "mohamed_guide",
        "password": "Password123!",
        "full_name": "Mohamed Ibrahim",
        "phone_number": "+20-100-555-1234",
        "bio": "Licensed Egyptologist guide with 15 years experience. Specializing in Giza and Saqqara tours.",
        "provider_profile": {
            "full_legal_name": "Mohamed Ibrahim Hassan",
            "phone_number": "+20-100-555-1234",
            "bio": "Licensed Egyptologist with PhD from Cairo University. Passionate about sharing Egypt's rich history with visitors from around the world.",
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
            "safety_certified": True
        }
    },
    {
        "account_type": "service_provider",
        "email": "nadia.photo@egyptphoto.com",
        "username": "nadia_photographer",
        "password": "Password123!",
        "full_name": "Nadia El-Sayed",
        "phone_number": "+20-120-555-6789",
        "bio": "Professional photographer specializing in travel and portrait photography at iconic Egyptian locations.",
        "provider_profile": {
            "full_legal_name": "Nadia El-Sayed Ahmed",
            "phone_number": "+20-120-555-6789",
            "bio": "Award-winning photographer capturing magical moments at Egypt's most beautiful sites. Sunrise pyramid shoots are my specialty!",
            "service_type": "photographer",
            "verification_status": "verified",
            "business_name": "Egypt Memories Photography",
            "business_license_number": "EG-PHOTO-2024-5678",
            "address": "28 Nile Corniche, Luxor",
            "city": "Luxor",
            "governorate": "Luxor",
            "latitude": 25.6872,
            "longitude": 32.6396,
            "services_offered": ["Portrait Photography", "Couple Shoots", "Family Photos", "Drone Photography"],
            "languages": ["Arabic", "English", "Italian"],
            "price_range_min": 100,
            "price_range_max": 500,
            "rating": 4.8,
            "review_count": 89,
            "completed_tours_count": 156,
            "verified_flag": True,
            "safety_certified": True
        }
    },
    {
        "account_type": "service_provider",
        "email": "kareem.driver@cairotravel.com",
        "username": "kareem_driver",
        "password": "Password123!",
        "full_name": "Kareem Mostafa",
        "phone_number": "+20-111-555-9999",
        "bio": "Professional driver with modern, air-conditioned vehicles. Safe and reliable transportation across Egypt.",
        "provider_profile": {
            "full_legal_name": "Kareem Mostafa Abdullah",
            "phone_number": "+20-111-555-9999",
            "bio": "Licensed driver with 10 years of experience. Clean, comfortable vehicles and excellent knowledge of all major routes in Egypt.",
            "service_type": "driver",
            "verification_status": "verified",
            "business_name": "Safe Egypt Transfers",
            "business_license_number": "EG-TRANS-2024-9999",
            "address": "42 Airport Road, Cairo",
            "city": "Cairo",
            "governorate": "Cairo",
            "latitude": 30.0444,
            "longitude": 31.2357,
            "services_offered": ["Airport Transfers", "City Tours", "Long Distance Travel", "Custom Routes"],
            "languages": ["Arabic", "English"],
            "price_range_min": 30,
            "price_range_max": 200,
            "rating": 4.7,
            "review_count": 234,
            "completed_tours_count": 567,
            "verified_flag": True,
            "safety_certified": True
        }
    }
]


# Sample conversations for travelers
SAMPLE_CONVERSATIONS = [
    {
        "user_email": "sarah.johnson@email.com",
        "messages": [
            {"role": "user", "content": "Hi! I'm visiting Egypt for the first time. What should I know?", "timestamp": datetime.now() - timedelta(days=5)},
            {"role": "assistant", "content": "Welcome to Egypt, Sarah! As a first-time visitor and solo female traveler, here are the key things to know:\n\n1. Safety: Egypt is generally safe for tourists, but stay aware of your surroundings\n2. Dress modestly: Cover shoulders and knees, especially at religious sites\n3. Currency: Egyptian Pound (EGP). ATMs widely available\n4. Haggling: Expected at markets - start at 50% of asking price\n5. Stay hydrated and use sun protection\n\nWould you like specific advice about any particular area?", "timestamp": datetime.now() - timedelta(days=5)},
            {"role": "user", "content": "Yes, I want to visit the pyramids. Any tips?", "timestamp": datetime.now() - timedelta(days=5)},
            {"role": "assistant", "content": "Great choice! Here are tips for visiting the Pyramids of Giza:\n\n🕐 Best time: Early morning (8-9 AM) to avoid crowds and heat\n🎫 Ticket: Entry is separate from pyramid interior access\n📸 Photography: Bring extra batteries - you'll take lots of photos!\n🚖 Transport: Use official taxis or Uber/Careem\n👥 Guides: Hire licensed guides at the entrance, not from touts\n⚠️ Scam alert: Ignore 'helpful' strangers offering unsolicited services\n\nAs a solo woman: Consider joining a small group tour for added comfort. The site is wheelchair accessible at the base.", "timestamp": datetime.now() - timedelta(days=5)}
        ]
    },
    {
        "user_email": "david.oconnor@email.com",
        "messages": [
            {"role": "user", "content": "I'm a wheelchair user. Can I visit the pyramids?", "timestamp": datetime.now() - timedelta(days=3)},
            {"role": "assistant", "content": "Yes, absolutely! The Pyramids of Giza are accessible for wheelchair users:\n\n✅ Accessible areas:\n- Main viewing area at the base of the pyramids\n- Sphinx viewing platform (with assistance)\n- Visitor center and facilities\n- Museum areas\n\n❌ Not accessible:\n- Inside the pyramids (narrow passages with stairs)\n- Some elevated viewing points\n\nTips:\n- Hire a guide experienced with accessibility\n- Visit early morning (cooler, less crowded)\n- Bring someone to assist on uneven areas\n- Accessible restrooms available at visitor center\n\nMany tour operators offer specialized accessible tours. Would you like recommendations?", "timestamp": datetime.now() - timedelta(days=3)},
            {"role": "user", "content": "Yes please! And what about the Egyptian Museum?", "timestamp": datetime.now() - timedelta(days=3)},
            {"role": "assistant", "content": "The Grand Egyptian Museum (GEM) is fully wheelchair accessible! \n\n✅ Features:\n- Wheelchair ramps throughout\n- Accessible elevators\n- Wide corridors\n- Accessible restrooms\n- Wheelchair rental available\n- Priority entry for visitors with disabilities\n\nThe old Egyptian Museum in Tahrir Square has limited accessibility (some areas require stairs), but GEM is the way to go!\n\nFor accessible tour operators, I recommend:\n1. Accessible Egypt Tours\n2. Easy Access Travel\n3. Wheelchair Friendly Egypt\n\nThey provide trained guides and accessible vehicles.", "timestamp": datetime.now() - timedelta(days=3)}
        ]
    }
]


# Sample posts
SAMPLE_POSTS = [
    {
        "author_email": "sarah.johnson@email.com",
        "caption": "Finally here! The Pyramids of Giza are even more breathtaking in person. 🇪🇬✨ #BucketList #Egypt #Pyramids",
        "location": "Pyramids of Giza",
        "latitude": 29.9792,
        "longitude": 31.1342
    },
    {
        "author_email": "yuki.tanaka@email.com",
        "caption": "Golden hour at the Nile. This country never stops amazing me. 📸🌅 #NileRiver #Photography #Egypt",
        "location": "Nile River, Cairo",
        "latitude": 30.0444,
        "longitude": 31.2357
    },
    {
        "author_email": "fatima_explorer",
        "caption": "Best koshari I've ever had! If you're in Cairo, you MUST try this local gem. 🍲😍 #EgyptianFood #Cairo",
        "location": "Downtown Cairo",
        "latitude": 30.0444,
        "longitude": 31.2357
    }
]


# ==================== Main Upload Function ====================

async def upload_dummy_data():
    """Upload all dummy data to MongoDB"""
    
    print("Connecting to MongoDB...")
    client = AsyncIOMotorClient(MONGODB_URI)
    db = client[DATABASE_NAME]
    
    print(f"✓ Connected to {DATABASE_NAME}\n")
    
    # Clear existing data (optional - comment out to keep existing data)
    print("Clearing existing data...")
    for collection in await db.list_collection_names():
        await db[collection].delete_many({})
    print("✓ Cleared\n")
    
    user_ids = {}  # Store user_id mappings
    
    # ==================== Upload Users & Profiles ====================
    
    print("Creating users and profiles...")
    for i, user_data in enumerate(DUMMY_USERS, 1):
        # Create user
        user_doc = {
            "account_type": user_data["account_type"],
            "email": user_data["email"],
            "username": user_data["username"],
            "hashed_password": hash_password(user_data["password"]),
            "full_name": user_data["full_name"],
            "phone_number": user_data.get("phone_number"),
            "bio": user_data.get("bio"),
            "avatar_url": f"https://ui-avatars.com/api/?name={user_data['full_name'].replace(' ', '+')}&size=200",
            "email_verified": True,
            "phone_verified": True,
            "identity_verified": user_data["account_type"] == "service_provider",
            "verified_flag": user_data["account_type"] == "service_provider",
            "rating": random.uniform(4.5, 5.0) if user_data["account_type"] == "traveler" else 0,
            "review_count": random.randint(5, 30) if user_data["account_type"] == "traveler" else 0,
            "member_since": random_date(365, 30),
            "is_active": True,
            "is_banned": False,
            "created_at": random_date(365, 30),
            "last_login": random_date(7, 0)
        }
        
        result = await db.users.insert_one(user_doc)
        user_id = str(result.inserted_id)
        user_ids[user_data["email"]] = user_id
        
        # Create profile based on account type
        if user_data["account_type"] == "traveler":
            profile_data = user_data["profile"].copy()
            profile_data["user_id"] = user_id
            profile_data["created_at"] = user_doc["created_at"]
            await db.traveler_profiles.insert_one(profile_data)
            
            # Create user memory
            memory = {
                "user_id": user_id,
                "learned_interests": profile_data.get("travel_interests", [])[:3],
                "learned_concerns": ["safety"] if profile_data.get("is_solo_traveler") else [],
                "favorite_destinations": ["Cairo", "Giza"] if not profile_data.get("first_time_egypt") else [],
                "recent_topics": [],
                "tone_preference": "friendly",
                "detail_level": "medium",
                "first_time_egypt": profile_data.get("first_time_egypt", True),
                "traveling_alone": profile_data.get("traveling_alone", False),
                "key_facts": {},
                "total_conversations": random.randint(1, 5),
                "total_messages": random.randint(10, 50),
                "created_at": user_doc["created_at"]
            }
            await db.user_memories.insert_one(memory)
            
            # Create user preferences
            preferences = {
                "user_id": user_id,
                "theme_mode": random.choice(["light", "dark", "system"]),
                "high_contrast_enabled": False,
                "font_scale": 1.0,
                "reduce_motion": False,
                "push_notifications_enabled": True,
                "email_notifications_enabled": True,
                "safety_alerts_enabled": True,
                "profile_public": True,
                "show_location": True,
                "allow_messages": True,
                "app_language": "en",
                "created_at": user_doc["created_at"]
            }
            await db.user_preferences.insert_one(preferences)
            
        else:  # service_provider
            provider_data = user_data["provider_profile"].copy()
            provider_data["user_id"] = user_id
            provider_data["created_at"] = user_doc["created_at"]
            provider_data["id_scan_timestamp"] = random_date(60, 30)
            provider_data["selfie_timestamp"] = random_date(60, 30)
            await db.service_provider_profiles.insert_one(provider_data)
        
        print(f"  {i}. Created {user_data['username']} ({user_data['account_type']})")
    
    print(f"✓ Created {len(DUMMY_USERS)} users\n")
    
    # ==================== Upload Conversations ====================
    
    print("Creating conversations...")
    for conv_data in SAMPLE_CONVERSATIONS:
        user_id = user_ids[conv_data["user_email"]]
        conv_id = f"conv_{ObjectId()}"
        
        conversation = {
            "conversation_id": conv_id,
            "user_id": user_id,
            "title": conv_data["messages"][0]["content"][:50],
            "messages": conv_data["messages"],
            "message_count": len(conv_data["messages"]),
            "last_message_at": conv_data["messages"][-1]["timestamp"],
            "is_active": True,
            "is_archived": False,
            "created_at": conv_data["messages"][0]["timestamp"]
        }
        
        await db.conversations.insert_one(conversation)
        print(f"  - Created conversation for {conv_data['user_email']}")
    
    print(f"✓ Created {len(SAMPLE_CONVERSATIONS)} conversations\n")
    
    # ==================== Upload Posts ====================
    
    print("Creating posts...")
    for post_data in SAMPLE_POSTS:
        # Find user by email or username
        if "@" in post_data["author_email"]:
            user_id = user_ids.get(post_data["author_email"])
        else:
            # Find by username
            user = await db.users.find_one({"username": post_data["author_email"]})
            user_id = str(user["_id"]) if user else None
        
        if user_id:
            post = {
                "author_id": user_id,
                "caption": post_data["caption"],
                "location": post_data["location"],
                "latitude": post_data["latitude"],
                "longitude": post_data["longitude"],
                "media_type": "image",
                "media_url": f"https://source.unsplash.com/800x600/?egypt,{post_data['location'].replace(' ', '-')}",
                "like_count": random.randint(50, 500),
                "comment_count": random.randint(5, 50),
                "share_count": random.randint(0, 20),
                "is_promoted": False,
                "is_public": True,
                "created_at": random_date(14, 1),
                "time": random_date(14, 1)
            }
            await db.posts.insert_one(post)
            print(f"  - Created post by {post_data['author_email']}")
    
    print(f"✓ Created {len(SAMPLE_POSTS)} posts\n")
    
    # ==================== Summary ====================
    
    print("="*60)
    print("DATA UPLOAD COMPLETE!")
    print("="*60)
    print(f"\n📊 Summary:")
    print(f"  Users: {await db.users.count_documents({})}")
    print(f"  Traveler Profiles: {await db.traveler_profiles.count_documents({})}")
    print(f"  Service Provider Profiles: {await db.service_provider_profiles.count_documents({})}")
    print(f"  Conversations: {await db.conversations.count_documents({})}")
    print(f"  User Memories: {await db.user_memories.count_documents({})}")
    print(f"  User Preferences: {await db.user_preferences.count_documents({})}")
    print(f"  Posts: {await db.posts.count_documents({})}")
    
    print(f"\n🔑 Test Login Credentials:")
    print(f"  All passwords: Password123!")
    print(f"\n  Travelers:")
    print(f"    sarah.johnson@email.com (Solo female, first time)")
    print(f"    ahmed.hassan@email.com (Local Egyptian)")
    print(f"    david.oconnor@email.com (Wheelchair user)")
    print(f"\n  Service Providers:")
    print(f"    mohamed.guide@egypttours.com (Tour guide)")
    print(f"    nadia.photo@egyptphoto.com (Photographer)")
    print(f"    kareem.driver@cairotravel.com (Driver)")
    
    print("\n✓ Dummy data uploaded successfully!\n")
    
    client.close()


# ==================== Run ====================

if __name__ == "__main__":
    print("\n" + "="*60)
    print("SMARTEXPLORERS DUMMY DATA GENERATOR")
    print("="*60 + "\n")
    
    asyncio.run(upload_dummy_data())