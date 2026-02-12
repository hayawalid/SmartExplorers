"""
Itinerary Place Verifier - "Verify, Verify, Verify" Architecture
Verifies every place and activity in a generated itinerary using
OpenStreetMap (Nominatim + Overpass) and AI safety analysis before
returning the itinerary to the user.

ALL MAP APIs ARE FREE - no credit card or API key needed.

Verification Pipeline:
  1. OpenStreetMap existence check via Overpass API (does this place exist?)
  2. Nominatim detail enrichment (address, type, accessibility)
  3. AI safety risk assessment (Groq LLM analysis)
  4. Coordinate validation (are lat/lng actually in Egypt?)
  5. Accessibility feature detection
"""
from typing import Dict, List, Any, Optional
from datetime import datetime
import asyncio
import json
import httpx
from groq import Groq
from geopy.distance import geodesic
from app.config import settings


class ItineraryPlaceVerifier:
    """
    Verifies every place in a generated itinerary against real-world data.
    
    Uses a triple-verification approach (ALL FREE):
      1st verify: Overpass API (OpenStreetMap) - Does the place exist?
      2nd verify: Nominatim - Get place details (address, type, hours)
      3rd verify: AI Safety - Is it safe for the target traveler profile?
    """
    
    # Egypt bounding box for coordinate sanity check
    EGYPT_BOUNDS = {
        "lat_min": 22.0,
        "lat_max": 31.7,
        "lng_min": 24.7,
        "lng_max": 36.9
    }
    
    OVERPASS_URL = "https://overpass-api.de/api/interpreter"
    NOMINATIM_URL = "https://nominatim.openstreetmap.org"
    
    def __init__(self):
        """Initialize verification clients (all free, no API keys needed for maps)"""
        self.http_client = httpx.AsyncClient(timeout=30.0)
        self.groq_client = Groq(api_key=settings.GROQ_API_KEY)
        print("\u2713 Itinerary Place Verifier initialized (OpenStreetMap + Groq - FREE)")
    
    # ========================================================================
    # FREE API HELPERS
    # ========================================================================
    
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
  node["historic"]{name_filter}(around:{radius},{lat},{lng});
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
    
    async def verify_itinerary(
        self,
        itinerary_data: Dict[str, Any],
        is_solo_traveler: bool = False,
        is_woman_traveler: bool = False,
        accessibility_needs: Optional[Dict] = None
    ) -> Dict[str, Any]:
        """
        Verify all places in a generated itinerary.
        
        For each activity/place:
        1. Check existence on OpenStreetMap (Overpass API)
        2. Get place details via Nominatim
        3. Run AI safety assessment
        4. Validate coordinates are in Egypt
        5. Check accessibility features
        
        Args:
            itinerary_data: The AI-generated itinerary
            is_solo_traveler: Whether the traveler is solo
            is_woman_traveler: Whether the traveler is a woman
            accessibility_needs: Accessibility requirements dict
            
        Returns:
            Enhanced itinerary with verification data for each activity
        """
        
        print("\n" + "=" * 70)
        print("VERIFY-VERIFY-VERIFY: Itinerary Place Verification")
        print("=" * 70)
        
        all_activities = []
        activity_map = {}  # Maps (day_idx, activity_idx) -> activity dict
        
        # Collect all activities
        for day_idx, day_plan in enumerate(itinerary_data.get("daily_plans", [])):
            for act_idx, activity in enumerate(day_plan.get("activities", [])):
                key = (day_idx, act_idx)
                all_activities.append((key, activity))
                activity_map[key] = activity
        
        total_activities = len(all_activities)
        print(f"Found {total_activities} activities to verify\n")
        
        # Verify all activities (batched for efficiency)
        verification_tasks = []
        for key, activity in all_activities:
            verification_tasks.append(
                self._verify_single_place(
                    activity,
                    is_solo_traveler=is_solo_traveler,
                    is_woman_traveler=is_woman_traveler,
                    accessibility_needs=accessibility_needs
                )
            )
        
        verification_results = await asyncio.gather(
            *verification_tasks, return_exceptions=True
        )
        
        # Process results and enhance itinerary
        verified_count = 0
        flagged_count = 0
        replaced_count = 0
        verification_summary = []
        
        for i, ((day_idx, act_idx), activity) in enumerate(all_activities):
            result = verification_results[i]
            
            if isinstance(result, Exception):
                # Verification failed - mark as unverified
                activity["verification"] = {
                    "status": "error",
                    "error": str(result),
                    "verified_at": datetime.utcnow().isoformat()
                }
                flagged_count += 1
                verification_summary.append({
                    "place": activity.get("location_name", "Unknown"),
                    "status": "error",
                    "reason": str(result)
                })
                continue
            
            # Attach verification data to activity
            activity["verification"] = result
            
            if result["status"] == "verified":
                verified_count += 1
                
                # Enrich with map data
                if result.get("google_data"):
                    gd = result["google_data"]
                    
                    # Update coordinates if map source has better ones
                    if gd.get("location"):
                        activity["latitude"] = gd["location"].get("lat", activity.get("latitude"))
                        activity["longitude"] = gd["location"].get("lng", activity.get("longitude"))
                    
                    # Add OSM data
                    activity["osm_id"] = gd.get("osm_id")
                    
                    # Update wheelchair accessibility from OSM
                    if gd.get("wheelchair_accessible") is not None:
                        activity["wheelchair_accessible"] = gd["wheelchair_accessible"]
                
                verification_summary.append({
                    "place": activity.get("location_name", "Unknown"),
                    "status": "verified",
                    "google_rating": result.get("google_data", {}).get("rating"),
                    "safety_level": result.get("safety_assessment", {}).get("level", "unknown")
                })
                
            elif result["status"] == "flagged":
                flagged_count += 1
                
                # Add safety warnings from verification
                if "safety_warnings" not in activity:
                    activity["safety_warnings"] = []
                activity["safety_warnings"].extend(
                    result.get("warnings", [])
                )
                
                verification_summary.append({
                    "place": activity.get("location_name", "Unknown"),
                    "status": "flagged",
                    "warnings": result.get("warnings", [])
                })
                
            elif result["status"] == "not_found":
                flagged_count += 1
                
                # Try to find an alternative
                alternative = result.get("suggested_alternative")
                if alternative:
                    # Suggest the alternative but keep original
                    activity["verification"]["suggested_alternative"] = alternative
                    activity["safety_warnings"] = activity.get("safety_warnings", [])
                    activity["safety_warnings"].append(
                        f"Place not found on maps. Consider: {alternative.get('name', 'N/A')}"
                    )
                else:
                    activity["safety_warnings"] = activity.get("safety_warnings", [])
                    activity["safety_warnings"].append(
                        "This place could not be verified on OpenStreetMap. Exercise caution."
                    )
                
                verification_summary.append({
                    "place": activity.get("location_name", "Unknown"),
                    "status": "not_found",
                    "alternative": alternative.get("name") if alternative else None
                })
        
        # Update itinerary with verification metadata
        itinerary_data["verification"] = {
            "verified_at": datetime.utcnow().isoformat(),
            "total_activities": total_activities,
            "verified_count": verified_count,
            "flagged_count": flagged_count,
            "replaced_count": replaced_count,
            "verification_rate": round(
                (verified_count / total_activities * 100) if total_activities > 0 else 0, 1
            ),
            "summary": verification_summary,
            "sources": ["OpenStreetMap (Nominatim + Overpass)", "Groq AI Safety Analysis"]
        }
        
        # Recalculate safety score post-verification
        itinerary_data["verified_safety_score"] = self._calculate_verified_safety_score(
            itinerary_data
        )
        
        print(f"\nVERIFICATION COMPLETE")
        print(f"   Verified: {verified_count}/{total_activities}")
        print(f"   Flagged:  {flagged_count}/{total_activities}")
        print(f"   Rate:     {itinerary_data['verification']['verification_rate']}%")
        print(f"   Safety:   {itinerary_data['verified_safety_score']}/100")
        print("=" * 70 + "\n")
        
        return itinerary_data
    
    async def _verify_single_place(
        self,
        activity: Dict[str, Any],
        is_solo_traveler: bool = False,
        is_woman_traveler: bool = False,
        accessibility_needs: Optional[Dict] = None
    ) -> Dict[str, Any]:
        """
        Triple-verify a single place/activity (ALL FREE APIs)
        
        Verification 1: OpenStreetMap existence (Overpass API)
        Verification 2: Place details & accessibility (Nominatim/OSM tags)
        Verification 3: AI safety assessment (Groq)
        """
        
        place_name = activity.get("location_name", activity.get("title", ""))
        latitude = activity.get("latitude")
        longitude = activity.get("longitude")
        
        result = {
            "status": "unverified",
            "place_name": place_name,
            "verifications": [],
            "warnings": [],
            "verified_at": datetime.utcnow().isoformat()
        }
        
        # ================================================================
        # VERIFICATION 1: OpenStreetMap - Does this place exist?
        # ================================================================
        map_data = await self._verify_osm(place_name, latitude, longitude)
        result["google_data"] = map_data  # Keep key name for backward compat
        
        if map_data.get("exists"):
            result["verifications"].append("osm_exists")
            print(f"  [1/3] \u2713 {place_name} - Found on OpenStreetMap")
        else:
            print(f"  [1/3] \u2717 {place_name} - NOT found on OpenStreetMap")
            
            # Try text search as fallback
            fallback = await self._search_place_text(place_name)
            if fallback.get("exists"):
                result["google_data"] = fallback
                result["verifications"].append("nominatim_text_search")
                print(f"        \u2192 Found via text search: {fallback.get('name')}")
            else:
                result["status"] = "not_found"
                result["warnings"].append(f"'{place_name}' not found on OpenStreetMap")
                
                # Try to find alternative
                alternative = await self._find_alternative(place_name, latitude, longitude)
                if alternative:
                    result["suggested_alternative"] = alternative
                
                return result
        
        # ================================================================
        # VERIFICATION 2: Place Details & Quality Check
        # ================================================================
        osm_id = map_data.get("osm_id")
        tags = map_data.get("tags", {})
        
        # Check business status from OSM tags
        if tags.get("disused") or tags.get("abandoned"):
            result["warnings"].append(f"'{place_name}' appears to be closed/abandoned")
            result["status"] = "flagged"
            return result
        
        # Check if place has enough details to be trustworthy
        has_details = bool(tags.get("name") or tags.get("tourism") or tags.get("amenity"))
        if has_details:
            result["verifications"].append("osm_has_details")
            print(f"  [2/3] \u2713 {place_name} - Has OSM details (type: {tags.get('tourism') or tags.get('amenity') or 'general'})")
        else:
            print(f"  [2/3] ~ {place_name} - Limited details on OpenStreetMap")
        
        # ================================================================
        # VERIFICATION 3: AI Safety Assessment
        # ================================================================
        safety = await self._assess_safety_ai(
            place_name=place_name,
            activity=activity,
            google_data=result.get("google_data", {}),
            is_solo_traveler=is_solo_traveler,
            is_woman_traveler=is_woman_traveler
        )
        
        result["safety_assessment"] = safety
        result["verifications"].append("ai_safety_assessed")
        
        safety_level = safety.get("level", "unknown")
        if safety_level == "low":
            result["warnings"].append(
                f"AI safety assessment: LOW safety for '{place_name}'"
            )
            result["warnings"].extend(safety.get("concerns", []))
        
        print(f"  [3/3] ✓ {place_name} - Safety: {safety_level.upper()}")
        
        # ================================================================
        # COORDINATE VALIDATION
        # ================================================================
        if latitude and longitude:
            if not self._is_in_egypt(latitude, longitude):
                result["warnings"].append(
                    f"Coordinates ({latitude}, {longitude}) are outside Egypt"
                )
                # Attempt to fix using OSM coordinates
                if result["google_data"].get("location"):
                    gl = result["google_data"]["location"]
                    if self._is_in_egypt(gl.get("lat", 0), gl.get("lng", 0)):
                        result["warnings"].append(
                            f"Using corrected coordinates from OpenStreetMap"
                        )
        
        # ================================================================
        # ACCESSIBILITY CHECK
        # ================================================================
        if accessibility_needs:
            acc_result = self._check_accessibility(result["google_data"], accessibility_needs)
            result["accessibility"] = acc_result
            if acc_result.get("warnings"):
                result["warnings"].extend(acc_result["warnings"])
        
        # Determine final status
        if result["warnings"]:
            result["status"] = "flagged" if any(
                "LOW safety" in w or "permanently closed" in w.lower()
                for w in result["warnings"]
            ) else "verified"
        else:
            result["status"] = "verified"
        
        return result
    
    async def _verify_osm(
        self, place_name: str, latitude: Optional[float], longitude: Optional[float]
    ) -> Dict[str, Any]:
        """Verify place exists on OpenStreetMap using Overpass API - FREE"""
        
        try:
            if latitude and longitude:
                # Search near the claimed coordinates
                results = await self._overpass_search_nearby(
                    latitude, longitude, radius=1000, keyword=place_name
                )
            else:
                # Nominatim text search with Egypt context
                results = await self._nominatim_search(f"{place_name} Egypt", limit=3)
            
            if not results:
                return {"exists": False}
            
            place = results[0]
            tags = place.get("tags", {})
            
            # Get location from Overpass element
            lat = place.get("lat", place.get("center", {}).get("lat", latitude or 0))
            lon = place.get("lon", place.get("center", {}).get("lon", longitude or 0))
            
            return {
                "exists": True,
                "osm_id": place.get("id", place.get("osm_id")),
                "name": tags.get("name", place.get("display_name", place_name)),
                "types": [v for k, v in tags.items() if k in ("tourism", "amenity", "historic", "shop")],
                "tags": tags,
                "vicinity": tags.get("addr:street", tags.get("addr:city", "")),
                "location": {"lat": float(lat), "lng": float(lon)},
                "wheelchair_accessible": tags.get("wheelchair") == "yes",
                "business_status": "CLOSED_PERMANENTLY" if tags.get("disused") else "OPERATIONAL"
            }
            
        except Exception as e:
            return {"exists": False, "error": str(e)}
    
    async def _search_place_text(self, place_name: str) -> Dict[str, Any]:
        """Fallback text search using Nominatim - FREE"""
        
        try:
            results = await self._nominatim_search(f"{place_name} Egypt tourism", limit=3)
            
            if not results:
                return {"exists": False}
            
            place = results[0]
            
            return {
                "exists": True,
                "osm_id": place.get("osm_id"),
                "name": place.get("display_name", place_name),
                "types": [place.get("type", "unknown")],
                "tags": place.get("extratags", {}),
                "location": {
                    "lat": float(place.get("lat", 0)),
                    "lng": float(place.get("lon", 0))
                },
                "business_status": "OPERATIONAL",
                "search_method": "nominatim_text_search"
            }
        except Exception:
            return {"exists": False}
    
    async def _get_place_details(self, osm_id: str) -> Dict[str, Any]:
        """Get detailed place information from Nominatim reverse lookup - FREE"""
        
        try:
            # Use Nominatim lookup by OSM ID
            response = await self.http_client.get(
                f"{self.NOMINATIM_URL}/lookup",
                params={
                    "osm_ids": f"N{osm_id}",
                    "format": "json",
                    "addressdetails": 1,
                    "extratags": 1
                },
                headers={"User-Agent": "SmartExplorers/1.0"}
            )
            
            results = response.json()
            if not results:
                return {}
            
            place = results[0]
            tags = place.get("extratags", {})
            address = place.get("address", {})
            
            return {
                "formatted_address": place.get("display_name", ""),
                "phone": tags.get("phone") or tags.get("contact:phone"),
                "website": tags.get("website") or tags.get("contact:website"),
                "opening_hours": tags.get("opening_hours"),
                "wheelchair_accessible": tags.get("wheelchair") == "yes",
                "business_status": "OPERATIONAL",
                "location": {
                    "lat": float(place.get("lat", 0)),
                    "lng": float(place.get("lon", 0))
                }
            }
            
        except Exception as e:
            return {"error": str(e)}
    
    async def _assess_safety_ai(
        self,
        place_name: str,
        activity: Dict[str, Any],
        google_data: Dict[str, Any],
        is_solo_traveler: bool = False,
        is_woman_traveler: bool = False
    ) -> Dict[str, Any]:
        """Use Groq AI to assess safety of a place for the traveler's profile"""
        
        try:
            traveler_context = []
            if is_solo_traveler:
                traveler_context.append("solo traveler")
            if is_woman_traveler:
                traveler_context.append("woman traveler")
            traveler_desc = ", ".join(traveler_context) if traveler_context else "general tourist"
            
            prompt = f"""Assess the safety of this location in Egypt for a {traveler_desc}:

Place: {place_name}
Category: {activity.get('category', 'tourism')}
Time of visit: {activity.get('start_time', 'daytime')} - {activity.get('end_time', '')}
Address: {google_data.get('formatted_address', activity.get('location_name', 'Egypt'))}
Place type: {', '.join(google_data.get('types', ['unknown']))}

Consider:
- Tourist scams common at this type of location
- Harassment risk (especially for solo/women travelers)
- Theft or pickpocket risk
- Time-of-day safety (is it safe at the planned visit time?)
- Transportation safety to/from this location
- Any known safety issues in the area

Respond with ONLY valid JSON:
{{
  "level": "high" or "medium" or "low",
  "score": 0-100,
  "concerns": ["concern1", "concern2"],
  "tips": ["safety tip 1", "safety tip 2"],
  "scam_warnings": ["any known scams at this location"]
}}"""

            response = self.groq_client.chat.completions.create(
                model=settings.GROQ_MODEL,
                messages=[{
                    "role": "system",
                    "content": "You are an Egypt tourism safety expert. Provide accurate, practical safety assessments. Do not be alarmist but do flag genuine concerns."
                }, {
                    "role": "user",
                    "content": prompt
                }],
                response_format={"type": "json_object"},
                temperature=0.3
            )
            
            safety = json.loads(response.choices[0].message.content)
            return safety
            
        except Exception as e:
            return {
                "level": "medium",
                "score": 50,
                "concerns": [],
                "tips": ["Exercise normal travel precautions"],
                "scam_warnings": [],
                "error": str(e)
            }
    
    async def _find_alternative(
        self, place_name: str, latitude: Optional[float], longitude: Optional[float]
    ) -> Optional[Dict[str, Any]]:
        """Find an alternative place nearby using Overpass API - FREE"""
        
        try:
            if not (latitude and longitude):
                return None
            
            # Search for tourist attractions nearby via Overpass
            query = f"""
[out:json][timeout:10];
(
  node["tourism"](around:2000,{latitude},{longitude});
  way["tourism"](around:2000,{latitude},{longitude});
  node["historic"](around:2000,{latitude},{longitude});
);
out center body 5;"""
            response = await self.http_client.post(
                self.OVERPASS_URL,
                data={"data": query},
                timeout=15.0
            )
            data = response.json()
            results = data.get("elements", [])
            
            if results:
                alt = results[0]
                tags = alt.get("tags", {})
                return {
                    "name": tags.get("name", "Nearby attraction"),
                    "osm_id": alt.get("id"),
                    "location": {
                        "lat": alt.get("lat", alt.get("center", {}).get("lat")),
                        "lng": alt.get("lon", alt.get("center", {}).get("lon"))
                    },
                    "types": [v for k, v in tags.items() if k in ("tourism", "historic", "amenity")]
                }
            
            return None
            
        except Exception:
            return None
    
    def _is_in_egypt(self, lat: float, lng: float) -> bool:
        """Check if coordinates are within Egypt's bounds"""
        return (
            self.EGYPT_BOUNDS["lat_min"] <= lat <= self.EGYPT_BOUNDS["lat_max"] and
            self.EGYPT_BOUNDS["lng_min"] <= lng <= self.EGYPT_BOUNDS["lng_max"]
        )
    
    def _check_accessibility(
        self, google_data: Dict[str, Any], accessibility_needs: Dict
    ) -> Dict[str, Any]:
        """Check if place meets accessibility requirements"""
        
        result = {
            "meets_requirements": True,
            "features": [],
            "warnings": []
        }
        
        wheelchair_accessible = google_data.get("wheelchair_accessible")
        
        if accessibility_needs.get("wheelchair_accessible"):
            if wheelchair_accessible is True:
                result["features"].append("Wheelchair accessible entrance confirmed")
            elif wheelchair_accessible is False:
                result["meets_requirements"] = False
                result["warnings"].append(
                    f"'{google_data.get('name', 'This place')}' is NOT wheelchair accessible"
                )
            else:
                result["warnings"].append(
                    f"Wheelchair accessibility unknown for '{google_data.get('name', 'this place')}'"
                )
        
        return result
    
    def _calculate_verified_safety_score(self, itinerary_data: Dict[str, Any]) -> float:
        """Calculate safety score based on verified data"""
        
        scores = []
        
        for day_plan in itinerary_data.get("daily_plans", []):
            for activity in day_plan.get("activities", []):
                verification = activity.get("verification", {})
                
                if verification.get("status") == "verified":
                    safety = verification.get("safety_assessment", {})
                    scores.append(safety.get("score", 50))
                elif verification.get("status") == "flagged":
                    scores.append(30)  # Penalize flagged places
                elif verification.get("status") == "not_found":
                    scores.append(20)  # Penalize unverified places
                else:
                    scores.append(40)
        
        if not scores:
            return 50.0
        
        return round(sum(scores) / len(scores), 1)


# Global instance
itinerary_place_verifier = ItineraryPlaceVerifier()
