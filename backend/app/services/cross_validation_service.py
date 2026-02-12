"""
Cross-Validation Verification Service
Multi-source verification for places and service providers with fraud detection
"""
from typing import Dict, List, Any, Optional, Tuple
from datetime import datetime, timedelta
import asyncio
import httpx
from groq import Groq
from geopy.distance import geodesic
import json
import re
from app.config import settings


class CrossValidationService:
    """
    Multi-source verification service for places and providers
    
    Verification Sources (ALL FREE - no API keys needed for maps):
    1. OpenStreetMap / Nominatim (geocoding, location verification)
    2. Overpass API (POI/business existence checks)
    3. Social Media APIs (Facebook, Instagram)
    4. TripAdvisor API (reviews, ratings)
    5. Egyptian Tourism Authority (license verification)
    6. Cross-database checks (duplicates, fraud patterns)
    """
    
    OVERPASS_URL = "https://overpass-api.de/api/interpreter"
    NOMINATIM_URL = "https://nominatim.openstreetmap.org"
    
    def __init__(self):
        """Initialize API clients (all free, no credit card needed)"""
        # Groq for AI analysis
        self.groq_client = Groq(api_key=settings.GROQ_API_KEY)
        
        # HTTP client for API calls (Nominatim, Overpass, etc.)
        self.http_client = httpx.AsyncClient(timeout=30.0)
        
        # Verification thresholds
        self.LOCATION_DISTANCE_THRESHOLD = 500  # meters
        self.REVIEW_AUTHENTICITY_THRESHOLD = 0.7  # 0-1 scale
        self.SOCIAL_MEDIA_MIN_FOLLOWERS = 50
        self.MIN_REVIEW_COUNT = 3
        
        print("\u2713 CrossValidationService initialized (Nominatim + Overpass - FREE)")
    
    # ========================================================================
    # FREE API HELPERS (Nominatim + Overpass)
    # ========================================================================
    
    async def _nominatim_geocode(self, query: str) -> Optional[Dict]:
        """Geocode an address using Nominatim (OpenStreetMap) - FREE"""
        try:
            response = await self.http_client.get(
                f"{self.NOMINATIM_URL}/search",
                params={
                    "q": query,
                    "format": "json",
                    "limit": 1,
                    "addressdetails": 1
                },
                headers={"User-Agent": "SmartExplorers/1.0"}
            )
            results = response.json()
            return results[0] if results else None
        except Exception:
            return None
    
    async def _nominatim_search(self, query: str, limit: int = 5) -> List[Dict]:
        """Search for places by text using Nominatim - FREE"""
        try:
            response = await self.http_client.get(
                f"{self.NOMINATIM_URL}/search",
                params={
                    "q": query,
                    "format": "json",
                    "limit": limit,
                    "addressdetails": 1,
                    "extratags": 1
                },
                headers={"User-Agent": "SmartExplorers/1.0"}
            )
            return response.json()
        except Exception:
            return []
    
    async def _overpass_search_nearby(
        self, lat: float, lng: float, radius: int = 500, keyword: str = ""
    ) -> List[Dict]:
        """Search for places near coordinates using Overpass API - FREE"""
        try:
            name_filter = f'["name"~"{keyword}",i]' if keyword else '["name"]'
            query = f"""
[out:json][timeout:10];
(
  node["tourism"]{name_filter}(around:{radius},{lat},{lng});
  node["amenity"]{name_filter}(around:{radius},{lat},{lng});
  node["shop"]{name_filter}(around:{radius},{lat},{lng});
  way["tourism"]{name_filter}(around:{radius},{lat},{lng});
  way["amenity"]{name_filter}(around:{radius},{lat},{lng});
);
out center body;"""
            response = await self.http_client.post(
                self.OVERPASS_URL,
                data={"data": query},
                timeout=15.0
            )
            data = response.json()
            return data.get("elements", [])
        except Exception:
            return []
        
    async def verify_service_provider(
        self,
        provider_data: Dict[str, Any],
        db
    ) -> Dict[str, Any]:
        """
        Complete multi-source verification for service provider
        
        Args:
            provider_data: Provider information dict
            db: MongoDB database instance
            
        Returns:
            Comprehensive verification report with score and details
        """
        
        verification_results = {
            "provider_id": provider_data.get("_id"),
            "timestamp": datetime.utcnow().isoformat(),
            "overall_score": 0.0,
            "verification_level": "pending",
            "checks_passed": [],
            "checks_failed": [],
            "warnings": [],
            "recommendations": [],
            "detailed_results": {}
        }
        
        # Run all verification checks in parallel
        tasks = [
            self._verify_location(provider_data),
            self._verify_business_exists(provider_data),
            self._verify_social_media(provider_data),
            self._analyze_reviews(provider_data),
            self._check_duplicates(provider_data, db),
            self._verify_phone_location_match(provider_data),
            self._verify_business_hours(provider_data),
            self._check_license_validity(provider_data),
        ]
        
        results = await asyncio.gather(*tasks, return_exceptions=True)
        
        # Process results
        checks = [
            "location_verification",
            "business_existence",
            "social_media",
            "review_analysis",
            "duplicate_check",
            "phone_location",
            "business_hours",
            "license_validity"
        ]
        
        total_score = 0
        max_score = 0
        
        for i, check_name in enumerate(checks):
            result = results[i]
            
            if isinstance(result, Exception):
                verification_results["warnings"].append(
                    f"{check_name}: {str(result)}"
                )
                verification_results["detailed_results"][check_name] = {
                    "status": "error",
                    "error": str(result)
                }
                continue
            
            verification_results["detailed_results"][check_name] = result
            
            # Calculate scores
            if result.get("passed"):
                verification_results["checks_passed"].append(check_name)
                total_score += result.get("score", 0)
            else:
                verification_results["checks_failed"].append(check_name)
                if result.get("critical", False):
                    verification_results["warnings"].append(
                        f"CRITICAL: {check_name} - {result.get('message', 'Failed')}"
                    )
            
            max_score += result.get("max_score", 10)
        
        # Calculate overall score (0-100)
        if max_score > 0:
            verification_results["overall_score"] = (total_score / max_score) * 100
        
        # Determine verification level
        score = verification_results["overall_score"]
        if score >= 80:
            verification_results["verification_level"] = "verified"
            verification_results["badge"] = "green_verified"
        elif score >= 60:
            verification_results["verification_level"] = "partially_verified"
            verification_results["badge"] = "yellow_partial"
        else:
            verification_results["verification_level"] = "unverified"
            verification_results["badge"] = "none"
        
        # Generate recommendations
        verification_results["recommendations"] = self._generate_recommendations(
            verification_results
        )
        
        return verification_results
    
    async def verify_place(
        self,
        place_data: Dict[str, Any]
    ) -> Dict[str, Any]:
        """
        Verify a place/location across multiple sources
        
        Args:
            place_data: Place information (name, address, coordinates)
            
        Returns:
            Place verification report
        """
        
        verification_results = {
            "place_name": place_data.get("name"),
            "timestamp": datetime.utcnow().isoformat(),
            "exists": False,
            "verified": False,
            "safety_level": "unknown",
            "accessibility_score": 0.0,
            "sources": {}
        }
        
        # OpenStreetMap verification (FREE)
        google_result = await self._verify_place_google(place_data)
        verification_results["sources"]["openstreetmap"] = google_result
        
        if google_result.get("exists"):
            verification_results["exists"] = True
        
        # TripAdvisor verification (if available)
        tripadvisor_result = await self._verify_place_tripadvisor(place_data)
        verification_results["sources"]["tripadvisor"] = tripadvisor_result
        
        # Cross-reference results
        if google_result.get("exists") and tripadvisor_result.get("exists"):
            # Compare ratings and details
            verification_results["verified"] = True
            verification_results["confidence"] = "high"
        elif google_result.get("exists"):
            verification_results["verified"] = True
            verification_results["confidence"] = "medium"
        
        # Safety analysis
        safety_analysis = await self._analyze_place_safety(place_data, verification_results)
        verification_results["safety_level"] = safety_analysis.get("level", "unknown")
        verification_results["safety_score"] = safety_analysis.get("score", 0.0)
        verification_results["safety_notes"] = safety_analysis.get("notes", [])
        
        # Accessibility analysis
        accessibility = self._analyze_accessibility(verification_results)
        verification_results["accessibility_score"] = accessibility.get("score", 0.0)
        verification_results["accessibility_features"] = accessibility.get("features", [])
        
        return verification_results
    
    # ========================================================================
    # LOCATION VERIFICATION
    # ========================================================================
    
    async def _verify_location(self, provider_data: Dict) -> Dict:
        """Verify business location exists and coordinates are accurate using OpenStreetMap"""
        
        try:
            business_name = provider_data.get("business_name", "")
            address = provider_data.get("address", "")
            claimed_lat = provider_data.get("latitude")
            claimed_lng = provider_data.get("longitude")
            
            if not address:
                return {
                    "passed": False,
                    "score": 0,
                    "max_score": 15,
                    "message": "No address provided"
                }
            
            # 1. Geocode the address using Nominatim (FREE)
            geocode_result = await self._nominatim_geocode(f"{address}, Egypt")
            
            if not geocode_result:
                return {
                    "passed": False,
                    "score": 0,
                    "max_score": 15,
                    "message": "Address not found via OpenStreetMap",
                    "critical": True
                }
            
            actual_lat = float(geocode_result['lat'])
            actual_lng = float(geocode_result['lon'])
            
            # 2. Calculate distance if coordinates provided
            distance_meters = 0
            if claimed_lat and claimed_lng:
                distance_meters = geodesic(
                    (claimed_lat, claimed_lng),
                    (actual_lat, actual_lng)
                ).meters
            
            # 3. Search for business by name near location using Overpass API (FREE)
            nearby_places = await self._overpass_search_nearby(
                actual_lat, actual_lng, radius=1000, keyword=business_name
            )
            business_found = len(nearby_places) > 0
            
            # Scoring
            score = 0
            max_score = 15
            
            # Address exists: 5 points
            score += 5
            
            # Coordinates match: 5 points
            if distance_meters < self.LOCATION_DISTANCE_THRESHOLD:
                score += 5
                coordinate_match = True
            else:
                coordinate_match = False
            
            # Business found nearby: 5 points
            if business_found:
                score += 5
            
            return {
                "passed": score >= 10,  # Need at least 10/15
                "score": score,
                "max_score": max_score,
                "distance_meters": round(distance_meters, 2),
                "coordinate_match": coordinate_match,
                "business_found_nearby": business_found,
                "actual_location": {
                    "lat": actual_lat,
                    "lng": actual_lng
                },
                "confidence": "high" if score >= 12 else "medium" if score >= 8 else "low"
            }
            
        except Exception as e:
            return {
                "passed": False,
                "score": 0,
                "max_score": 15,
                "error": str(e)
            }
    
    async def _verify_business_exists(self, provider_data: Dict) -> Dict:
        """Verify business exists on OpenStreetMap via Overpass API"""
        
        try:
            business_name = provider_data.get("business_name", "")
            latitude = provider_data.get("latitude")
            longitude = provider_data.get("longitude")
            
            if not (business_name and latitude and longitude):
                return {
                    "passed": False,
                    "score": 0,
                    "max_score": 10,
                    "message": "Missing business info"
                }
            
            # Search Overpass API for nearby businesses (FREE)
            nearby_places = await self._overpass_search_nearby(
                latitude, longitude, radius=500, keyword=business_name
            )
            
            if not nearby_places:
                # Fallback: Nominatim text search
                search_results = await self._nominatim_search(
                    f"{business_name} Egypt", limit=3
                )
                if not search_results:
                    return {
                        "passed": False,
                        "score": 0,
                        "max_score": 10,
                        "message": "Business not found on OpenStreetMap",
                        "critical": True
                    }
                nearby_places = search_results
            
            place = nearby_places[0]
            tags = place.get('tags', {})
            
            # Scoring
            score = 5  # Base score for existing
            
            # Has contact info: +2 points
            has_phone = bool(tags.get('phone') or tags.get('contact:phone'))
            has_website = bool(tags.get('website') or tags.get('contact:website'))
            if has_phone or has_website:
                score += 2
            
            # Has opening hours: +1 point
            if tags.get('opening_hours'):
                score += 1
            
            # Has category/type: +1 point
            if tags.get('tourism') or tags.get('amenity') or tags.get('shop'):
                score += 1
            
            # Has address info: +1 point
            if tags.get('addr:street') or tags.get('addr:city'):
                score += 1
            
            osm_id = place.get('id', place.get('osm_id', ''))
            
            return {
                "passed": True,
                "score": score,
                "max_score": 10,
                "osm_id": osm_id,
                "name": tags.get('name', place.get('display_name', business_name)),
                "has_phone": has_phone,
                "has_website": has_website,
                "has_hours": bool(tags.get('opening_hours')),
                "business_type": tags.get('tourism') or tags.get('amenity') or tags.get('shop', 'unknown'),
                "business_status": "OPERATIONAL",
                "osm_url": f"https://www.openstreetmap.org/node/{osm_id}"
            }
            
        except Exception as e:
            return {
                "passed": False,
                "score": 0,
                "max_score": 10,
                "error": str(e)
            }
    
    # ========================================================================
    # SOCIAL MEDIA VERIFICATION
    # ========================================================================
    
    async def _verify_social_media(self, provider_data: Dict) -> Dict:
        """Verify social media presence"""
        
        results = {
            "passed": False,
            "score": 0,
            "max_score": 10,
            "platforms": {}
        }
        
        # Facebook verification
        facebook_url = provider_data.get("facebook_url")
        if facebook_url:
            fb_result = await self._verify_facebook(facebook_url)
            results["platforms"]["facebook"] = fb_result
            if fb_result.get("verified"):
                results["score"] += 5
        
        # Instagram verification
        instagram_username = provider_data.get("instagram_username")
        if instagram_username:
            ig_result = await self._verify_instagram(instagram_username)
            results["platforms"]["instagram"] = ig_result
            if ig_result.get("verified"):
                results["score"] += 5
        
        results["passed"] = results["score"] >= 3  # At least one platform
        
        return results
    
    async def _verify_facebook(self, facebook_url: str) -> Dict:
        """Verify Facebook page exists and is active"""
        
        try:
            # Extract page ID from URL
            page_id = self._extract_facebook_page_id(facebook_url)
            
            if not page_id:
                return {
                    "verified": False,
                    "error": "Invalid Facebook URL"
                }
            
            # Facebook Graph API call
            # Note: Requires Facebook App access token
            if not hasattr(settings, 'FACEBOOK_ACCESS_TOKEN') or not settings.FACEBOOK_ACCESS_TOKEN:
                # Fallback: Web scraping check
                try:
                    response = await self.http_client.get(facebook_url)
                    exists = response.status_code == 200
                except Exception:
                    exists = False
                
                return {
                    "verified": exists,
                    "page_id": page_id,
                    "method": "web_check",
                    "exists": exists
                }
            
            # Use Graph API (preferred)
            api_url = f"https://graph.facebook.com/v18.0/{page_id}"
            response = await self.http_client.get(
                api_url,
                params={
                    "fields": "name,verification_status,fan_count,rating_count,about",
                    "access_token": settings.FACEBOOK_ACCESS_TOKEN
                }
            )
            
            if response.status_code == 200:
                data = response.json()
                
                return {
                    "verified": True,
                    "page_id": page_id,
                    "name": data.get('name'),
                    "followers": data.get('fan_count', 0),
                    "rating_count": data.get('rating_count', 0),
                    "is_verified": data.get('verification_status') == 'verified',
                    "active": data.get('fan_count', 0) >= self.SOCIAL_MEDIA_MIN_FOLLOWERS
                }
            else:
                return {
                    "verified": False,
                    "error": "Page not found or private"
                }
                
        except Exception as e:
            return {
                "verified": False,
                "error": str(e)
            }
    
    async def _verify_instagram(self, username: str) -> Dict:
        """Verify Instagram account exists"""
        
        try:
            # Clean username
            username = username.replace('@', '').strip()
            
            # Check if profile exists (web check)
            profile_url = f"https://www.instagram.com/{username}/"
            
            try:
                response = await self.http_client.get(
                    profile_url,
                    headers={
                        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
                    }
                )
                exists = response.status_code == 200
            except Exception:
                exists = False
            
            return {
                "verified": exists,
                "username": username,
                "profile_url": profile_url,
                "active": exists
            }
            
        except Exception as e:
            return {
                "verified": False,
                "error": str(e)
            }
    
    def _extract_facebook_page_id(self, url: str) -> Optional[str]:
        """Extract Facebook page ID from URL"""
        
        patterns = [
            r'facebook\.com/([^/\?]+)',
            r'facebook\.com/pages/[^/]+/(\d+)',
            r'profile\.php\?id=(\d+)'
        ]
        
        for pattern in patterns:
            match = re.search(pattern, url)
            if match:
                return match.group(1)
        
        return None
    
    # ========================================================================
    # REVIEW ANALYSIS
    # ========================================================================
    
    async def _analyze_reviews(self, provider_data: Dict) -> Dict:
        """Analyze reviews from multiple sources using AI"""
        
        try:
            business_name = provider_data.get("business_name", "")
            
            # Collect reviews from multiple sources
            all_reviews = []
            
            # Google reviews
            google_reviews = await self._get_google_reviews(provider_data)
            all_reviews.extend(google_reviews)
            
            # TripAdvisor reviews (if available)
            ta_reviews = await self._get_tripadvisor_reviews(business_name)
            all_reviews.extend(ta_reviews)
            
            if not all_reviews:
                return {
                    "passed": False,
                    "score": 0,
                    "max_score": 15,
                    "message": "No reviews found"
                }
            
            # Analyze with AI
            analysis = await self._ai_analyze_reviews(all_reviews)
            
            # Calculate score
            score = 0
            max_score = 15
            
            # Review count: 0-5 points
            review_count = len(all_reviews)
            if review_count >= 50:
                score += 5
            elif review_count >= 20:
                score += 4
            elif review_count >= 10:
                score += 3
            elif review_count >= 5:
                score += 2
            elif review_count >= 3:
                score += 1
            
            # Sentiment: 0-5 points
            sentiment = analysis.get("sentiment", "neutral")
            if sentiment == "positive":
                score += 5
            elif sentiment == "neutral":
                score += 3
            elif sentiment == "mixed":
                score += 2
            
            # Authenticity: 0-5 points
            authenticity_score = analysis.get("authenticity_score", 0.5)
            score += int(authenticity_score * 5)
            
            return {
                "passed": score >= 8,
                "score": score,
                "max_score": max_score,
                "review_count": review_count,
                "average_rating": sum(r['rating'] for r in all_reviews) / len(all_reviews),
                "sentiment": sentiment,
                "authenticity_score": authenticity_score,
                "common_themes": analysis.get("themes", []),
                "red_flags": analysis.get("red_flags", []),
                "sources": {
                    "google": len(google_reviews),
                    "tripadvisor": len(ta_reviews)
                }
            }
            
        except Exception as e:
            return {
                "passed": False,
                "score": 0,
                "max_score": 15,
                "error": str(e)
            }
    
    async def _get_google_reviews(self, provider_data: Dict) -> List[Dict]:
        """Get reviews for a business.
        Note: Free APIs (Nominatim/Overpass) do not provide user reviews.
        Reviews come from TripAdvisor integration when available."""
        # Free map APIs don't include user reviews
        return []
    
    async def _get_tripadvisor_reviews(self, business_name: str) -> List[Dict]:
        """Get TripAdvisor reviews (requires API key)"""
        # TripAdvisor Content API integration pending
        return []
    
    async def _ai_analyze_reviews(self, reviews: List[Dict]) -> Dict:
        """Use Groq to analyze review sentiment and authenticity"""
        
        try:
            reviews_string = "\n\n".join([
                f"Review {i+1} ({r['rating']}/5): {r['text']}"
                for i, r in enumerate(reviews[:20])
            ])
            
            response = self.groq_client.chat.completions.create(
                model=settings.GROQ_MODEL,
                messages=[{
                    "role": "user",
                    "content": f"""Analyze these reviews for a tour guide/tourism service in Egypt:

{reviews_string}

Provide JSON with:
- sentiment: overall sentiment (positive/neutral/negative/mixed)
- themes: list of main topics mentioned (max 5)
- red_flags: any safety concerns, scam mentions, or serious issues (list)
- authenticity_score: 0-1 (are reviews genuine? look for patterns, similar wording, suspicious timing)
- recommendation: should this provider be trusted? (yes/no/maybe)

Return ONLY valid JSON."""
                }],
                response_format={"type": "json_object"},
                temperature=0.3
            )
            
            analysis = json.loads(response.choices[0].message.content)
            return analysis
            
        except Exception as e:
            return {
                "sentiment": "neutral",
                "themes": [],
                "red_flags": [],
                "authenticity_score": 0.5,
                "recommendation": "maybe",
                "error": str(e)
            }
    
    # ========================================================================
    # CROSS-DATABASE CHECKS
    # ========================================================================
    
    async def _check_duplicates(self, provider_data: Dict, db) -> Dict:
        """Check for duplicate providers in database"""
        
        try:
            provider_id = provider_data.get("_id")
            phone = provider_data.get("phone")
            email = provider_data.get("email")
            license_number = provider_data.get("business_license")
            national_id = provider_data.get("national_id")
            
            duplicates = {
                "phone": [],
                "email": [],
                "license": [],
                "national_id": []
            }
            
            if phone:
                phone_duplicates = await db.service_provider_profiles.find({
                    "phone": phone,
                    "_id": {"$ne": provider_id}
                }).to_list(length=10)
                duplicates["phone"] = [str(d["_id"]) for d in phone_duplicates]
            
            if email:
                email_duplicates = await db.service_provider_profiles.find({
                    "email": email,
                    "_id": {"$ne": provider_id}
                }).to_list(length=10)
                duplicates["email"] = [str(d["_id"]) for d in email_duplicates]
            
            if license_number:
                license_duplicates = await db.service_provider_profiles.find({
                    "business_license": license_number,
                    "_id": {"$ne": provider_id}
                }).to_list(length=10)
                duplicates["license"] = [str(d["_id"]) for d in license_duplicates]
            
            if national_id:
                id_duplicates = await db.service_provider_profiles.find({
                    "national_id": national_id,
                    "_id": {"$ne": provider_id}
                }).to_list(length=10)
                duplicates["national_id"] = [str(d["_id"]) for d in id_duplicates]
            
            total_duplicates = sum(len(v) for v in duplicates.values())
            
            if total_duplicates > 0:
                return {
                    "passed": False,
                    "score": 0,
                    "max_score": 10,
                    "critical": True,
                    "duplicates_found": total_duplicates,
                    "duplicate_details": duplicates,
                    "message": f"Found {total_duplicates} duplicate entries"
                }
            else:
                return {
                    "passed": True,
                    "score": 10,
                    "max_score": 10,
                    "duplicates_found": 0,
                    "message": "No duplicates found"
                }
                
        except Exception as e:
            return {
                "passed": False,
                "score": 0,
                "max_score": 10,
                "error": str(e)
            }
    
    async def _verify_phone_location_match(self, provider_data: Dict) -> Dict:
        """Verify phone area code matches claimed location"""
        
        try:
            phone = provider_data.get("phone", "")
            city = provider_data.get("city", "").lower()
            
            if not phone or not city:
                return {
                    "passed": True,
                    "score": 5,
                    "max_score": 5,
                    "message": "Skipped - missing data"
                }
            
            # Egyptian phone area codes
            area_codes = {
                "cairo": ["2"],
                "giza": ["2"],
                "alexandria": ["3"],
                "port said": ["66"],
                "suez": ["62"],
                "luxor": ["95"],
                "aswan": ["97"],
                "hurghada": ["65"],
                "sharm el sheikh": ["69"],
                "dahab": ["69"],
                "marsa alam": ["65"]
            }
            
            clean_phone = phone.replace("+20", "").replace(" ", "").replace("-", "")
            phone_area = clean_phone[0] if clean_phone else ""
            if len(clean_phone) > 1 and clean_phone[0] in ['6', '9']:
                phone_area = clean_phone[:2]
            
            expected_codes = area_codes.get(city, [])
            matches = phone_area in expected_codes if expected_codes else True
            
            return {
                "passed": matches or not expected_codes,
                "score": 5 if matches or not expected_codes else 0,
                "max_score": 5,
                "phone_area_code": phone_area,
                "expected_codes": expected_codes,
                "matches": matches
            }
            
        except Exception as e:
            return {
                "passed": True,
                "score": 2,
                "max_score": 5,
                "error": str(e)
            }
    
    async def _verify_business_hours(self, provider_data: Dict) -> Dict:
        """Verify business hours are reasonable"""
        
        try:
            hours = provider_data.get("business_hours", {})
            
            if not hours:
                return {
                    "passed": True,
                    "score": 3,
                    "max_score": 5,
                    "message": "No hours provided"
                }
            
            issues = []
            
            for day, times in hours.items():
                if not times:
                    continue
                
                open_time = times.get("open")
                close_time = times.get("close")
                
                if open_time and close_time:
                    try:
                        open_hour = int(open_time.split(":")[0])
                        close_hour = int(close_time.split(":")[0])
                        
                        if open_hour < 5 or open_hour > 12:
                            issues.append(f"{day}: Unusual opening time {open_time}")
                        
                        if close_hour < 16 or close_hour > 24:
                            issues.append(f"{day}: Unusual closing time {close_time}")
                        
                        if close_hour <= open_hour:
                            close_hour += 24
                        
                        duration = close_hour - open_hour
                        if duration > 16:
                            issues.append(f"{day}: Very long hours ({duration}h)")
                        elif duration < 2:
                            issues.append(f"{day}: Very short hours ({duration}h)")
                    except Exception:
                        pass
            
            score = 5 if len(issues) == 0 else max(0, 5 - len(issues))
            
            return {
                "passed": len(issues) < 3,
                "score": score,
                "max_score": 5,
                "issues": issues
            }
            
        except Exception as e:
            return {
                "passed": True,
                "score": 3,
                "max_score": 5,
                "error": str(e)
            }
    
    async def _check_license_validity(self, provider_data: Dict) -> Dict:
        """Verify business license format and validity"""
        
        try:
            license_number = provider_data.get("business_license")
            
            if not license_number:
                return {
                    "passed": False,
                    "score": 0,
                    "max_score": 10,
                    "message": "No license number provided",
                    "critical": True
                }
            
            if len(license_number) < 5:
                return {
                    "passed": False,
                    "score": 0,
                    "max_score": 10,
                    "message": "Invalid license format"
                }
            
            # Format valid - API verification with Egyptian Tourism Authority pending
            return {
                "passed": True,
                "score": 5,
                "max_score": 10,
                "message": "License format valid - API verification pending",
                "license_number": license_number
            }
            
        except Exception as e:
            return {
                "passed": False,
                "score": 0,
                "max_score": 10,
                "error": str(e)
            }
    
    # ========================================================================
    # PLACE VERIFICATION
    # ========================================================================
    
    async def _verify_place_google(self, place_data: Dict) -> Dict:
        """Verify place exists using OpenStreetMap (Nominatim + Overpass) - FREE"""
        
        try:
            name = place_data.get("name")
            address = place_data.get("address")
            latitude = place_data.get("latitude")
            longitude = place_data.get("longitude")
            
            # Search for place using Overpass if we have coordinates
            if latitude and longitude:
                nearby = await self._overpass_search_nearby(
                    latitude, longitude, radius=500, keyword=name
                )
                if nearby:
                    place = nearby[0]
                    tags = place.get('tags', {})
                    loc = {
                        "lat": place.get('lat', place.get('center', {}).get('lat', latitude)),
                        "lng": place.get('lon', place.get('center', {}).get('lon', longitude))
                    }
                    return {
                        "exists": True,
                        "osm_id": place.get('id'),
                        "name": tags.get('name', name),
                        "formatted_address": tags.get('addr:street', address or ''),
                        "types": [v for k, v in tags.items() if k in ('tourism', 'amenity', 'shop', 'historic')],
                        "business_status": "OPERATIONAL",
                        "wheelchair_accessible": tags.get('wheelchair') == 'yes',
                        "location": loc
                    }
            
            # Fallback: Nominatim text search
            query = f"{name} {address}" if address else f"{name} Egypt"
            results = await self._nominatim_search(query, limit=3)
            
            if not results:
                return {"exists": False}
            
            place = results[0]
            return {
                "exists": True,
                "osm_id": place.get('osm_id'),
                "name": place.get('display_name', name),
                "formatted_address": place.get('display_name', ''),
                "types": [place.get('type', 'unknown')],
                "business_status": "OPERATIONAL",
                "wheelchair_accessible": False,
                "location": {
                    "lat": float(place.get('lat', 0)),
                    "lng": float(place.get('lon', 0))
                }
            }
            
        except Exception as e:
            return {"exists": False, "error": str(e)}
    
    async def _verify_place_tripadvisor(self, place_data: Dict) -> Dict:
        """Verify place on TripAdvisor"""
        # TripAdvisor Content API integration pending
        return {"exists": False, "message": "TripAdvisor integration pending"}
    
    async def _analyze_place_safety(
        self,
        place_data: Dict,
        verification_results: Dict
    ) -> Dict:
        """Analyze place safety using AI"""
        
        try:
            google_data = verification_results.get('sources', {}).get('openstreetmap', {})
            
            info = f"""
            Place: {place_data.get('name')}
            Location: {place_data.get('address', 'Egypt')}
            Type: {place_data.get('category', 'unknown')}
            Business Status: {google_data.get('business_status', 'N/A')}
            """
            
            response = self.groq_client.chat.completions.create(
                model=settings.GROQ_MODEL,
                messages=[{
                    "role": "user",
                    "content": f"""Analyze the safety of this location in Egypt for tourists:

{info}

Consider:
- Tourist safety (scams, harassment, theft)
- Accessibility for women travelers
- Accessibility for people with disabilities
- Current security situation
- Common safety concerns in the area

Provide JSON with:
- level: safety level (high/medium/low)
- score: safety score 0-100
- notes: list of safety considerations (max 5 points)
- recommendations: safety tips for visitors (max 3)

Return ONLY valid JSON."""
                }],
                response_format={"type": "json_object"},
                temperature=0.3
            )
            
            analysis = json.loads(response.choices[0].message.content)
            return analysis
            
        except Exception as e:
            return {
                "level": "unknown",
                "score": 50,
                "notes": [f"Analysis error: {str(e)}"],
                "recommendations": ["Exercise normal precautions"]
            }
    
    def _analyze_accessibility(self, verification_results: Dict) -> Dict:
        """Analyze accessibility features"""
        
        features = []
        score = 0
        
        google_data = verification_results.get('sources', {}).get('openstreetmap', {})
        
        if google_data.get('wheelchair_accessible'):
            features.append("Wheelchair accessible entrance")
            score += 30
        
        return {
            "score": score,
            "features": features
        }
    
    def _generate_recommendations(self, verification_results: Dict) -> List[str]:
        """Generate recommendations based on verification results"""
        
        recommendations = []
        failed = verification_results["checks_failed"]
        score = verification_results["overall_score"]
        
        if "location_verification" in failed:
            recommendations.append(
                "Verify your business address and update coordinates to match actual location"
            )
        
        if "business_existence" in failed:
            recommendations.append(
                "Claim your business on OpenStreetMap to improve verification"
            )
        
        if "social_media" in failed:
            recommendations.append(
                "Create and maintain active social media profiles to build trust"
            )
        
        if "review_analysis" in failed:
            recommendations.append(
                "Encourage satisfied customers to leave reviews on Google and TripAdvisor"
            )
        
        if "duplicate_check" in failed:
            recommendations.append(
                "CRITICAL: Duplicate account detected - contact support immediately"
            )
        
        if "license_validity" in failed:
            recommendations.append(
                "Provide valid business license or tourism authority certification"
            )
        
        if score < 60:
            recommendations.append(
                "Complete basic verification requirements to improve trust score"
            )
        
        return recommendations


# Global instance
cross_validation_service = CrossValidationService()
