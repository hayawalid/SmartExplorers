"""
Smart Matching Engine for Travelers and Service Providers
Uses:
1. Verification filtering
2. Interest overlap scoring (keyword-based)
3. K-means clustering for demographics
4. LLM verification for match quality (optional with Groq)
5. Strict threshold filtering (50%+)
"""
"""
Test suite for Smart Matching System
Tests all 5 core features with real database users
"""
import nest_asyncio
nest_asyncio.apply()


# CRITICAL FIX: Load environment variables FIRST
import os
from dotenv import load_dotenv

# Load .env file - try multiple possible locations
load_dotenv()  # Looks for .env in current directory
load_dotenv(os.path.join(os.path.dirname(__file__), 'backend', '.env'))  # backend subfolder

# Print to verify it loaded (remove after testing)
print(f"✓ GROQ_API_KEY loaded: {'✓ Present' if os.getenv('GROQ_API_KEY') else '✗ MISSING'}")
print(f"✓ MongoDB URI loaded: {'✓ Present' if os.getenv('MONGODB_URI') else '✗ MISSING'}")

import numpy as np
from sklearn.cluster import KMeans
from sklearn.preprocessing import StandardScaler
from typing import List, Dict, Any, Tuple, Optional
from datetime import datetime
from collections import Counter
import os
from dataclasses import dataclass
import json
import requests
from pymongo import MongoClient
from bson import ObjectId
import certifi


@dataclass
class MatchResult:
    """Result of a matching operation"""
    matched_user_id: str
    match_score: float
    match_quality: str  # "PERFECT", "GREAT", "GOOD", or "NOT_VERIFIED"
    match_reasons: List[str]
    common_interests: List[str]
    common_languages: List[str]
    common_dates: List[str]
    budget_compatibility: float
    safety_score: float
    demographics_bonus: float
    interest_similarity: float
    cluster_id: int
    llm_verification: Optional[str] = None
    llm_verified: bool = False


class SmartMatchingEngine:
    """
    Smart matching engine with interest overlap and LLM verification
    """
    
    def __init__(self, openai_api_key: Optional[str] = None, groq_api_key: Optional[str] = None):
        """
        Initialize the matching engine
        
        Args:
            openai_api_key: OpenAI API key (deprecated, use groq_api_key)
            groq_api_key: Groq API key for LLM verification
        """
        self.groq_api_key = groq_api_key or openai_api_key or os.getenv("GROQ_API_KEY")
        
        self.scaler = StandardScaler()
        self.kmeans_model = None
        self.n_clusters = 5
        
        # MongoDB connection
        self.mongodb_uri = os.getenv("MONGODB_URI", "mongodb://localhost:27017")
        self.db_name = os.getenv("MONGODB_DB_NAME", "smartexplorers")
        
        self.mongo_client = None
        self.db = None
        
        # Common languages
        self.common_languages = [
            "Arabic", "English", "French", "German", "Spanish", "Italian",
            "Russian", "Chinese", "Japanese", "Korean", "Portuguese"
        ]
        
        print("✓ Matching engine initialized (keyword-based)")
        
        # Initialize MongoDB connection
        self._init_mongodb()
    
    # ==================== DATABASE FETCHING ====================
    
    def _init_mongodb(self):
        """Initialize MongoDB connection"""
        try:
            if self.mongodb_uri:
                self.mongo_client = MongoClient(
                    self.mongodb_uri,
                    tlsCAFile=certifi.where(),
                    serverSelectionTimeoutMS=5000
                )
                self.db = self.mongo_client[self.db_name]
                
                # Test connection
                self.mongo_client.admin.command('ping')
                print(f"✓ MongoDB connected successfully to {self.db_name}")
                
                # Debug: List collections
                collections = self.db.list_collection_names()
                print(f"📋 Available collections: {collections}")
                
            else:
                print("⚠️  MongoDB URI not found, using mock data")
        except Exception as e:
            print(f"⚠️  MongoDB connection failed: {e}, using mock data")
            self.mongo_client = None
            self.db = None
    
    def _convert_objectid(self, data: Dict) -> Dict:
        """Convert ObjectId to string for JSON serialization"""
        if isinstance(data, dict):
            for key, value in data.items():
                if isinstance(value, ObjectId):
                    data[key] = str(value)
                elif isinstance(value, dict):
                    data[key] = self._convert_objectid(value)
                elif isinstance(value, list):
                    data[key] = [
                        self._convert_objectid(item) if isinstance(item, dict) else item
                        for item in value
                    ]
        return data
    
    def fetch_all_users(self) -> List[Dict[str, Any]]:
        """
        Fetch all users from MongoDB with their associated profiles
        
        Returns:
            List of user documents with embedded profile data
        """
        all_users = []
        
        if self.db is None:
            print("⚠️  No database connection, using mock users for testing")
            return self._get_mock_users()
        
        try:
            # Get all users from the users collection
            users_collection = self.db['users']
            users = list(users_collection.find({}))
            
            print(f"📡 Found {len(users)} users in database")
            
            for user in users:
                user = self._convert_objectid(user)
                user_id = user['_id']
                
                # Fetch the appropriate profile based on account_type
                if user.get('account_type') == 'traveler':
                    # Get traveler profile
                    profile = self.db['traveler_profiles'].find_one({'user_id': user_id})
                    if profile:
                        profile = self._convert_objectid(profile)
                        user['profile'] = profile
                        print(f"  ✓ Loaded traveler: {user.get('full_name', user.get('username'))}")
                    else:
                        print(f"  ⚠️  No profile found for traveler: {user.get('email')}")
                        user['profile'] = {}
                        
                elif user.get('account_type') == 'service_provider':
                    # Get service provider profile
                    profile = self.db['service_provider_profiles'].find_one({'user_id': user_id})
                    if profile:
                        profile = self._convert_objectid(profile)
                        user['provider_profile'] = profile
                        print(f"  ✓ Loaded service provider: {user.get('full_name', user.get('username'))}")
                    else:
                        print(f"  ⚠️  No profile found for service provider: {user.get('email')}")
                        user['provider_profile'] = {}
                
                # Add bio if it exists in user document
                if 'bio' not in user:
                    user['bio'] = ''
                
                all_users.append(user)
            
            print(f"\n✓ Total {len(all_users)} users loaded from database")
            
        except Exception as e:
            print(f"⚠️  Error fetching from database: {e}")
            print("⚠️  Falling back to mock users")
            return self._get_mock_users()
        
        # If no users found, use mock data
        if not all_users:
            print("⚠️  No users found in database, using mock users")
            return self._get_mock_users()
        
        return all_users
    
    def fetch_users_by_type(self, account_type: str) -> List[Dict[str, Any]]:
        """
        Fetch users by account type with their profiles
        
        Args:
            account_type: Either 'traveler' or 'service_provider'
        
        Returns:
            List of users of specified type with profiles
        """
        if self.db is None:
            return []
        
        users = []
        
        try:
            # Get users of specified type
            users_collection = self.db['users']
            user_docs = list(users_collection.find({'account_type': account_type}))
            
            for user in user_docs:
                user = self._convert_objectid(user)
                user_id = user['_id']
                
                # Fetch profile
                if account_type == 'traveler':
                    profile = self.db['traveler_profiles'].find_one({'user_id': user_id})
                    if profile:
                        profile = self._convert_objectid(profile)
                        user['profile'] = profile
                else:
                    profile = self.db['service_provider_profiles'].find_one({'user_id': user_id})
                    if profile:
                        profile = self._convert_objectid(profile)
                        user['provider_profile'] = profile
                
                users.append(user)
            
            print(f"✓ Fetched {len(users)} {account_type}s from database")
            
        except Exception as e:
            print(f"⚠️  Error fetching {account_type}s: {e}")
        
        return users
    
    def fetch_user_by_id(self, user_id: str) -> Optional[Dict[str, Any]]:
        """
        Fetch a single user by ID with their profile
        
        Args:
            user_id: The user's ObjectId as string
        
        Returns:
            User document with profile or None if not found
        """
        if self.db is None:
            return None
        
        try:
            # Convert string ID to ObjectId
            try:
                obj_id = ObjectId(user_id)
            except:
                print(f"⚠️  Invalid ObjectId format: {user_id}")
                return None
            
            # Find user
            users_collection = self.db['users']
            user = users_collection.find_one({'_id': obj_id})
            
            if user:
                user = self._convert_objectid(user)
                user_id = user['_id']
                
                # Fetch profile based on account type
                if user.get('account_type') == 'traveler':
                    profile = self.db['traveler_profiles'].find_one({'user_id': user_id})
                    if profile:
                        profile = self._convert_objectid(profile)
                        user['profile'] = profile
                elif user.get('account_type') == 'service_provider':
                    profile = self.db['service_provider_profiles'].find_one({'user_id': user_id})
                    if profile:
                        profile = self._convert_objectid(profile)
                        user['provider_profile'] = profile
                
                return user
            
        except Exception as e:
            print(f"⚠️  Error fetching user {user_id}: {e}")
        
        return None
    
    def fetch_user_by_email(self, email: str) -> Optional[Dict[str, Any]]:
        """
        Fetch a single user by email with their profile
        
        Args:
            email: The user's email address
        
        Returns:
            User document with profile or None if not found
        """
        if self.db is None:
            return None
        
        try:
            # Find user by email
            users_collection = self.db['users']
            user = users_collection.find_one({'email': email})
            
            if user:
                user = self._convert_objectid(user)
                user_id = user['_id']
                
                # Fetch profile based on account type
                if user.get('account_type') == 'traveler':
                    profile = self.db['traveler_profiles'].find_one({'user_id': user_id})
                    if profile:
                        profile = self._convert_objectid(profile)
                        user['profile'] = profile
                elif user.get('account_type') == 'service_provider':
                    profile = self.db['service_provider_profiles'].find_one({'user_id': user_id})
                    if profile:
                        profile = self._convert_objectid(profile)
                        user['provider_profile'] = profile
                
                return user
            
        except Exception as e:
            print(f"⚠️  Error fetching user by email {email}: {e}")
        
        return None
    
    def _get_mock_users(self) -> List[Dict[str, Any]]:
        """Generate mock users for testing when database is unavailable"""
        print("📊 Generating mock users for testing...")
        
        from datetime import datetime
        
        mock_users = [
            {
                "_id": "1",
                "email": "sarah.johnson@email.com",
                "full_name": "Sarah Johnson",
                "username": "sarah_explorer",
                "account_type": "traveler",
                "verified_flag": True,
                "bio": "Solo female traveler passionate about ancient history and photography. First time visiting Egypt!",
                "profile": {
                    "date_of_birth": datetime(1995, 3, 15),
                    "gender": "female",
                    "nationality": "American",
                    "languages_spoken": ["English", "Spanish"],
                    "travel_interests": ["Ancient History", "Photography", "Culture & Arts", "Food & Cuisine"],
                    "setup_interests": ["History/Archaeology", "Photography", "Culture & Arts"],
                    "typical_budget_min": 50,
                    "typical_budget_max": 150,
                    "is_solo_traveler": True,
                    "first_time_egypt": True,
                    "traveling_alone": True,
                    "wheelchair_access": False,
                    "visual_assistance": False,
                    "hearing_assistance": False,
                    "mobility_support": False
                }
            },
            {
                "_id": "2",
                "email": "ahmed.hassan@email.com",
                "full_name": "Ahmed Hassan",
                "username": "ahmed_adventurer",
                "account_type": "traveler",
                "verified_flag": True,
                "bio": "Egyptian local showing visitors the hidden gems of Cairo. Love adventure and food!",
                "profile": {
                    "date_of_birth": datetime(1988, 7, 22),
                    "gender": "male",
                    "nationality": "Egyptian",
                    "languages_spoken": ["Arabic", "English", "French"],
                    "travel_interests": ["Adventure", "Food & Cuisine", "Nature", "Desert Safari"],
                    "setup_interests": ["Adventure", "Food & Cuisine", "Relaxation"],
                    "typical_budget_min": 30,
                    "typical_budget_max": 80,
                    "is_solo_traveler": False,
                    "first_time_egypt": False,
                    "traveling_alone": False,
                    "wheelchair_access": False,
                    "visual_assistance": False,
                    "hearing_assistance": False,
                    "mobility_support": False
                }
            },
            {
                "_id": "3",
                "email": "david.oconnor@email.com",
                "full_name": "David O'Connor",
                "username": "david_wheelchair",
                "account_type": "traveler",
                "verified_flag": True,
                "bio": "Wheelchair user proving accessibility shouldn't limit adventure. Sharing accessible travel tips!",
                "profile": {
                    "date_of_birth": datetime(1985, 9, 14),
                    "gender": "male",
                    "nationality": "British",
                    "languages_spoken": ["English"],
                    "travel_interests": ["Ancient History", "Culture & Arts", "Food & Cuisine"],
                    "setup_interests": ["History/Archaeology", "Culture & Arts", "Food & Cuisine"],
                    "typical_budget_min": 100,
                    "typical_budget_max": 300,
                    "is_solo_traveler": True,
                    "first_time_egypt": True,
                    "traveling_alone": True,
                    "wheelchair_access": True,
                    "visual_assistance": False,
                    "hearing_assistance": False,
                    "mobility_support": True
                }
            },
            {
                "_id": "4",
                "email": "mohamed.guide@egypttours.com",
                "full_name": "Mohamed Ibrahim",
                "username": "mohamed_guide",
                "account_type": "service_provider",
                "verified_flag": True,
                "bio": "Licensed Egyptologist guide with 15 years experience. Specializing in Giza and Saqqara tours.",
                "provider_profile": {
                    "verified_flag": True,
                    "languages": ["Arabic", "English", "French", "German"],
                    "services_offered": ["Pyramid Tours", "Museum Tours", "Historical Site Visits", "Custom Itineraries"],
                    "price_range_min": 50,
                    "price_range_max": 150,
                    "service_type": "tour_guide",
                    "wheelchair_access": True,
                    "visual_assistance": False,
                    "hearing_assistance": False,
                    "mobility_support": False,
                    "rating": 4.9,
                    "review_count": 127
                }
            },
            {
                "_id": "5",
                "email": "nadia.photo@egyptphoto.com",
                "full_name": "Nadia El-Sayed",
                "username": "nadia_photographer",
                "account_type": "service_provider",
                "verified_flag": True,
                "bio": "Professional photographer specializing in travel and portrait photography at iconic Egyptian locations.",
                "provider_profile": {
                    "verified_flag": True,
                    "languages": ["Arabic", "English", "Italian"],
                    "services_offered": ["Portrait Photography", "Couple Shoots", "Family Photos", "Drone Photography"],
                    "price_range_min": 100,
                    "price_range_max": 500,
                    "service_type": "photographer",
                    "wheelchair_access": False,
                    "visual_assistance": False,
                    "hearing_assistance": False,
                    "mobility_support": False,
                    "rating": 4.8,
                    "review_count": 89
                }
            }
        ]
        
        print(f"✓ Generated {len(mock_users)} mock users")
        return mock_users
    
    def close(self):
        """Close MongoDB connection"""
        if self.mongo_client:
            self.mongo_client.close()
            print("✓ MongoDB connection closed")
    
    # ==================== POINT 1: VERIFICATION FILTERING ====================
    
    def _is_verified(self, user: Dict[str, Any]) -> bool:
        """
        Check if user is verified and eligible for matching
        
        POINT 1: Verification check before matching
        """
        if user.get("account_type") == "traveler":
            return True

        # Check user-level verification
        if not user.get("verified_flag", False):
            return False
        
        # For providers, also check provider profile verification
        if user.get("account_type") == "service_provider":
            provider_profile = user.get("provider_profile", {})
            if not provider_profile.get("verified_flag", False):
                return False
        
        return True
    
    # ==================== POINT 2: INTEREST SIMILARITY (KEYWORD-BASED) ====================
    
    def _calculate_interest_similarity(self, user1: Dict, user2: Dict) -> float:
        """
        Calculate interest similarity based on keyword overlap
        
        Simpler than semantic embeddings but no PyTorch dependency
        """
        # Get profile data
        profile1 = user1.get("profile", {}) if user1.get("account_type") == "traveler" else user1.get("provider_profile", {})
        profile2 = user2.get("profile", {}) if user2.get("account_type") == "traveler" else user2.get("provider_profile", {})
        
        # Get interests
        interests1 = set(profile1.get("travel_interests", []) or profile1.get("setup_interests", []) or profile1.get("services_offered", []))
        interests2 = set(profile2.get("travel_interests", []) or profile2.get("setup_interests", []) or profile2.get("services_offered", []))
        
        # Get bios
        bio1 = (user1.get("bio", "") or profile1.get("bio", "")).lower()
        bio2 = (user2.get("bio", "") or profile2.get("bio", "")).lower()
        
        # Calculate interest overlap
        if not interests1 or not interests2:
            interest_score = 0.3  # Low default if no interests
        else:
            common = interests1 & interests2
            union = interests1 | interests2
            interest_score = len(common) / len(union) if union else 0.3
        
        # Calculate bio similarity (simple keyword matching)
        bio_score = 0.5  # Default
        if bio1 and bio2:
            bio_words1 = set(bio1.split())
            bio_words2 = set(bio2.split())
            
            if bio_words1 and bio_words2:
                common_words = bio_words1 & bio_words2
                bio_score = min(len(common_words) / 10, 1.0)  # Cap at 1.0
        
        # Combined score (interests weighted more heavily)
        combined_score = (interest_score * 0.7) + (bio_score * 0.3)
        
        return float(combined_score)
    
    # ==================== POINT 3: DEMOGRAPHIC CLUSTERING ====================
    
    def _extract_demographic_features(self, user: Dict[str, Any]) -> np.ndarray:
        """
        Extract demographic features for clustering
        
        POINT 3: Cluster according to demographics
        """
        profile = user.get("profile", {}) if user.get("account_type") == "traveler" else user.get("provider_profile", {})
        
        # Language encoding (11 features)
        language_vector = np.zeros(len(self.common_languages))
        languages = profile.get("languages_spoken", []) or profile.get("languages", [])
        for idx, language in enumerate(self.common_languages):
            if language in languages:
                language_vector[idx] = 1
        
        # Budget features (2 features)
        budget_min = profile.get("typical_budget_min", 0) or profile.get("price_range_min", 0)
        budget_max = profile.get("typical_budget_max", 0) or profile.get("price_range_max", 0)
        budget_min_norm = min(budget_min / 500.0, 1.0)
        budget_max_norm = min(budget_max / 500.0, 1.0)
        
        # Demographics (4 features)
        age = self._calculate_age(profile.get("date_of_birth")) / 100.0 if profile.get("date_of_birth") else 0.3
        is_solo = float(profile.get("is_solo_traveler", False))
        first_time = float(profile.get("first_time_egypt", False))
        
        # Gender encoding (1 feature)
        gender_map = {"male": 0.0, "female": 1.0, "other": 0.5}
        gender = gender_map.get(profile.get("gender", "other"), 0.5)
        
        # Accessibility features (4 features)
        wheelchair = float(profile.get("wheelchair_access", False))
        visual = float(profile.get("visual_assistance", False))
        hearing = float(profile.get("hearing_assistance", False))
        mobility = float(profile.get("mobility_support", False))
        
        # Combine all features (22 total)
        features = np.concatenate([
            language_vector,      # 11 features
            [budget_min_norm, budget_max_norm],  # 2 features
            [age, is_solo, first_time, gender],  # 4 features
            [wheelchair, visual, hearing, mobility]  # 4 features
        ])
        
        return features
    
    def train_clusters(self, users: List[Dict[str, Any]], n_clusters: int = 5):
        """
        Train K-means clustering model on demographic features
        
        POINT 3: Clustering based on demographics
        """
        self.n_clusters = n_clusters
        
        # Filter only verified users for training
        verified_users = [u for u in users if self._is_verified(u)]
        
        if len(verified_users) < n_clusters:
            n_clusters = max(2, len(verified_users) // 2)
            self.n_clusters = n_clusters
        
        # Extract demographic features
        features_list = []
        for user in verified_users:
            features = self._extract_demographic_features(user)
            features_list.append(features)
        
        # Train K-means on demographics only
        X = np.array(features_list)
        X_scaled = self.scaler.fit_transform(X)
        
        self.kmeans_model = KMeans(n_clusters=n_clusters, random_state=42, n_init=10)
        self.kmeans_model.fit(X_scaled)
        
        print(f"✓ Trained {n_clusters} clusters on {len(verified_users)} verified users")
        return self.kmeans_model.labels_
    
    def _get_cluster(self, user: Dict[str, Any]) -> int:
        """Get the cluster ID for a user based on demographics"""
        if self.kmeans_model is None:
            raise ValueError("Model not trained. Call train_clusters first.")
        
        features = self._extract_demographic_features(user)
        features_scaled = self.scaler.transform([features])
        return self.kmeans_model.predict(features_scaled)[0]
    
    def _calculate_age(self, date_of_birth: datetime) -> int:
        """Calculate age from date of birth"""
        if not date_of_birth:
            return 30  # Default age
        today = datetime.now()
        return today.year - date_of_birth.year - (
            (today.month, today.day) < (date_of_birth.month, date_of_birth.day)
        )
    
    # ==================== MATCHING LOGIC ====================
    
    def _check_language_compatibility(self, languages1: List[str], languages2: List[str]) -> Tuple[bool, List[str]]:
        """Check if two users share at least one common language"""
        common = list(set(languages1) & set(languages2))
        return len(common) > 0, common
    
    def _check_budget_compatibility(self, budget1: Tuple[float, float], budget2: Tuple[float, float]) -> Tuple[bool, float]:
        """Check if two users have compatible budgets"""
        min1, max1 = budget1
        min2, max2 = budget2
        
        # Check for overlap
        overlap_min = max(min1, min2)
        overlap_max = min(max1, max2)
        
        if overlap_min <= overlap_max:
            range1 = max1 - min1 if max1 > min1 else 1
            range2 = max2 - min2 if max2 > min2 else 1
            overlap_range = overlap_max - overlap_min
            compatibility = min(overlap_range / range1, overlap_range / range2)
            return True, compatibility
        
        # Check if close
        gap = min(abs(max1 - min2), abs(max2 - min1))
        avg_range = (max1 - min1 + max2 - min2) / 2
        
        if avg_range > 0 and gap / avg_range < 0.4:
            return True, 0.6 - (gap / avg_range)
        
        return False, 0.0
    
    def _calculate_safety_score(self, user1: Dict, user2: Dict) -> float:
        """Calculate safety compatibility score"""
        score = 0.7  # Base
        
        verified1 = self._is_verified(user1)
        verified2 = self._is_verified(user2)
        
        if verified1 and verified2:
            score += 0.3
        
        return min(score, 1.0)
    
    # ==================== POINT 5: LLM VERIFICATION ====================
    
    async def _verify_match_with_llm(self, user1: Dict, user2: Dict, match_score: float) -> Tuple[bool, str, str]:
        """
        Use Groq LLM to verify if match is actually reasonable
        
        POINT 5: LLM verification of match quality
        """
        if not self.groq_api_key:
            return True, "LLM verification unavailable", "GOOD"
        
        # Prepare user descriptions
        profile1 = user1.get("profile", {}) if user1.get("account_type") == "traveler" else user1.get("provider_profile", {})
        profile2 = user2.get("profile", {}) if user2.get("account_type") == "traveler" else user2.get("provider_profile", {})
        
        user1_desc = f"""
User 1: {user1.get('full_name', 'Unknown')} ({user1.get('account_type', 'unknown').upper()})
- Interests: {', '.join((profile1.get('travel_interests', []) or profile1.get('services_offered', []))[:5])}
- Bio: {(user1.get('bio', '') or profile1.get('bio', ''))[:200]}
- Languages: {', '.join(profile1.get('languages_spoken', []) or profile1.get('languages', []))}
- Budget/Price: ${profile1.get('typical_budget_min', 0) or profile1.get('price_range_min', 0)}-${profile1.get('typical_budget_max', 0) or profile1.get('price_range_max', 0)}
- Nationality: {profile1.get('nationality', 'Unknown')}
        """.strip()
        
        user2_desc = f"""
User 2: {user2.get('full_name', 'Unknown')} ({user2.get('account_type', 'unknown').upper()})
- Interests: {', '.join((profile2.get('travel_interests', []) or profile2.get('services_offered', []))[:5])}
- Bio: {(user2.get('bio', '') or profile2.get('bio', ''))[:200]}
- Languages: {', '.join(profile2.get('languages_spoken', []) or profile2.get('languages', []))}
- Budget/Price: ${profile2.get('typical_budget_min', 0) or profile2.get('price_range_min', 0)}-${profile2.get('typical_budget_max', 0) or profile2.get('price_range_max', 0)}
- Nationality: {profile2.get('nationality', 'Unknown')}
        """.strip()
        
        # Detailed anti-hallucination prompt
        prompt = f"""You are an expert travel matchmaking advisor specializing in creating meaningful connections between travelers and service providers in Egypt.

Your task: Analyze if these two users would make a GENUINE, MEANINGFUL match for travel companionship or services in Egypt.

{user1_desc}

{user2_desc}

Current algorithmic match score: {match_score:.1%}

CRITICAL EVALUATION CRITERIA:
1. Do they share genuine common interests (not just one overlapping keyword)?
2. Are their travel styles compatible (budget, preferences, pace)?
3. Do they speak a common language fluently?
4. Would they realistically enjoy traveling together or benefit from the service?
5. Are there any red flags (vastly different budgets, incompatible travel styles, no real overlap)?

ANTI-HALLUCINATION RULES:
- Base your judgment ONLY on the information provided above
- Do NOT invent interests, qualities, or compatibility that aren't explicitly stated
- Do NOT assume compatibility just because they're both travelers
- If there's minimal overlap, be honest about it
- Consider cultural and practical compatibility

RESPOND IN EXACTLY THIS FORMAT:
VERDICT: [PERFECT / GREAT / GOOD / POOR]
REASON: [One clear sentence explaining why, based ONLY on facts above]

Be honest and critical. A poor match is better than a forced match."""

        try:
            # Call Groq API
            response = requests.post(
                "https://api.groq.com/openai/v1/chat/completions",
                headers={
                    "Authorization": f"Bearer {self.groq_api_key}",
                    "Content-Type": "application/json"
                },
                json={
                    "model": "llama-3.3-70b-versatile",
                    "messages": [
                        {
                            "role": "system",
                            "content": "You are a critical travel matchmaking expert. Be honest and factual. Reject poor matches."
                        },
                        {
                            "role": "user",
                            "content": prompt
                        }
                    ],
                    "temperature": 0.3,  # Low temperature for consistency
                    "max_tokens": 150
                },
                timeout=10
            )
            
            if response.status_code == 200:
                result = response.json()
                llm_response = result['choices'][0]['message']['content'].strip()
                
                # Parse response
                lines = llm_response.split('\n')
                verdict = "GOOD"
                reason = llm_response
                
                for line in lines:
                    if line.startswith("VERDICT:"):
                        verdict = line.replace("VERDICT:", "").strip()
                    elif line.startswith("REASON:"):
                        reason = line.replace("REASON:", "").strip()
                
                # Determine if verified
                verified = verdict in ["PERFECT", "GREAT", "GOOD"]
                
                return verified, reason, verdict
            else:
                return True, f"LLM API error: {response.status_code}", "GOOD"
                
        except Exception as e:
            return True, f"LLM verification failed: {str(e)}", "GOOD"
    
    # ==================== MAIN MATCHING FUNCTION ====================
    
    def find_matches(
        self,
        target_user: Dict[str, Any],
        candidate_users: List[Dict[str, Any]],
        travel_dates: Optional[List[Dict]] = None,
        top_k: int = 10,
        use_llm_verification: bool = False
    ) -> List[MatchResult]:
        """
        Find best matches with verification, interest matching, and optional LLM validation
        
        Implements all 5 points:
        1. Verification filtering
        2. Interest similarity (keyword-based)
        3. Demographic clustering
        4. 50% threshold filtering
        5. LLM verification (optional)
        """
        if self.kmeans_model is None:
            raise ValueError("Model not trained. Call train_clusters first.")
        
        # POINT 1: Check target user verification
        if not self._is_verified(target_user):
            print(f"⚠️  Target user {target_user.get('full_name', target_user.get('username'))} is NOT VERIFIED")
            return []
        
        target_type = target_user.get("account_type")
        target_cluster = self._get_cluster(target_user)
        target_profile = target_user.get("profile", {}) if target_type == "traveler" else target_user.get("provider_profile", {})
        
        matches = []
        
        for candidate in candidate_users:
            # Skip self
            if candidate.get("email") == target_user.get("email"):
                continue
            
            candidate_type = candidate.get("account_type")
            
            # POINT 1: Check candidate verification
            if not self._is_verified(candidate):
                continue  # Skip unverified users entirely
            
            # Service providers cannot request matches with other service providers
            if target_type == "service_provider" and candidate_type == "service_provider":
                continue
            
            # Get candidate cluster (POINT 3: Demographic clustering)
            candidate_cluster = self._get_cluster(candidate)
            cluster_similarity = 1.0 if target_cluster == candidate_cluster else 0.6
            
            candidate_profile = candidate.get("profile", {}) if candidate_type == "traveler" else candidate.get("provider_profile", {})
            
            # Check languages (REQUIRED)
            target_languages = target_profile.get("languages_spoken", []) or target_profile.get("languages", [])
            candidate_languages = candidate_profile.get("languages", []) if candidate_type == "service_provider" else candidate_profile.get("languages_spoken", [])
            
            has_common_language, common_languages = self._check_language_compatibility(
                target_languages, candidate_languages
            )
            
            if not has_common_language:
                continue  # No match without common language
            
            language_score = min(len(common_languages) / 2.0, 1.0)
            
            # POINT 2: Calculate interest similarity (keyword-based)
            interest_similarity = self._calculate_interest_similarity(target_user, candidate)
            
            # Get common interests (for display)
            if target_type == "traveler":
                target_interests = target_profile.get("travel_interests", []) + target_profile.get("setup_interests", [])
            else:
                target_interests = target_profile.get("services_offered", [])
                
            if candidate_type == "traveler":
                candidate_interests = candidate_profile.get("travel_interests", []) + candidate_profile.get("setup_interests", [])
            else:
                candidate_interests = candidate_profile.get("services_offered", [])
            
            common_interests = list(set(target_interests) & set(candidate_interests))
            
            # Budget compatibility
            target_budget = (
                target_profile.get("typical_budget_min", 0) or target_profile.get("price_range_min", 0),
                target_profile.get("typical_budget_max", 1000) or target_profile.get("price_range_max", 1000)
            )
            candidate_budget = (
                candidate_profile.get("price_range_min" if candidate_type == "service_provider" else "typical_budget_min", 0),
                candidate_profile.get("price_range_max" if candidate_type == "service_provider" else "typical_budget_max", 1000)
            )
            
            budget_compatible, budget_score = self._check_budget_compatibility(
                target_budget, candidate_budget
            )
            
            if budget_score < 0.3:
                budget_score = 0.3
            
            # Safety score
            safety_score = self._calculate_safety_score(target_user, candidate)
            
            # Calculate final match score with INTEREST SIMILARITY as primary factor
            match_score = (
                cluster_similarity * 0.15 +      # Demographic clustering
                interest_similarity * 0.40 +     # INTEREST MATCHING (highest weight)
                language_score * 0.20 +
                budget_score * 0.15 +
                safety_score * 0.10
            )
            
            # POINT 4: Remove matches below 50%
            if match_score < 0.50:
                continue
            
            # Compile match reasons
            match_reasons = []
            if interest_similarity > 0.6:
                match_reasons.append(f"Strong interest overlap ({interest_similarity:.1%})")
            if common_interests:
                match_reasons.append(f"Shared interests: {', '.join(common_interests[:3])}")
            if common_languages:
                match_reasons.append(f"Common languages: {', '.join(common_languages)}")
            if budget_compatible:
                match_reasons.append(f"Compatible budget range")
            if safety_score > 0.9:
                match_reasons.append("Both users verified and safe")
            
            # Assign initial quality based on score
            if match_score >= 0.80:
                match_quality = "PERFECT"
            elif match_score >= 0.65:
                match_quality = "GREAT"
            else:
                match_quality = "GOOD"
            
            # Create match result
            match = MatchResult(
                matched_user_id=candidate.get("email", "") or candidate.get("_id", ""),
                match_score=match_score,
                match_quality=match_quality,
                match_reasons=match_reasons,
                common_interests=common_interests,
                common_languages=common_languages,
                common_dates=[],
                budget_compatibility=budget_score,
                safety_score=safety_score,
                demographics_bonus=0.0,
                interest_similarity=interest_similarity,
                cluster_id=candidate_cluster,
                llm_verified=False
            )
            
            matches.append((match, candidate))
        
        # Sort by match score
        matches.sort(key=lambda x: x[0].match_score, reverse=True)
        
        # POINT 5: LLM verification for top matches (optional)
        if use_llm_verification and self.groq_api_key:
            print(f"\n🤖 Verifying top {min(len(matches), top_k)} matches with LLM...")
            
            import asyncio
            
            async def verify_all():
                verified_matches = []
                for match, candidate in matches[:top_k]:
                    llm_verified, llm_reason, llm_quality = await self._verify_match_with_llm(
                        target_user, candidate, match.match_score
                    )
                    
                    # Update match with LLM results
                    match.llm_verified = llm_verified
                    match.llm_verification = llm_reason
                    match.match_quality = llm_quality
                    
                    verified_matches.append(match)
                
                return verified_matches
            
            # Run async verification
            try:
                loop = asyncio.get_event_loop()
                final_matches = loop.run_until_complete(verify_all())
            except RuntimeError:
                # Create new event loop if needed
                loop = asyncio.new_event_loop()
                asyncio.set_event_loop(loop)
                final_matches = loop.run_until_complete(verify_all())
        else:
            # No LLM verification - just return top matches
            final_matches = [match for match, _ in matches[:top_k]]
        
        return final_matches
    
    def get_match_statistics(self, matches: List[MatchResult]) -> Dict[str, Any]:
        """Get statistics about matches"""
        if not matches:
            return {
                "total_matches": 0,
                "average_score": 0.0,
                "top_score": 0.0
            }
        
        scores = [m.match_score for m in matches]
        qualities = [m.match_quality for m in matches]
        
        quality_counts = Counter(qualities)
        
        all_interests = []
        all_languages = []
        all_clusters = []
        
        for m in matches:
            all_interests.extend(m.common_interests)
            all_languages.extend(m.common_languages)
            all_clusters.append(m.cluster_id)
        
        return {
            "total_matches": len(matches),
            "average_score": float(np.mean(scores)),
            "top_score": float(max(scores)),
            "score_std": float(np.std(scores)),
            "quality_distribution": dict(quality_counts),
            "perfect_matches": quality_counts.get("PERFECT", 0),
            "great_matches": quality_counts.get("GREAT", 0),
            "good_matches": quality_counts.get("GOOD", 0),
            "matches_above_90": sum(1 for s in scores if s >= 0.9),
            "matches_above_80": sum(1 for s in scores if s >= 0.8),
            "matches_above_50": sum(1 for s in scores if s >= 0.5),
            "top_interests": Counter(all_interests).most_common(10),
            "top_languages": Counter(all_languages).most_common(5),
            "cluster_distribution": dict(Counter(all_clusters))
        }


# ==================== USAGE EXAMPLE ====================

if __name__ == "__main__":
    # Initialize engine
    engine = SmartMatchingEngine()
    
    try:
        # Fetch all users from MongoDB
        print("\n📡 Fetching users from database...")
        all_users = engine.fetch_all_users()
        
        if len(all_users) < 2:
            print("❌ Not enough users for matching (need at least 2)")
            print("   Please run the dummy data generator first:")
            print("   python -m backend.dummy_data_generator")
        else:
            # Split target and candidates (first user is target)
            target_user = all_users[0]
            candidate_users = all_users[1:]
            
            print(f"\n🎯 Target user: {target_user.get('full_name', target_user.get('username'))} ({target_user.get('account_type')})")
            print(f"👥 Candidate users: {len(candidate_users)}")
            
            # Train clusters
            print("\n📊 Training demographic clusters...")
            engine.train_clusters(all_users)
            
            # Find matches
            print("\n🔍 Finding matches...")
            matches = engine.find_matches(
                target_user, 
                candidate_users, 
                top_k=5, 
                use_llm_verification=False
            )
            
            # View results
            print(f"\n✅ Found {len(matches)} matches:\n")
            for i, m in enumerate(matches, 1):
                print(f"{i}. Score: {m.match_score:.1%} | Quality: {m.match_quality}")
                print(f"   User: {m.matched_user_id}")
                print(f"   Reasons: {', '.join(m.match_reasons[:2])}")
                print()
            
            # Get statistics
            stats = engine.get_match_statistics(matches)
            print("📈 Match Statistics:")
            print(f"   Average score: {stats['average_score']:.1%}")
            print(f"   Perfect matches: {stats['perfect_matches']}")
            print(f"   Great matches: {stats['great_matches']}")
    
    finally:
        # Close database connection
        engine.close()