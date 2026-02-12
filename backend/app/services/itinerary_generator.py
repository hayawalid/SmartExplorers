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
from ..config import settings
from .destination_rag import destination_rag  # RAG service
from .itinerary_place_verifier import itinerary_place_verifier  # Verify-Verify-Verify


class ItineraryGenerator:
    """AI-powered itinerary generation engine using Groq + RAG with ChromaDB"""
    
    def __init__(self):
        # Get API key from settings
        api_key = settings.GROQ_API_KEY
        
        # Validate API key
        if not api_key or api_key.startswith("gsk_your-") or len(api_key) < 20:
            raise ValueError(
                "⚠️  Valid Groq API key required!\n"
                "Set GROQ_API_KEY in your .env file.\n"
                "Get your FREE key from: https://console.groq.com/keys"
            )
        
        try:
            if Groq is None:
                raise ValueError("Groq SDK not installed. Install: pip install groq")
            
            self.client = Groq(api_key=api_key)
            self.model = "llama-3.3-70b-versatile"
            
            print(f"✓ Groq client initialized: {self.model}")
            
        except Exception as e:
            raise ValueError(f"Failed to initialize Groq: {str(e)}")
        
        # Use RAG instead of loading entire JSON
        self.rag = destination_rag
        print("✓ RAG system ready with ChromaDB")
        
    async def generate_itinerary(self, request: ItineraryGenerationRequest, user_id: int) -> Dict[str, Any]:
        """Generate AI-powered itinerary using Groq + RAG"""
        
        # Calculate trip duration
        total_days = (request.end_date - request.start_date).days + 1
        
        # Validate duration
        if total_days < 1:
            raise ValueError("Trip must be at least 1 day long")
        if total_days > 30:
            raise ValueError("Maximum trip duration is 30 days")
        
        # 🔍 RAG: Get relevant destinations using semantic search
        relevant_destinations = await self._get_relevant_destinations(request)
        
        print(f"🔍 RAG found {len(relevant_destinations)} relevant destinations")
        
        # Build AI prompt with RAG results (not entire JSON!)
        prompt = self._build_generation_prompt(request, total_days, relevant_destinations)
        system_prompt = self._get_system_prompt()
        
        # Call Groq API
        try:
            print(f"🤖 Calling Groq API for {total_days}-day itinerary...")
            
            response = self.client.chat.completions.create(
                model=self.model,
                messages=[
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": prompt}
                ],
                temperature=0.7,
                response_format={"type": "json_object"}
            )
            
            print("✓ Groq API response received")
            
            # Parse response
            content = response.choices[0].message.content
            itinerary_data = json.loads(content)
            
            # Validate
            if "daily_plans" not in itinerary_data:
                raise ValueError("AI response missing daily_plans")
            
            # Enhance with safety validation
            enhanced_itinerary = await self._enhance_itinerary(
                itinerary_data, 
                request,
                total_days
            )
            
            print(f"✓ Itinerary enhanced (safety score: {enhanced_itinerary['safety_score']})")
            
            # ============================================================
            # VERIFY-VERIFY-VERIFY: Triple verification of every place
            # Uses Google Maps, Google Places, and AI Safety Analysis
            # ============================================================
            print("\n🔍 Starting Verify-Verify-Verify pipeline...")
            
            accessibility_needs = None
            if request.accessibility_requirements:
                accessibility_needs = {
                    "wheelchair_accessible": request.accessibility_requirements.wheelchair_accessible,
                    "visual_impairment_support": request.accessibility_requirements.visual_impairment_support,
                    "hearing_impairment_support": request.accessibility_requirements.hearing_impairment_support,
                    "mobility_assistance": request.accessibility_requirements.mobility_assistance,
                }
            
            try:
                verified_itinerary = await itinerary_place_verifier.verify_itinerary(
                    itinerary_data=enhanced_itinerary,
                    is_solo_traveler=request.is_solo_traveler,
                    is_woman_traveler=request.is_woman_traveler,
                    accessibility_needs=accessibility_needs
                )
                
                verification_info = verified_itinerary.get("verification", {})
                print(
                    f"✓ Verification complete: "
                    f"{verification_info.get('verified_count', 0)}/"
                    f"{verification_info.get('total_activities', 0)} places verified "
                    f"({verification_info.get('verification_rate', 0)}%)"
                )
                
                return verified_itinerary
                
            except Exception as verify_err:
                # Verification is best-effort; return unverified itinerary on failure
                print(f"⚠️  Verification pipeline error: {verify_err}")
                enhanced_itinerary["verification"] = {
                    "status": "skipped",
                    "reason": str(verify_err),
                    "verified_at": None
                }
                return enhanced_itinerary
            
        except json.JSONDecodeError as e:
            raise Exception(f"Failed to parse AI response: {str(e)}")
        except Exception as e:
            error_msg = str(e)
            if "invalid_api_key" in error_msg or "401" in error_msg:
                raise Exception("Invalid Groq API key. Check GROQ_API_KEY in .env")
            elif "rate_limit" in error_msg.lower() or "429" in error_msg:
                raise Exception("Groq rate limit exceeded. Try again in a moment.")
            else:
                raise Exception(f"Failed to generate itinerary: {error_msg}")
    
    async def _get_relevant_destinations(
        self, 
        request: ItineraryGenerationRequest
    ) -> List[Dict[str, Any]]:
        """Use RAG to find relevant destinations based on user preferences"""
        
        # Build search criteria
        budget_max = request.budget_max
        accessibility_required = False
        
        if request.accessibility_requirements:
            acc = request.accessibility_requirements
            if acc.wheelchair_accessible or acc.mobility_assistance:
                accessibility_required = True
        
        # Determine safety level filter
        safety_level = None
        if request.is_solo_traveler or request.is_woman_traveler:
            safety_level = "high"  # Prioritize high safety
        
        # Get destinations matching user preferences
        relevant_dests = self.rag.get_destinations_for_preferences(
            interests=request.interests or ["tourism", "culture", "history"],
            budget_max=budget_max,
            accessibility_required=accessibility_required,
            safety_level=safety_level,
            n_results=15  # Get top 15 most relevant
        )
        
        # If user specified specific destinations, prioritize those
        if request.destinations:
            specified_dests = self.rag.get_destinations_by_names(request.destinations)
            # Merge: specified destinations first, then RAG suggestions
            relevant_dests = specified_dests + [
                d for d in relevant_dests 
                if d['name'] not in request.destinations
            ]
        
        return relevant_dests[:10]  # Return top 10
    
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

    def _build_generation_prompt(
        self, 
        request: ItineraryGenerationRequest, 
        total_days: int,
        relevant_destinations: List[Dict[str, Any]]
    ) -> str:
        """Build detailed prompt with RAG results"""
        
        # Format destination context from RAG results
        destination_info = []
        for dest in relevant_destinations:
            attractions_list = ", ".join(dest.get("attractions", [])[:5])
            destination_info.append(
                f"**{dest['name']}**: {dest.get('description', '')} "
                f"Main attractions: {attractions_list}. "
                f"Safety: {dest.get('safety_level', 'medium')}, "
                f"Accessibility: {dest.get('accessibility', 'moderate')}, "
                f"Budget: ${dest.get('avg_budget_low')}-${dest.get('avg_budget_high')}/day. "
                f"Best time: {dest.get('best_time', 'Oct-Apr')}."
            )
        
        destinations_context = "\n".join(destination_info)
        
        # Accessibility text
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
        
        # Safety context
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
Requested Destinations: {', '.join(request.destinations) if request.destinations else 'flexible'}
Group Size: {request.group_size} people
Budget: {budget_text}{accessibility_text}
Interests: {', '.join(request.interests) if request.interests else 'general tourism'}
Dietary Restrictions: {', '.join(request.dietary_restrictions) if request.dietary_restrictions else 'none'}{safety_context}

RELEVANT DESTINATIONS (Selected by AI based on your preferences):
{destinations_context}

IMPORTANT: Use ONLY the destinations listed above. These were specifically selected to match your interests, budget, safety requirements, and accessibility needs.

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
8. Use ONLY destinations from the list above"""

        return prompt
    
    async def _enhance_itinerary(
        self, 
        itinerary_data: Dict[str, Any], 
        request: ItineraryGenerationRequest,
        total_days: int
    ) -> Dict[str, Any]:
        """Enhance AI-generated itinerary with safety validation"""
        
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
        
        # Filter by accessibility
        if request.accessibility_requirements:
            itinerary_data["daily_plans"] = self._filter_by_accessibility(
                itinerary_data["daily_plans"],
                request.accessibility_requirements
            )
        
        # Add day numbers
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
        """Calculate overall safety score"""
        
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
        
        # Determine level
        if safety_score >= 0.8:
            level = "high"
        elif safety_score >= 0.5:
            level = "medium"
        else:
            level = "low"
            safety_notes.append("This itinerary includes some higher-risk locations")
        
        # Context-specific notes
        if request.is_solo_traveler:
            safety_notes.append("Share your itinerary with family/friends")
            safety_notes.append("Use registered taxi services only")
        
        if request.is_woman_traveler:
            safety_notes.append("Dress modestly, especially at religious sites")
            safety_notes.append("Consider women-only tour groups")
        
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
        """Filter activities by accessibility"""
        
        filtered_plans = []
        
        for day_plan in daily_plans:
            filtered_activities = []
            
            for activity in day_plan.get("activities", []):
                # Check wheelchair accessibility
                if requirements.wheelchair_accessible:
                    if not activity.get("wheelchair_accessible", False):
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
        """Validate user modifications"""
        
        validation_result = {
            "is_valid": True,
            "warnings": [],
            "suggestions": []
        }
        
        original_activities = self._get_all_activities(original_itinerary)
        modified_activities = self._get_all_activities(modified_itinerary)
        
        # Check for overload
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
                            f"Late night activity at {activity.get('location_name')} - ensure safe transportation"
                        )
                except ValueError:
                    pass
        
        return validation_result
    
    def _get_all_activities(self, itinerary: Dict[str, Any]) -> List[Dict[str, Any]]:
        """Extract all activities"""
        activities = []
        for day_plan in itinerary.get("daily_plans", []):
            activities.extend(day_plan.get("activities", []))
        return activities