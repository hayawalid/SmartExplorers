"""
Smart Matching Engine for Travelers and Service Providers
Uses K-means clustering and LLM for intelligent matching based on:
- Interests
- Travel dates
- Languages
- Budget
- Safety preferences
- Demographics (nationality, age, gender, disabilities)
"""

import numpy as np
from sklearn.cluster import KMeans
from sklearn.preprocessing import StandardScaler, LabelEncoder
from typing import List, Dict, Any, Tuple, Optional
from datetime import datetime, timedelta
from collections import Counter
import os
from dataclasses import dataclass
import json

try:
    import openai
    OPENAI_AVAILABLE = True
except ImportError:
    OPENAI_AVAILABLE = False


@dataclass
class MatchResult:
    """Result of a matching operation"""
    matched_user_id: str
    match_score: float
    match_reasons: List[str]
    common_interests: List[str]
    common_languages: List[str]
    common_dates: List[str]
    budget_compatibility: float
    safety_score: float
    demographics_bonus: float
    cluster_id: int


class SmartMatchingEngine:
    """
    Smart matching engine using K-means clustering and LLM analysis
    """
    
    def __init__(self, openai_api_key: Optional[str] = None):
        """
        Initialize the matching engine
        
        Args:
            openai_api_key: OpenAI API key for LLM analysis (optional)
        """
        self.openai_api_key = openai_api_key or os.getenv("OPENAI_API_KEY")
        if self.openai_api_key and OPENAI_AVAILABLE:
            openai.api_key = self.openai_api_key
        
        self.scaler = StandardScaler()
        self.interest_encoder = LabelEncoder()
        self.language_encoder = LabelEncoder()
        self.kmeans_model = None
        self.n_clusters = 5  # Default number of clusters
        
        # Common interest categories for encoding
        self.common_interests = [
            "Ancient History", "Photography", "Adventure", "Food & Cuisine",
            "Nature", "Beaches", "Culture & Arts", "Shopping", "Nightlife",
            "Relaxation", "History/Archaeology", "Museums", "Wildlife",
            "Water Sports", "Desert Safari", "Religious Sites", "Architecture"
        ]
        
        # Common languages
        self.common_languages = [
            "Arabic", "English", "French", "German", "Spanish", "Italian",
            "Russian", "Chinese", "Japanese", "Korean", "Portuguese"
        ]
    
    def _encode_interests(self, interests: List[str]) -> np.ndarray:
        """
        Encode interests into a numerical vector
        
        Args:
            interests: List of interest strings
            
        Returns:
            Binary vector of interest presence
        """
        vector = np.zeros(len(self.common_interests))
        for idx, interest in enumerate(self.common_interests):
            if interest in interests:
                vector[idx] = 1
        return vector
    
    def _encode_languages(self, languages: List[str]) -> np.ndarray:
        """
        Encode languages into a numerical vector
        
        Args:
            languages: List of language strings
            
        Returns:
            Binary vector of language presence
        """
        vector = np.zeros(len(self.common_languages))
        for idx, language in enumerate(self.common_languages):
            if language in languages:
                vector[idx] = 1
        return vector
    
    def _calculate_age(self, date_of_birth: datetime) -> int:
        """Calculate age from date of birth"""
        if not date_of_birth:
            return 0
        today = datetime.now()
        return today.year - date_of_birth.year - (
            (today.month, today.day) < (date_of_birth.month, date_of_birth.day)
        )
    
    def _extract_features_traveler(self, traveler: Dict[str, Any]) -> np.ndarray:
        """
        Extract features from a traveler profile for clustering
        
        Args:
            traveler: Traveler profile dictionary
            
        Returns:
            Feature vector for clustering
        """
        profile = traveler.get("profile", {})
        
        # Interest encoding (17 features)
        interests = profile.get("travel_interests", []) + profile.get("setup_interests", [])
        interest_vector = self._encode_interests(interests)
        
        # Language encoding (11 features)
        languages = profile.get("languages_spoken", [])
        language_vector = self._encode_languages(languages)
        
        # Budget features (normalized to 0-1 scale, 2 features)
        budget_min = profile.get("typical_budget_min", 0) / 500.0  # Normalize
        budget_max = profile.get("typical_budget_max", 0) / 500.0
        
        # Safety/accessibility features (6 features)
        wheelchair = float(profile.get("wheelchair_access", False))
        visual = float(profile.get("visual_assistance", False))
        hearing = float(profile.get("hearing_assistance", False))
        mobility = float(profile.get("mobility_support", False))
        dietary = float(profile.get("dietary_restrictions_flag", False))
        sensory = float(profile.get("sensory_sensitivity", False))
        
        # Demographics (3 features)
        age = self._calculate_age(profile.get("date_of_birth")) / 100.0  # Normalize
        is_solo = float(profile.get("is_solo_traveler", False))
        first_time = float(profile.get("first_time_egypt", False))
        
        # Combine all features
        features = np.concatenate([
            interest_vector,      # 17 features
            language_vector,      # 11 features
            [budget_min, budget_max],  # 2 features
            [wheelchair, visual, hearing, mobility, dietary, sensory],  # 6 features
            [age, is_solo, first_time]  # 3 features
        ])
        
        return features
    
    def _extract_features_provider(self, provider: Dict[str, Any]) -> np.ndarray:
        """
        Extract features from a service provider profile for clustering
        
        Args:
            provider: Service provider profile dictionary
            
        Returns:
            Feature vector for clustering
        """
        provider_profile = provider.get("provider_profile", {})
        
        # Service type encoding (simplified - convert to interests)
        service_type = provider_profile.get("service_type", "")
        services_offered = provider_profile.get("services_offered", [])
        
        # Map services to interests
        service_interests = []
        if "tour_guide" in service_type.lower() or any("tour" in s.lower() for s in services_offered):
            service_interests.extend(["Ancient History", "Culture & Arts", "History/Archaeology"])
        if any("photo" in s.lower() for s in services_offered):
            service_interests.append("Photography")
        if any("food" in s.lower() or "cuisine" in s.lower() for s in services_offered):
            service_interests.append("Food & Cuisine")
        
        interest_vector = self._encode_interests(service_interests)
        
        # Language encoding
        languages = provider_profile.get("languages", [])
        language_vector = self._encode_languages(languages)
        
        # Budget features
        budget_min = provider_profile.get("price_range_min", 0) / 500.0
        budget_max = provider_profile.get("price_range_max", 0) / 500.0
        
        # Safety features (providers with certification get higher safety scores)
        safety_cert = float(provider_profile.get("safety_certified", False))
        verified = float(provider_profile.get("verified_flag", False))
        
        # Fill remaining features with zeros to match traveler feature size
        padding = np.zeros(4)  # To match wheelchair, visual, hearing, mobility
        
        # Rating and experience
        rating = provider_profile.get("rating", 0.0) / 5.0  # Normalize
        experience = min(provider_profile.get("completed_tours_count", 0) / 100.0, 1.0)
        is_verified = float(verified)
        
        features = np.concatenate([
            interest_vector,
            language_vector,
            [budget_min, budget_max],
            [safety_cert, verified] + list(padding),
            [rating, experience, is_verified]
        ])
        
        return features
    
    def train_clusters(self, users: List[Dict[str, Any]], n_clusters: int = 5):
        """
        Train K-means clustering model on user data
        
        Args:
            users: List of user dictionaries (both travelers and providers)
            n_clusters: Number of clusters to create
        """
        self.n_clusters = n_clusters
        
        # Extract features for all users
        features_list = []
        for user in users:
            if user.get("account_type") == "traveler":
                features = self._extract_features_traveler(user)
            else:
                features = self._extract_features_provider(user)
            features_list.append(features)
        
        # Convert to numpy array and fit scaler
        X = np.array(features_list)
        X_scaled = self.scaler.fit_transform(X)
        
        # Train K-means
        self.kmeans_model = KMeans(n_clusters=n_clusters, random_state=42, n_init=10)
        self.kmeans_model.fit(X_scaled)
        
        return self.kmeans_model.labels_
    
    def _get_cluster(self, user: Dict[str, Any]) -> int:
        """
        Get the cluster ID for a user
        
        Args:
            user: User dictionary
            
        Returns:
            Cluster ID
        """
        if self.kmeans_model is None:
            raise ValueError("Model not trained. Call train_clusters first.")
        
        if user.get("account_type") == "traveler":
            features = self._extract_features_traveler(user)
        else:
            features = self._extract_features_provider(user)
        
        features_scaled = self.scaler.transform([features])
        return self.kmeans_model.predict(features_scaled)[0]
    
    def _check_date_compatibility(self, dates1: List[Dict], dates2: List[Dict]) -> Tuple[bool, List[str], float]:
        """
        Check if two users have overlapping travel dates
        
        Args:
            dates1: List of date ranges for user 1
            dates2: List of date ranges for user 2
            
        Returns:
            Tuple of (has_overlap, common_date_strings, overlap_score)
        """
        if not dates1 or not dates2:
            return False, [], 0.0
        
        common_dates = []
        total_overlap_days = 0
        
        for d1 in dates1:
            start1 = d1.get("start_date")
            end1 = d1.get("end_date")
            if not start1 or not end1:
                continue
            
            for d2 in dates2:
                start2 = d2.get("start_date")
                end2 = d2.get("end_date")
                if not start2 or not end2:
                    continue
                
                # Check for overlap
                latest_start = max(start1, start2)
                earliest_end = min(end1, end2)
                
                if latest_start <= earliest_end:
                    overlap_days = (earliest_end - latest_start).days + 1
                    total_overlap_days += overlap_days
                    common_dates.append(
                        f"{latest_start.strftime('%Y-%m-%d')} to {earliest_end.strftime('%Y-%m-%d')}"
                    )
        
        has_overlap = len(common_dates) > 0
        overlap_score = min(total_overlap_days / 7.0, 1.0)  # Normalize to week
        
        return has_overlap, common_dates, overlap_score
    
    def _check_language_compatibility(self, languages1: List[str], languages2: List[str]) -> Tuple[bool, List[str]]:
        """
        Check if two users share at least one common language
        
        Args:
            languages1: Languages of user 1
            languages2: Languages of user 2
            
        Returns:
            Tuple of (has_common, common_languages)
        """
        common = list(set(languages1) & set(languages2))
        return len(common) > 0, common
    
    def _check_budget_compatibility(self, budget1: Tuple[float, float], budget2: Tuple[float, float]) -> Tuple[bool, float]:
        """
        Check if two users have compatible budgets
        
        Args:
            budget1: (min, max) budget for user 1
            budget2: (min, max) budget for user 2
            
        Returns:
            Tuple of (is_compatible, compatibility_score)
        """
        min1, max1 = budget1
        min2, max2 = budget2
        
        # Check for overlap
        overlap_min = max(min1, min2)
        overlap_max = min(max1, max2)
        
        if overlap_min <= overlap_max:
            # Calculate overlap percentage
            range1 = max1 - min1 if max1 > min1 else 1
            range2 = max2 - min2 if max2 > min2 else 1
            overlap_range = overlap_max - overlap_min
            
            compatibility = min(overlap_range / range1, overlap_range / range2)
            return True, compatibility
        
        # Check if ranges are close
        gap = min(abs(max1 - min2), abs(max2 - min1))
        avg_range = (max1 - min1 + max2 - min2) / 2
        
        if gap / avg_range < 0.3:  # Within 30% is considered "close"
            return True, 0.7 - (gap / avg_range)
        
        return False, 0.0
    
    def _calculate_safety_score(self, user1: Dict, user2: Dict) -> float:
        """
        Calculate safety compatibility score
        
        Args:
            user1: First user
            user2: Second user
            
        Returns:
            Safety score (0-1)
        """
        score = 0.8  # Base safety score
        
        # Check if both are verified
        verified1 = user1.get("verified_flag", False) or user1.get("provider_profile", {}).get("verified_flag", False)
        verified2 = user2.get("verified_flag", False) or user2.get("provider_profile", {}).get("verified_flag", False)
        
        if verified1 and verified2:
            score += 0.2
        
        # Provider safety certification
        if user1.get("account_type") == "service_provider":
            if user1.get("provider_profile", {}).get("safety_certified", False):
                score += 0.1
        
        if user2.get("account_type") == "service_provider":
            if user2.get("provider_profile", {}).get("safety_certified", False):
                score += 0.1
        
        return min(score, 1.0)
    
    def _calculate_demographics_bonus(self, user1: Dict, user2: Dict) -> Tuple[float, List[str]]:
        """
        Calculate bonus score for demographic similarities
        
        Args:
            user1: First user
            user2: Second user
            
        Returns:
            Tuple of (bonus_score, reasons)
        """
        bonus = 0.0
        reasons = []
        
        profile1 = user1.get("profile", {})
        profile2 = user2.get("profile", {})
        
        # Same nationality bonus
        nationality1 = profile1.get("nationality", "")
        nationality2 = profile2.get("nationality", "")
        if nationality1 and nationality2 and nationality1 == nationality2:
            bonus += 0.15
            reasons.append(f"Same nationality ({nationality1})")
        
        # Similar age bonus (within 10 years)
        dob1 = profile1.get("date_of_birth")
        dob2 = profile2.get("date_of_birth")
        if dob1 and dob2:
            age1 = self._calculate_age(dob1)
            age2 = self._calculate_age(dob2)
            age_diff = abs(age1 - age2)
            if age_diff <= 10:
                bonus += 0.1
                reasons.append(f"Similar age (within {age_diff} years)")
        
        # Disability/accessibility match
        disabilities1 = [
            profile1.get("wheelchair_access", False),
            profile1.get("visual_assistance", False),
            profile1.get("hearing_assistance", False),
            profile1.get("mobility_support", False)
        ]
        disabilities2 = [
            profile2.get("wheelchair_access", False),
            profile2.get("visual_assistance", False),
            profile2.get("hearing_assistance", False),
            profile2.get("mobility_support", False)
        ]
        
        if any(disabilities1) and any(disabilities2):
            # Both have accessibility needs
            bonus += 0.2
            reasons.append("Both have accessibility needs")
        
        return bonus, reasons
    
    def _get_gender_priority_bonus(self, user1: Dict, user2: Dict) -> Tuple[float, str]:
        """
        Calculate gender matching priority bonus (women matched with women get priority)
        
        Args:
            user1: First user
            user2: Second user
            
        Returns:
            Tuple of (bonus_score, reason)
        """
        # Note: Gender field might not be in the schema, so we handle gracefully
        gender1 = user1.get("profile", {}).get("gender", "").lower()
        gender2 = user2.get("profile", {}).get("gender", "").lower()
        
        if gender1 == "female" and gender2 == "female":
            return 0.25, "Women-to-women matching priority"
        
        return 0.0, ""
    
    async def _get_llm_match_analysis(self, user1: Dict, user2: Dict, match_data: Dict) -> str:
        """
        Use LLM to provide personalized match explanation
        
        Args:
            user1: First user
            user2: Second user
            match_data: Calculated match data
            
        Returns:
            LLM-generated match explanation
        """
        if not OPENAI_AVAILABLE or not self.openai_api_key:
            return "LLM analysis not available (OpenAI not installed or no API key provided)"
        
        prompt = f"""
You are a travel matching assistant. Analyze this match and provide a brief, friendly explanation.

User 1: {user1.get('full_name', 'User 1')}
- Interests: {', '.join(user1.get('profile', {}).get('travel_interests', [])[:5])}
- Languages: {', '.join(user1.get('profile', {}).get('languages_spoken', []))}
- Budget: ${user1.get('profile', {}).get('typical_budget_min', 0)}-${user1.get('profile', {}).get('typical_budget_max', 0)}

User 2: {user2.get('full_name', 'User 2')}
- Interests: {', '.join(user2.get('profile', {}).get('travel_interests', [])[:5])}
- Languages: {', '.join(user2.get('profile', {}).get('languages_spoken', []))}
- Budget: ${user2.get('profile', {}).get('typical_budget_min', 0)}-${user2.get('profile', {}).get('typical_budget_max', 0)}

Common interests: {', '.join(match_data['common_interests'])}
Common languages: {', '.join(match_data['common_languages'])}
Match score: {match_data['match_score']:.2f}

Provide a 2-3 sentence friendly explanation of why they're a good match.
"""
        
        try:
            response = await openai.ChatCompletion.acreate(
                model="gpt-3.5-turbo",  # Free tier compatible
                messages=[
                    {"role": "system", "content": "You are a helpful travel matching assistant."},
                    {"role": "user", "content": prompt}
                ],
                max_tokens=150,
                temperature=0.7
            )
            return response.choices[0].message.content.strip()
        except Exception as e:
            return f"LLM analysis unavailable: {str(e)}"
    
    def find_matches(
        self,
        target_user: Dict[str, Any],
        candidate_users: List[Dict[str, Any]],
        travel_dates: Optional[List[Dict]] = None,
        top_k: int = 10,
        use_llm: bool = False
    ) -> List[MatchResult]:
        """
        Find best matches for a target user
        
        Args:
            target_user: The user to find matches for
            candidate_users: Pool of potential matches
            travel_dates: Optional travel date ranges for the target user
            top_k: Number of top matches to return
            use_llm: Whether to use LLM for match analysis
            
        Returns:
            List of MatchResult objects, sorted by score
        """
        if self.kmeans_model is None:
            raise ValueError("Model not trained. Call train_clusters first.")
        
        target_type = target_user.get("account_type")
        target_cluster = self._get_cluster(target_user)
        
        matches = []
        
        for candidate in candidate_users:
            # Skip self-matching
            if candidate.get("email") == target_user.get("email"):
                continue
            
            candidate_type = candidate.get("account_type")
            
            # Enforce matching rules:
            # 1. Service providers can only be matched TO travelers (not vice versa)
            # 2. Travelers can be matched with each other
            if target_type == "service_provider" and candidate_type == "traveler":
                # Providers cannot be matched TO travelers
                continue
            
            # Get candidate cluster
            candidate_cluster = self._get_cluster(candidate)
            
            # Base score from cluster similarity
            cluster_similarity = 1.0 if target_cluster == candidate_cluster else 0.5
            
            # Extract profiles
            target_profile = target_user.get("profile", {})
            candidate_profile = candidate.get("profile", {}) if candidate_type == "traveler" else candidate.get("provider_profile", {})
            
            # Check interests
            target_interests = target_profile.get("travel_interests", []) + target_profile.get("setup_interests", [])
            
            if candidate_type == "traveler":
                candidate_interests = candidate_profile.get("travel_interests", []) + candidate_profile.get("setup_interests", [])
            else:
                # For providers, infer interests from services
                candidate_interests = candidate_profile.get("services_offered", [])
            
            common_interests = list(set(target_interests) & set(candidate_interests))
            interest_score = min(len(common_interests) / 3.0, 1.0)  # Normalize
            
            # Check languages - MUST have at least 1 common language
            target_languages = target_profile.get("languages_spoken", [])
            candidate_languages = candidate_profile.get("languages", []) if candidate_type == "service_provider" else candidate_profile.get("languages_spoken", [])
            
            has_common_language, common_languages = self._check_language_compatibility(
                target_languages, candidate_languages
            )
            
            if not has_common_language:
                # No match if no common language
                continue
            
            language_score = min(len(common_languages) / 2.0, 1.0)
            
            # Check dates if provided
            date_compatible = True
            common_dates = []
            date_score = 0.5  # Neutral if no dates provided
            
            if travel_dates:
                candidate_dates = candidate.get("travel_dates", [])
                date_compatible, common_dates, date_score = self._check_date_compatibility(
                    travel_dates, candidate_dates
                )
                
                if not date_compatible and travel_dates and candidate_dates:
                    # No match if dates provided but don't overlap
                    continue
            
            # Check budget compatibility
            target_budget = (
                target_profile.get("typical_budget_min", 0),
                target_profile.get("typical_budget_max", 1000)
            )
            candidate_budget = (
                candidate_profile.get("price_range_min" if candidate_type == "service_provider" else "typical_budget_min", 0),
                candidate_profile.get("price_range_max" if candidate_type == "service_provider" else "typical_budget_max", 1000)
            )
            
            budget_compatible, budget_score = self._check_budget_compatibility(
                target_budget, candidate_budget
            )
            
            # Budget doesn't have to be identical, just close
            if budget_score < 0.3:
                budget_score = 0.3  # Minimum acceptable score
            
            # Calculate safety score
            safety_score = self._calculate_safety_score(target_user, candidate)
            
            # Demographics bonus
            demographics_bonus, demo_reasons = self._calculate_demographics_bonus(
                target_user, candidate
            )
            
            # Gender priority bonus (women-to-women)
            gender_bonus, gender_reason = self._get_gender_priority_bonus(
                target_user, candidate
            )
            
            # Calculate final match score
            match_score = (
                cluster_similarity * 0.15 +
                interest_score * 0.25 +
                language_score * 0.20 +
                date_score * 0.15 +
                budget_score * 0.10 +
                safety_score * 0.10 +
                demographics_bonus +
                gender_bonus
            )
            
            # Compile match reasons
            match_reasons = []
            if common_interests:
                match_reasons.append(f"Shared interests: {', '.join(common_interests[:3])}")
            if common_languages:
                match_reasons.append(f"Common languages: {', '.join(common_languages)}")
            if common_dates:
                match_reasons.append(f"Overlapping dates: {common_dates[0]}")
            if budget_compatible:
                match_reasons.append(f"Compatible budget range")
            if safety_score > 0.9:
                match_reasons.append("High safety compatibility")
            match_reasons.extend(demo_reasons)
            if gender_reason:
                match_reasons.append(gender_reason)
            
            # Create match result
            match = MatchResult(
                matched_user_id=candidate.get("email", ""),
                match_score=match_score,
                match_reasons=match_reasons,
                common_interests=common_interests,
                common_languages=common_languages,
                common_dates=common_dates,
                budget_compatibility=budget_score,
                safety_score=safety_score,
                demographics_bonus=demographics_bonus + gender_bonus,
                cluster_id=candidate_cluster
            )
            
            matches.append(match)
        
        # Sort by match score (descending)
        matches.sort(key=lambda x: x.match_score, reverse=True)
        
        # Return top K matches
        return matches[:top_k]
    
    def get_match_statistics(self, matches: List[MatchResult]) -> Dict[str, Any]:
        """
        Get statistics about the matches
        
        Args:
            matches: List of match results
            
        Returns:
            Dictionary of statistics
        """
        if not matches:
            return {
                "total_matches": 0,
                "average_score": 0.0,
                "top_score": 0.0,
                "common_interests": [],
                "common_languages": [],
                "cluster_distribution": {}
            }
        
        # Calculate statistics
        scores = [m.match_score for m in matches]
        all_interests = [interest for m in matches for interest in m.common_interests]
        all_languages = [lang for m in matches for lang in m.common_languages]
        clusters = [m.cluster_id for m in matches]
        
        interest_counts = Counter(all_interests)
        language_counts = Counter(all_languages)
        cluster_counts = Counter(clusters)
        
        return {
            "total_matches": len(matches),
            "average_score": np.mean(scores),
            "top_score": max(scores),
            "score_std": np.std(scores),
            "top_interests": interest_counts.most_common(5),
            "top_languages": language_counts.most_common(3),
            "cluster_distribution": dict(cluster_counts),
            "matches_above_80": sum(1 for s in scores if s >= 0.8),
            "matches_above_90": sum(1 for s in scores if s >= 0.9)
        }