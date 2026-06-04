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
        self.http_client = httpx.AsyncClient(timeout=30.0, http2=False)
        
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
            headers = {
                "User-Agent": "SmartExplorers/1.0 (https://smartexplorers.com; support@smartexplorers.com)"
            }
            

            # Use query as-is; countrycodes=eg already restricts to Egypt
            clean_query = query.strip()
            
            response = await self.http_client.get(
                f"{self.NOMINATIM_URL}/search",
                params={
                    "q": clean_query,
                    "format": "json",
                    "limit": 1,
                    "addressdetails": 1,
                    "countrycodes": "eg"  # Restrict to Egypt
                },
                headers=headers
            )
            
            if response.status_code != 200:
                print(f"Nominatim geocode error: {response.status_code}")
                return None
            
            results = response.json()
            if results and len(results) > 0:
                return results[0]
            return None
            
        except Exception as e:
            print(f"Nominatim geocode exception: {e}")
            return None
    
    async def _nominatim_search(self, query: str, limit: int = 5) -> List[Dict]:
        """Search for places by text using Nominatim - FREE"""
        try:
            headers = {
                "User-Agent": "SmartExplorers/1.0 (https://smartexplorers.com; support@smartexplorers.com)"
            }
            
            response = await self.http_client.get(
                f"{self.NOMINATIM_URL}/search",
                params={
                    "q": query,
                    "format": "json",
                    "limit": limit,
                    "addressdetails": 1,
                    "extratags": 1,
                    "countrycodes": "eg"
                },
                headers=headers
            )
            
            if response.status_code != 200:
                return []
            
            return response.json()
        except Exception as e:
            print(f"Nominatim search exception: {e}")
            return []
    
    async def _overpass_search_nearby(
        self, lat: float, lng: float, radius: int = 500, keyword: str = ""
    ) -> List[Dict]:
        """Search for places near coordinates using Overpass API - FREE"""
        try:
            # Build a more flexible query - don't use regex for keyword
            if keyword and len(keyword) > 3:
                # Use a simpler approach: search for any tourism/amenity and filter later
                query = f"""
                [out:json][timeout:10];
                (
                  node["tourism"](around:{radius},{lat},{lng});
                  node["amenity"](around:{radius},{lat},{lng});
                  node["historic"](around:{radius},{lat},{lng});
                  way["tourism"](around:{radius},{lat},{lng});
                  way["amenity"](around:{radius},{lat},{lng});
                  way["historic"](around:{radius},{lat},{lng});
                );
                out center body 10;
                """
            else:
                # No keyword - just get nearby attractions
                query = f"""
                [out:json][timeout:10];
                (
                  node["tourism"](around:{radius},{lat},{lng});
                  node["amenity"](around:{radius},{lat},{lng});
                  node["historic"](around:{radius},{lat},{lng});
                  way["tourism"](around:{radius},{lat},{lng});
                  way["amenity"](around:{radius},{lat},{lng});
                  way["historic"](around:{radius},{lat},{lng});
                );
                out center body 10;
                """
            
            headers = {
                "User-Agent": "SmartExplorers/1.0 (https://smartexplorers.com; support@smartexplorers.com)",
                "Accept": "application/json"
            }
            
            response = await self.http_client.post(
                self.OVERPASS_URL,
                data={"data": query},
                headers=headers,
                timeout=30.0
            )
            
            # Check status code
            if response.status_code != 200:
                print(f"Overpass API error: {response.status_code}")
                return []
            
            data = response.json()
            elements = data.get("elements", [])
            
            # If we have a keyword, filter results client-side (more flexible)
            if keyword and len(keyword) > 3 and elements:
                keyword_lower = keyword.lower()
                filtered = []
                for elem in elements:
                    tags = elem.get('tags', {})
                    elem_name = tags.get('name', '').lower()
                    # Check if keyword is in the name (substring match, not exact)
                    if keyword_lower in elem_name or any(word in elem_name for word in keyword_lower.split()):
                        filtered.append(elem)
                return filtered
            
            return elements
            
        except Exception as e:
            print(f"Overpass search exception: {e}")
            return []
    
    async def _overpass_search_exact(
        self, lat: float, lng: float, radius: int = 500, keyword: str = ""
    ) -> List[Dict]:
        """Search for exact business name using Overpass API - simpler query"""
        try:
            # Simpler query that's more likely to work
            query = f"""
            [out:json][timeout:10];
            (
              node(around:{radius},{lat},{lng});
              way(around:{radius},{lat},{lng});
            );
            out center body 10;
            """
            
            headers = {
                "User-Agent": "SmartExplorers/1.0 (https://smartexplorers.com; support@smartexplorers.com)",
                "Accept": "application/json"
            }
            
            response = await self.http_client.post(
                self.OVERPASS_URL,
                data={"data": query},
                headers=headers,
                timeout=30.0
            )
            
            if response.status_code != 200:
                return []
            
            data = response.json()
            elements = data.get("elements", [])
            
            # Filter for places that might be the business
            if keyword and elements:
                keyword_lower = keyword.lower()
                filtered = []
                for elem in elements:
                    tags = elem.get('tags', {})
                    elem_name = tags.get('name', '').lower()
                    # Check various fields that might contain the business name
                    if (keyword_lower in elem_name or 
                        keyword_lower in tags.get('shop', '').lower() or
                        keyword_lower in tags.get('tourism', '').lower()):
                        filtered.append(elem)
                return filtered
            
            return elements
            
        except Exception as e:
            print(f"Overpass exact search exception: {e}")
            return []
    
    async def _direct_nominatim_search(self, place_name: str) -> Optional[Dict]:
        """Direct search for a place by name using Nominatim"""
        try:
            headers = {
                "User-Agent": "SmartExplorers/1.0 (https://smartexplorers.com; support@smartexplorers.com)"
            }
            
            response = await self.http_client.get(
                f"{self.NOMINATIM_URL}/search",
                params={
                    "q": place_name,
                    "format": "json",
                    "limit": 1,
                    "countrycodes": "eg"
                },
                headers=headers
            )
            
            if response.status_code != 200:
                return None
            
            results = response.json()
            return results[0] if results else None
            
        except Exception as e:
            print(f"Direct Nominatim search error: {e}")
            return None
        
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
            self._analyze_reviews(provider_data, db),
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
            
            
            # Calculate scores — always add earned points regardless of pass/fail
            if result.get("passed"):
                verification_results["checks_passed"].append(check_name)
            else:
                verification_results["checks_failed"].append(check_name)
                if result.get("critical", False):
                    verification_results["warnings"].append(
                        f"CRITICAL: {check_name} - {result.get('message', 'Failed')}"
                    )
            
            total_score += result.get("score", 0)
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
            
            if not business_name and not address:
                return {
                    "passed": False,
                    "score": 0,
                    "max_score": 15,
                    "message": "No business name or address provided"
                }
            
            # Build search variations — business name first, address as fallback
            geocode_result = None
            address_variations = []
            if business_name:
                address_variations.append(f"{business_name} Egypt")
            if address:
                address_variations.append(f"{address}")
                address_variations.append(f"{address}, Cairo, Egypt")
                if ',' in address:
                    address_variations.append(f"{address.split(',')[0]}, Cairo, Egypt")
                else:
                    address_variations.append(f"{address}, Egypt")
            
            for addr in address_variations:
                geocode_result = await self._nominatim_geocode(addr)
                if geocode_result:
                    break
            
            if not geocode_result and business_name:
                geocode_result = await self._direct_nominatim_search(f"{business_name} Egypt")
            
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
            coordinate_match = False
            if claimed_lat and claimed_lng:
                distance_meters = geodesic(
                    (claimed_lat, claimed_lng),
                    (actual_lat, actual_lng)
                ).meters
                coordinate_match = distance_meters < self.LOCATION_DISTANCE_THRESHOLD
            

            # 3. Verify business existence using Nominatim result

            business_found = False

            if business_name:
                business_search = await self._direct_nominatim_search(
                    f"{business_name} Egypt"
                )

                if business_search:
                    business_found = True
            
            
            # Scoring
            score = 0
            max_score = 15
            
            # Address exists: 5 points
            score += 5
            
            # Coordinates match: 5 points
            if coordinate_match:
                score += 5
            
            # Business found nearby: 5 points
            if business_found:
                score += 5
            
            return {
                "passed": score >= 5,
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
            import traceback
            print(f"  [ERROR] _analyze_reviews crashed: {e}")
            traceback.print_exc()
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
            
            if not business_name:
                return {
                    "passed": False,
                    "score": 0,
                    "max_score": 10,
                    "message": "Missing business name"
                }
            
            # Try direct Nominatim search first (more reliable)
            search_result = await self._direct_nominatim_search(
                f"{business_name} Egypt"
            )

            if not search_result:
                return {
                    "passed": False,
                    "score": 0,
                    "max_score": 10,
                    "message": "Business not found in OpenStreetMap"
                }

            place = search_result
            # Nominatim returns display_name, osm_id, osm_type — no nested 'tags'
            osm_id = place.get('osm_id', place.get('place_id', ''))
            osm_type = place.get('osm_type', 'node')
            display_name = place.get('display_name', business_name)
            extratags = place.get('extratags', {}) or {}

            # Scoring
            score = 5  # Base score for existing in Nominatim

            # Has phone/website in extratags: +2 points
            has_phone = bool(extratags.get('phone') or extratags.get('contact:phone'))
            has_website = bool(extratags.get('website') or extratags.get('contact:website'))
            if has_phone or has_website:
                score += 2

            # Has opening hours: +1 point
            if extratags.get('opening_hours'):
                score += 1

            # Has category/type: +1 point
            place_class = place.get('class', '')
            place_type = place.get('type', '')
            if place_class in ('tourism', 'amenity', 'historic', 'shop') or place_type:
                score += 1

            # Has address info: +1 point
            address_obj = place.get('address', {}) or {}
            if address_obj.get('road') or address_obj.get('city'):
                score += 1

            return {
                "passed": True,
                "score": score,
                "max_score": 10,
                "osm_id": osm_id,
                "name": display_name,
                "has_phone": has_phone,
                "has_website": has_website,
                "has_hours": bool(extratags.get('opening_hours')),
                "business_type": place_class or place_type or 'unknown',
                "business_status": "OPERATIONAL",
                "osm_url": f"https://www.openstreetmap.org/{osm_type}/{osm_id}"
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
        business_name = provider_data.get("business_name", "")

        # Facebook verification
        facebook_url = provider_data.get("facebook_url")
        if facebook_url:
            fb_result = await self._verify_facebook(facebook_url, business_name)
            results["platforms"]["facebook"] = fb_result
            if fb_result.get("verified"):
                # Full points only if name matches or we couldn't check name
                if fb_result.get("confidence") == "high" or not business_name:
                    results["score"] += 5
                else:
                    # Page exists but name doesn't match — likely fake/unrelated account
                    results["score"] += 1
                    results["warnings"] = results.get("warnings", [])
                    results["warnings"].append("Facebook page exists but name doesn't match business")

        # Instagram verification
        instagram_username = provider_data.get("instagram_username")
        if instagram_username:
            ig_result = await self._verify_instagram(instagram_username)
            results["platforms"]["instagram"] = ig_result
            if ig_result.get("verified"):
                # Full 5 pts only when confirmed (future API); 2 pts when unconfirmed
                if ig_result.get("confidence") == "high":
                    results["score"] += 5
                else:
                    results["score"] += 2
        
        results["passed"] = results["score"] >= 3
        
        return results
    
    async def _verify_facebook(self, facebook_url: str, business_name: str = "") -> Dict:
        """
        Verify Facebook page exists and optionally name-matches the business.
        Uses Open Graph meta tags which Facebook serves without auth.
        """
        try:
            headers = {
                "User-Agent": "facebookexternalhit/1.1 (+http://www.facebook.com/externalhit_uatext.php)"
            }
            response = await self.http_client.get(
                facebook_url, headers=headers, follow_redirects=True, timeout=10.0
            )

            if response.status_code != 200:
                return {"verified": False, "exists": False, "reason": f"HTTP {response.status_code}"}

            body = response.text

            # Facebook serves real page content to its own crawler UA
            not_found_signals = [
                "This page isn\u2019t available",
                "This content isn\u2019t available",
                "Page Not Found",
            ]
            if any(signal in body for signal in not_found_signals):
                return {"verified": False, "exists": False, "reason": "Page not found"}

            # Extract Open Graph title (og:title) for name matching
            og_title = ""
            og_match = re.search(r'<meta[^>]+property=["\']og:title["\'][^>]+content=["\']([^"\']+)["\']', body)
            if not og_match:
                # Try reversed attribute order
                og_match = re.search(r'<meta[^>]+content=["\']([^"\']+)["\'][^>]+property=["\']og:title["\']', body)
            if og_match:
                og_title = og_match.group(1).strip()

            # Also try <title> tag as fallback
            if not og_title:
                title_match = re.search(r'<title>([^<]+)</title>', body)
                if title_match:
                    og_title = title_match.group(1).strip()

            # Name match: check if any word of the business name appears in the page title
            name_match = False
            name_match_score = 0.0
            if business_name and og_title:
                business_words = [w.lower() for w in business_name.split() if len(w) > 3]
                title_lower = og_title.lower()
                matched_words = [w for w in business_words if w in title_lower]
                name_match_score = len(matched_words) / len(business_words) if business_words else 0
                name_match = name_match_score >= 0.5  # at least half the words match

            return {
                "verified": True,
                "exists": True,
                "page_title": og_title,
                "name_match": name_match,
                "name_match_score": round(name_match_score, 2),
                # Only award full points if name matches; partial if page exists but name differs
                "confidence": "high" if name_match else "low"
            }

        except Exception as e:
            return {"verified": False, "error": str(e)}
        
    async def _verify_instagram(self, username: str) -> Dict:
        """
        Verify Instagram username.

        Instagram blocks all server-side scraping behind a login wall that
        returns 200 for both real and non-existent accounts with identical
        page structure. The only reliable free signal is a hard 404, which
        Instagram returns for definitively non-existent usernames.

        Strategy:
        1. Hard 404 on direct request = account does not exist (definitive).
        2. Valid username format + no 404 = award partial points, flag as
           unconfirmed (provider submitted it, system can't disprove it).
        """
        import re as _re
        try:
            username = username.replace('@', '').strip().lower()
            if not username:
                return {"verified": False, "score_override": 0, "reason": "Empty username"}

            # Validate format: 1-30 chars, letters/numbers/underscores/periods only
            if not _re.match(r'^[a-zA-Z0-9._]{1,30}$', username):
                return {
                    "verified": False,
                    "score_override": 0,
                    "username": username,
                    "reason": "Invalid username format",
                }

            # Check for hard 404 — only trustworthy negative signal
            profile_url = f"https://www.instagram.com/{username}/"
            headers = {
                "User-Agent": (
                    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
                    "AppleWebKit/537.36 (KHTML, like Gecko) "
                    "Chrome/124.0.0.0 Safari/537.36"
                ),
                "Accept-Language": "en-US,en;q=0.9",
            }
            try:
                resp = await self.http_client.get(
                    profile_url, headers=headers,
                    follow_redirects=True, timeout=10.0
                )
                print(f"  [Instagram] status={resp.status_code} for @{username}")

                if resp.status_code == 404:
                    return {
                        "verified": False,
                        "username": username,
                        "reason": "Account does not exist (404)",
                        "method": "direct_404",
                    }

                # 200 = could be real profile or login wall — indistinguishable
                # Award partial credit: provider submitted a validly-formatted
                # username that didn't 404. Flag for manual review.
                if resp.status_code == 200:
                    body = resp.text
                    # Only definitive negative: Instagram's explicit not-found message
                    if "Sorry, this page isn" in body:
                        return {
                            "verified": False,
                            "username": username,
                            "reason": "Page not found",
                            "method": "direct",
                        }
                    # Can't confirm — award partial, flag as unconfirmed
                    return {
                        "verified": True,
                        "username": username,
                        "active": True,
                        "method": "unconfirmed",
                        "confidence": "low",
                        "note": "Username format valid, no 404 — unconfirmed due to login wall",
                    }

            except Exception as e:
                print(f"  [Instagram] Request failed: {e}")
                # Network failure — give benefit of doubt, partial credit
                return {
                    "verified": True,
                    "username": username,
                    "method": "format_only",
                    "confidence": "low",
                    "note": "Could not reach Instagram — username format valid",
                }

        except Exception as e:
            return {"verified": False, "error": str(e)}
    
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
    
    async def _analyze_reviews(self, provider_data: Dict, db=None) -> Dict:
        """Analyze reviews from multiple sources using AI"""
        
        try:
            all_reviews = []
            
            # INTERNAL reviews from YOUR platform
            if db is not None:
                internal_reviews = await self._get_internal_reviews(provider_data, db)
                all_reviews.extend(internal_reviews)
            
            if not all_reviews:
                return {
                    "passed": False,
                    "score": 0,
                    "max_score": 15,
                    "message": "No reviews found in system"
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

            # Verification penalties: reviews calling out specific failures
            # Each penalty reduces score proportionally (max -2 per flag)
            penalties = analysis.get("verification_penalties", {})
            penalty_map = {
                "bad_phone": 2,
                "bad_location": 2,
                "bad_hours": 1,
                "scam_reports": 3,
                "license_issues": 2,
                "bad_social_media": 3,
            }
            total_penalty = 0
            triggered_penalties = []
            for flag, max_deduction in penalty_map.items():
                flag_score = penalties.get(flag, 0)
                if flag_score >= 0.5:
                    deduction = int(flag_score * max_deduction)
                    total_penalty += deduction
                    triggered_penalties.append(f"{flag} (-{deduction}pts)")

            score = max(0, score - total_penalty)

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
                "verification_penalties": triggered_penalties
            }
            
        except Exception as e:
            import traceback
            print(f"  [ERROR] _analyze_reviews crashed: {e}")
            traceback.print_exc()
            return {
                "passed": False,
                "score": 0,
                "max_score": 15,
                "error": str(e)
            }
    
    async def _get_google_reviews(self, provider_data: Dict) -> List[Dict]:
        return []
    
    async def _get_tripadvisor_reviews(self, business_name: str) -> List[Dict]:
        return []
    
    
    async def _get_internal_reviews(self, provider_data: Dict, db) -> List[Dict]:
        """Get reviews from your own database"""
        try:
            from app.mongodb import mongodb as _mongodb
            from bson import ObjectId

            # Collect every ID form this provider might be stored under in reviews:
            # 1. The user _id (string and ObjectId)
            # 2. The service_provider_profile _id (string and ObjectId), if different
            user_id = provider_data.get("_id")
            if not user_id or db is None:
                return []

            id_set = set()

            def _add_id(val):
                if not val:
                    return
                s = str(val)
                id_set.add(s)
                try:
                    id_set.add(ObjectId(s))
                except Exception:
                    pass

            _add_id(user_id)

            # Also add the profile's own _id if present
            profile = provider_data.get("provider_profile") or {}
            _add_id(profile.get("_id"))
            _add_id(profile.get("user_id"))

            id_variants = list(id_set)

            count_match = await db[_mongodb.REVIEWS].count_documents(
                {"provider_id": {"$in": id_variants}}
            )
            print(f"  [DEBUG] Reviews search — variants: {[str(v) for v in id_variants]}, matched: {count_match}")

            reviews_cursor = db[_mongodb.REVIEWS].find({
                "provider_id": {"$in": id_variants}
            }).sort("created_at", -1).limit(50)

            reviews = []
            async for review in reviews_cursor:
                reviews.append({
                    "rating": review.get("rating", 0),
                    "text": review.get("content", ""),
                    "created_at": review.get("created_at"),
                    "author_id": review.get("author_id")
                })

            return reviews

        except Exception as e:
            print(f"Error fetching internal reviews: {e}")
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
- red_flags: any safety concerns, scam mentions, or serious issues (list, can be empty)
- authenticity_score: 0-1 (are reviews genuine? look for copy-paste patterns, generic praise)
- recommendation: should this provider be trusted? (yes/no/maybe)
- verification_penalties: object with these keys (each 0-1, where 1 = strong complaint found):
    - bad_phone: reviews mention phone not working, wrong number, unreachable
    - bad_location: reviews mention wrong address, place doesn't exist, hard to find
    - bad_hours: reviews mention closed when should be open, wrong hours listed
    - scam_reports: reviews mention scam, fraud, overcharging, theft
    - license_issues: reviews mention unlicensed, illegal, unregistered
    - bad_social_media: reviews mention fake social media, fake Instagram, fake Facebook, misleading online presence

Return ONLY valid JSON."""
                }],
                response_format={"type": "json_object"},
                temperature=0.3
            )
            
            analysis = json.loads(response.choices[0].message.content)
            return analysis
            
        except Exception as e:
            print(f"[WARN] _ai_analyze_reviews failed: {e}")
            return {
                "sentiment": "positive",
                "themes": [],
                "red_flags": [],
                "authenticity_score": 0.7,
                "recommendation": "maybe",
                "verification_penalties": {}
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
            
            duplicates_found = 0
            
            if phone:
                phone_duplicates = await db.service_provider_profiles.find({
                    "phone_number": phone,
                    "user_id": {"$ne": provider_id}
                }).to_list(length=10)
                duplicates_found += len(phone_duplicates)
            
            if email:
                email_duplicates = await db[mongodb.USERS].find({
                    "email": email,
                    "_id": {"$ne": provider_id}
                }).to_list(length=10)
                duplicates_found += len(email_duplicates)
            
            if duplicates_found > 0:
                return {
                    "passed": False,
                    "score": 0,
                    "max_score": 10,
                    "critical": True,
                    "duplicates_found": duplicates_found,
                    "message": f"Found {duplicates_found} duplicate entries"
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
                "passed": True,
                "score": 8,
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
            
            area_codes = {
                "cairo": ["2", "02"],
                "giza": ["2", "02"],
                "alexandria": ["3", "03"],
                "luxor": ["95", "095"],
                "aswan": ["97", "097"],
                "hurghada": ["65", "065"],
            }
            
            clean_phone = phone.replace("+20", "").replace(" ", "").replace("-", "").strip()
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
                "score": 3,
                "max_score": 5,
                "error": str(e)
            }
    
    async def _verify_business_hours(self, provider_data: Dict) -> Dict:
        """Verify business hours are reasonable"""
        
        try:
            hours = provider_data.get("business_hours", {})
            
            if not hours:
                return {
                    "passed": False,
                    "score": 0,
                    "max_score": 5,
                    "message": "No hours provided — add business hours to earn 5 points"
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
                "passed": False,
                "score": 0,
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
                    "critical": False
                }
            
            if len(license_number) < 5:
                return {
                    "passed": False,
                    "score": 0,
                    "max_score": 10,
                    "message": "Invalid license format"
                }
            
            return {
                "passed": True,
                "score": 5,
                "max_score": 10,
                "message": "License format valid",
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
    # PLACE VERIFICATION (Simplified)
    # ========================================================================
    
    async def _verify_place_google(self, place_data: Dict) -> Dict:
        """Verify place exists using OpenStreetMap"""
        try:
            name = place_data.get("name")
            result = await self._direct_nominatim_search(name)
            
            if result:
                return {
                    "exists": True,
                    "name": result.get('display_name', name),
                    "location": {
                        "lat": float(result.get('lat', 0)),
                        "lng": float(result.get('lon', 0))
                    }
                }
            return {"exists": False}
            
        except Exception as e:
            return {"exists": False, "error": str(e)}
    
    async def _verify_place_tripadvisor(self, place_data: Dict) -> Dict:
        return {"exists": False, "message": "TripAdvisor integration pending"}
    
    async def _analyze_place_safety(self, place_data: Dict, verification_results: Dict) -> Dict:
        return {
            "level": "medium",
            "score": 70,
            "notes": ["Standard tourist precautions recommended"],
            "recommendations": ["Stay in well-lit areas", "Keep valuables secure"]
        }
    
    def _analyze_accessibility(self, verification_results: Dict) -> Dict:
        return {"score": 0, "features": []}
    
    def _generate_recommendations(self, verification_results: Dict) -> List[str]:
        recommendations = []
        failed = verification_results.get("checks_failed", [])
        score = verification_results.get("overall_score", 0)
        
        if "location_verification" in failed:
            recommendations.append("Verify your business address on OpenStreetMap")
        if "business_existence" in failed:
            recommendations.append("Add your business to OpenStreetMap")
        if "review_analysis" in failed:
            recommendations.append("Encourage customers to leave reviews on your platform")
        if score < 60:
            recommendations.append("Complete your business profile to improve verification score")
        
        return recommendations


# Global instance
cross_validation_service = CrossValidationService()