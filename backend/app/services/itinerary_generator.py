import os
import json
from typing import List, Dict, Any, Optional
from datetime import datetime, timedelta, date
from pathlib import Path

try:
    from groq import Groq
except ImportError:
    Groq = None

from ..schemas.itinerary import (
    TripType, SafetyLevel, ItineraryGenerationRequest,
    AccessibilityRequirement
)
from ..config import settings  # Import settings


class ItineraryGenerator:
    """AI-powered itinerary generation engine using Groq (faster & cheaper alternative to OpenAI)"""
    
    def __init__(self):
        # Get API key from settings (which reads from .env file)
        api_key = settings.GROQ_API_KEY
        
        # Validate API key
        if not api_key or api_key.startswith("gsk_your-") or len(api_key) < 20:
            raise ValueError(
                "⚠️  Valid Groq API key required!\n"
                "Set GROQ_API_KEY in your .env file.\n"
                "Get your FREE key from: https://console.groq.com/keys\n"
                "(Groq is MUCH faster than OpenAI and has a generous free tier!)"
            )
        
        try:
            # Check if Groq is installed
            if Groq is None:
                raise ValueError(
                    "Groq SDK is not installed. Install it with: pip install groq"
                )
            
            # Initialize Groq client
            self.client = Groq(api_key=api_key)
            # Use Llama 3.3 70B - excellent for structured output
            self.model = "llama-3.3-70b-versatile"
            
            print(f"✓ Groq client initialized successfully with model: {self.model}")
            
        except Exception as e:
            raise ValueError(f"Failed to initialize Groq client: {str(e)}")
        
        # Load Egypt destinations from JSON file
        self.egypt_destinations = self._load_destinations_data()
        
    def _load_destinations_data(self) -> Dict[str, Any]:
        """Load Egypt destinations from JSON file"""
        try:
            # Get the path to the JSON file
            current_dir = Path(__file__).parent.parent
            json_path = current_dir / "data" / "egypt_destinations.json"
            
            if not json_path.exists():
                print(f"⚠️  Warning: {json_path} not found, using minimal fallback data")
                return self._get_fallback_destinations()
            
            with open(json_path, 'r', encoding='utf-8') as f:
                data = json.load(f)
            
            # Transform the data into a dictionary keyed by destination name
            destinations_dict = {}
            for dest in data.get("destinations", []):
                destinations_dict[dest["name"]] = {
                    "attractions": dest.get("attractions", []),
                    "safety_level": dest.get("safety_level", "medium"),
                    "accessibility": dest.get("accessibility", "moderate"),
                    "avg_daily_budget": dest.get("avg_daily_budget", {"low": 30, "mid": 70, "high": 150}),
                    "description": dest.get("description", ""),
                    "best_time": dest.get("best_time", "Oct-Apr")
                }
            
            print(f"✓ Loaded {len(destinations_dict)} destinations from JSON file")
            return destinations_dict
            
        except Exception as e:
            print(f"⚠️  Error loading destinations JSON: {e}")
            print("   Using fallback data instead")
            return self._get_fallback_destinations()
    
    def _get_fallback_destinations(self) -> Dict[str, Any]:
        """Fallback destinations data if JSON loading fails"""
        return {
            "Cairo": {
                "attractions": ["Pyramids of Giza", "Egyptian Museum", "Khan el-Khalili", "Citadel of Saladin"],
                "safety_level": "high",
                "accessibility": "high",
                "avg_daily_budget": {"low": 30, "mid": 70, "high": 150}
            },
            "Luxor": {
                "attractions": ["Valley of the Kings", "Karnak Temple", "Luxor Temple", "Hatshepsut Temple"],
                "safety_level": "high",
                "accessibility": "moderate",
                "avg_daily_budget": {"low": 40, "mid": 85, "high": 170}
            },
            "Aswan": {
                "attractions": ["Philae Temple", "Abu Simbel", "Nubian Village", "Aswan High Dam"],
                "safety_level": "high",
                "accessibility": "moderate",
                "avg_daily_budget": {"low": 45, "mid": 90, "high": 180}
            }
        }
        
    async def generate_itinerary(self, request: ItineraryGenerationRequest, user_id: int) -> Dict[str, Any]:
        """Generate a complete AI-powered itinerary using Groq"""
        
        # Calculate trip duration
        total_days = (request.end_date - request.start_date).days + 1
        
        # Validate duration
        if total_days < 1:
            raise ValueError("Trip must be at least 1 day long")
        if total_days > 30:
            raise ValueError("Maximum trip duration is 30 days")
        
        # Build AI prompt with real destination data
        prompt = self._build_generation_prompt(request, total_days)
        system_prompt = self._get_system_prompt()
        
        # Call Groq API with comprehensive error handling
        try:
            print(f"🤖 Calling Groq API (Llama 3.3) for {total_days}-day itinerary...")
            
            # Groq uses same interface as OpenAI
            response = self.client.chat.completions.create(
                model=self.model,
                messages=[
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": prompt}
                ],
                temperature=0.7,
                response_format={"type": "json_object"}  # Force JSON output
            )
            
            print("✓ Groq API response received (usually <1 second!)")
            
            # Parse the response
            content = response.choices[0].message.content
            itinerary_data = json.loads(content)
            
            # Validate response structure
            if "daily_plans" not in itinerary_data:
                raise ValueError("AI response missing daily_plans field")
            
            if not isinstance(itinerary_data["daily_plans"], list):
                raise ValueError("daily_plans must be a list")
            
            # Enhance with safety validation and accessibility filtering
            enhanced_itinerary = await self._enhance_itinerary(
                itinerary_data, 
                request,
                total_days
            )
            
            print(f"✓ Itinerary enhanced with safety score: {enhanced_itinerary['safety_score']}")
            
            return enhanced_itinerary
            
        except json.JSONDecodeError as e:
            raise Exception(f"Failed to parse AI response as JSON: {str(e)}")
        except Exception as e:
            # Provide helpful error messages
            error_msg = str(e)
            if "invalid_api_key" in error_msg or "401" in error_msg:
                raise Exception(
                    "Invalid Groq API key. Please check your GROQ_API_KEY in .env file. "
                    "Get a FREE key from: https://console.groq.com/keys"
                )
            elif "rate_limit" in error_msg.lower() or "429" in error_msg:
                raise Exception("Groq rate limit exceeded. Please try again in a moment.")
            else:
                raise Exception(f"Failed to generate itinerary: {error_msg}")
    
    def _get_system_prompt(self) -> str:
        """System prompt for Egypt tourism AI"""
        return """You are an expert Egypt travel planner specializing in safe, accessible, and culturally-aware tourism.

Your expertise includes:
- Deep knowledge of Egyptian history, culture, and customs
- Safety considerations for solo travelers and women travelers
- Accessibility requirements for travelers with disabilities
- Budget optimization
- Cultural sensitivity and Islamic customs
- Optimal timing to avoid crowds
- Transportation logistics in Egypt
- Scam prevention and fraud awareness

When creating itineraries, you:
- Prioritize safety and cultural respect
- Consider accessibility requirements carefully
- Balance popular attractions with hidden gems
- Account for Egyptian prayer times and customs
- Suggest gender-appropriate activities when relevant
- Include specific safety tips for each location
- Recommend verified guides and services
- Consider the Egyptian climate and best visiting times

CRITICAL: You MUST respond with valid JSON only. No markdown, no explanations, just pure JSON."""

    def _build_generation_prompt(self, request: ItineraryGenerationRequest, total_days: int) -> str:
        """Build detailed prompt for itinerary generation with real destination data"""
        
        # Get destination information from loaded JSON
        destination_info = []
        for dest in request.destinations:
            if dest in self.egypt_destinations:
                dest_data = self.egypt_destinations[dest]
                attractions_list = ", ".join(dest_data.get("attractions", [])[:5])  # Top 5
                destination_info.append(
                    f"{dest}: {dest_data.get('description', '')} "
                    f"Popular attractions: {attractions_list}. "
                    f"Safety level: {dest_data.get('safety_level', 'medium')}. "
                    f"Best time: {dest_data.get('best_time', 'Oct-Apr')}."
                )
        
        destinations_context = "\n".join(destination_info) if destination_info else ""
        
        accessibility_text = ""
        if request.accessibility_requirements:
            acc = request.accessibility_requirements
            requirements = []
            if acc.wheelchair_accessible:
                requirements.append("wheelchair accessible")
            if acc.visual_impairment_support:
                requirements.append("visual impairment support")
            if acc.hearing_impairment_support:
                requirements.append("hearing impairment support")
            if acc.mobility_assistance:
                requirements.append("mobility assistance")
            if requirements:
                accessibility_text = f"\nAccessibility Requirements: {', '.join(requirements)}"
        
        safety_context = ""
        if request.is_solo_traveler:
            safety_context += "\n- Solo traveler: prioritize well-lit, populated areas and verified services"
        if request.is_woman_traveler:
            safety_context += "\n- Woman traveler: include women-friendly accommodations and gender-appropriate activities"
        
        budget_text = f"${request.budget_min or 0} - ${request.budget_max or 'unlimited'} total"
        
        prompt = f"""Create a detailed {total_days}-day itinerary for Egypt with the following requirements:

Trip Type: {request.trip_type.value}
Dates: {request.start_date} to {request.end_date}
Starting Point: {request.start_location}
Destinations: {', '.join(request.destinations)}
Group Size: {request.group_size} people
Budget: {budget_text}{accessibility_text}
Interests: {', '.join(request.interests) if request.interests else 'general tourism'}
Dietary Restrictions: {', '.join(request.dietary_restrictions) if request.dietary_restrictions else 'none'}{safety_context}

Destination Context:
{destinations_context}

Respond with ONLY valid JSON in this exact structure (no markdown, no code blocks):
{{
  "title": "Trip title",
  "description": "Brief overview",
  "daily_plans": [
    {{
      "day": 1,
      "date": "{request.start_date}",
      "title": "Day title",
      "activities": [
        {{
          "title": "Activity name",
          "description": "Detailed description",
          "location_name": "Specific location",
          "latitude": 30.0444,
          "longitude": 31.2357,
          "start_time": "09:00",
          "end_time": "11:00",
          "duration_minutes": 120,
          "estimated_cost_min": 10,
          "estimated_cost_max": 20,
          "category": "sightseeing",
          "safety_level": "high",
          "wheelchair_accessible": true,
          "tags": ["historical", "cultural"],
          "booking_required": false,
          "safety_warnings": ["Specific safety tip"]
        }}
      ]
    }}
  ],
  "ai_recommendations": {{
    "best_time_to_visit": "Season recommendation",
    "what_to_pack": ["item1", "item2"],
    "cultural_tips": ["tip1", "tip2"],
    "safety_tips": ["tip1", "tip2"],
    "local_customs": ["custom1", "custom2"],
    "scam_awareness": ["warning1", "warning2"]
  }},
  "total_estimated_cost": {{
    "min": 500,
    "max": 1000,
    "breakdown": {{
      "accommodation": {{"min": 200, "max": 400}},
      "activities": {{"min": 150, "max": 300}},
      "food": {{"min": 100, "max": 200}},
      "transport": {{"min": 50, "max": 100}}
    }}
  }}
}}

Important guidelines:
1. Create exactly {total_days} day(s) in daily_plans array
2. Ensure activities flow logically (proximity and timing)
3. Include realistic travel time between locations
4. Account for Egyptian business hours (many close 14:00-16:00)
5. Consider Friday prayer times (12:00-14:00)
6. Include specific GPS coordinates for each location
7. Provide practical safety tips, not generic warnings
8. Use the destination information provided above for authentic recommendations"""

        return prompt
    
    async def _enhance_itinerary(
        self, 
        itinerary_data: Dict[str, Any], 
        request: ItineraryGenerationRequest,
        total_days: int
    ) -> Dict[str, Any]:
        """Enhance AI-generated itinerary with safety validation and filtering"""
        
        # Add metadata
        itinerary_data["trip_type"] = request.trip_type.value
        itinerary_data["start_date"] = request.start_date.isoformat()
        itinerary_data["end_date"] = request.end_date.isoformat()
        itinerary_data["total_days"] = total_days
        itinerary_data["start_location"] = request.start_location
        itinerary_data["destinations"] = request.destinations
        
        # Calculate safety score
        safety_info = self._calculate_safety_score(itinerary_data, request)
        itinerary_data["safety_level"] = safety_info["level"]
        itinerary_data["safety_score"] = safety_info["score"]
        itinerary_data["safety_notes"] = safety_info["notes"]
        
        # Filter activities based on accessibility
        if request.accessibility_requirements:
            itinerary_data["daily_plans"] = self._filter_by_accessibility(
                itinerary_data["daily_plans"],
                request.accessibility_requirements
            )
        
        # Add day numbers and ordering
        for day_idx, day_plan in enumerate(itinerary_data.get("daily_plans", []), 1):
            day_plan["day_number"] = day_idx
            for activity_idx, activity in enumerate(day_plan.get("activities", []), 1):
                activity["day_number"] = day_idx
                activity["order_in_day"] = activity_idx
                activity["accessibility_friendly"] = self._check_accessibility(
                    activity, 
                    request.accessibility_requirements
                )
        
        return itinerary_data
    
    def _calculate_safety_score(
        self, 
        itinerary_data: Dict[str, Any], 
        request: ItineraryGenerationRequest
    ) -> Dict[str, Any]:
        """Calculate overall safety score and level"""
        
        total_activities = 0
        high_safety_count = 0
        medium_safety_count = 0
        low_safety_count = 0
        safety_notes = []
        
        for day_plan in itinerary_data.get("daily_plans", []):
            for activity in day_plan.get("activities", []):
                total_activities += 1
                safety_level = activity.get("safety_level", "medium")
                
                if safety_level == "high":
                    high_safety_count += 1
                elif safety_level == "medium":
                    medium_safety_count += 1
                else:
                    low_safety_count += 1
                    if request.is_solo_traveler or request.is_woman_traveler:
                        safety_notes.append(
                            f"Exercise extra caution at {activity['location_name']}"
                        )
        
        if total_activities == 0:
            return {"level": "medium", "score": 0.5, "notes": []}
        
        # Calculate weighted score
        safety_score = (
            (high_safety_count * 1.0) + 
            (medium_safety_count * 0.6) + 
            (low_safety_count * 0.2)
        ) / total_activities
        
        # Determine safety level
        if safety_score >= 0.8:
            level = "high"
        elif safety_score >= 0.5:
            level = "medium"
        else:
            level = "low"
            safety_notes.append("This itinerary includes some higher-risk locations")
        
        # Add context-specific notes
        if request.is_solo_traveler:
            safety_notes.append("Share your itinerary with family/friends")
            safety_notes.append("Use registered taxi services only")
        
        if request.is_woman_traveler:
            safety_notes.append("Dress modestly, especially at religious sites")
            safety_notes.append("Consider women-only tour groups for certain activities")
        
        return {
            "level": level,
            "score": round(safety_score, 2),
            "notes": safety_notes
        }
    
    def _filter_by_accessibility(
        self, 
        daily_plans: List[Dict[str, Any]], 
        requirements: AccessibilityRequirement
    ) -> List[Dict[str, Any]]:
        """Filter and adjust activities based on accessibility requirements"""
        
        filtered_plans = []
        
        for day_plan in daily_plans:
            filtered_activities = []
            
            for activity in day_plan.get("activities", []):
                # Check wheelchair accessibility
                if requirements.wheelchair_accessible:
                    if not activity.get("wheelchair_accessible", False):
                        # Add accessibility note
                        if "safety_warnings" not in activity:
                            activity["safety_warnings"] = []
                        activity["safety_warnings"].append(
                            "Limited wheelchair accessibility - alternative arrangements may be needed"
                        )
                
                filtered_activities.append(activity)
            
            day_plan["activities"] = filtered_activities
            filtered_plans.append(day_plan)
        
        return filtered_plans
    
    def _check_accessibility(
        self, 
        activity: Dict[str, Any], 
        requirements: Optional[AccessibilityRequirement]
    ) -> bool:
        """Check if activity meets accessibility requirements"""
        
        if not requirements:
            return True
        
        if requirements.wheelchair_accessible:
            return activity.get("wheelchair_accessible", False)
        
        return True
    
    async def validate_user_modifications(
        self, 
        original_itinerary: Dict[str, Any],
        modified_itinerary: Dict[str, Any]
    ) -> Dict[str, Any]:
        """Validate user modifications to ensure safety standards"""
        
        validation_result = {
            "is_valid": True,
            "warnings": [],
            "suggestions": []
        }
        
        # Check for removed safety activities
        original_activities = self._get_all_activities(original_itinerary)
        modified_activities = self._get_all_activities(modified_itinerary)
        
        # Safety validation checks
        if len(modified_activities) > len(original_activities) * 1.5:
            validation_result["warnings"].append(
                "You've added many activities - ensure adequate rest time"
            )
        
        # Check for late-night activities
        for activity in modified_activities:
            start_time = activity.get("start_time", "")
            if start_time and ":" in start_time:
                try:
                    hour = int(start_time.split(":")[0])
                    if hour >= 22 or hour <= 5:
                        validation_result["warnings"].append(
                            f"Late night/early morning activity at {activity.get('location_name', 'unknown')} - ensure safe transportation"
                        )
                except ValueError:
                    pass  # Invalid time format, skip
        
        return validation_result
    
    def _get_all_activities(self, itinerary: Dict[str, Any]) -> List[Dict[str, Any]]:
        """Extract all activities from itinerary"""
        activities = []
        for day_plan in itinerary.get("daily_plans", []):
            activities.extend(day_plan.get("activities", []))
        return activities