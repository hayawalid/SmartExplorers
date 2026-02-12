"""
Unified Planner Service – combines AI chat + itinerary generation + RAG
One LLM endpoint that handles both conversational chat and structured itinerary generation.
"""
import json
import uuid
from typing import Optional, Dict, List, Any
from datetime import datetime

from groq import Groq
from app.config import settings
from app.services.destination_rag import destination_rag


class PlannerService:
    """Unified AI planner that can chat AND generate itineraries, powered by RAG."""

    def __init__(self):
        self.client = Groq(api_key=settings.GROQ_API_KEY)
        self.model = settings.GROQ_MODEL  # llama-3.3-70b-versatile
        self.rag = destination_rag
        self.conversations: Dict[str, List[Dict[str, str]]] = {}

        # Combined system prompt (travel assistant + itinerary planner)
        self.system_prompt = """You are an expert AI travel assistant specializing in Egypt tourism.

You have TWO modes — detect which one the user needs:

═══ MODE 1 — CHAT ═══
When the user asks a general question, greets you, or wants travel advice, respond naturally.
Return JSON: {"mode": "chat", "message": "<your helpful response>", "suggestions": ["follow-up 1", "follow-up 2", "follow-up 3"]}

═══ MODE 2 — ITINERARY ═══
When the user asks you to **plan a trip**, **create an itinerary**, or says things like
"plan me a 3-day trip", "I want to visit Luxor and Aswan", "create an itinerary for Cairo",
switch to itinerary mode.

IMPORTANT DATE/TIME RULES:
- If the user specifies dates, use those exact dates for the daily_plans.
- If the user does NOT specify dates, pick the best upcoming dates starting from today's date and assign them.
- Every daily_plan MUST have a "date" field in "YYYY-MM-DD" format.
- Every activity MUST have "start_time" and "end_time" in "HH:MM" 24-hour format.
- Choose the BEST time of day for each activity based on your expert knowledge:
  * Outdoor monuments (Pyramids, temples): early morning (07:00-10:00) to avoid heat
  * Museums: mid-morning (10:00-13:00)
  * Markets/bazaars (Khan El Khalili): late afternoon/evening (16:00-20:00)
  * Nile cruises/felucca rides: sunset time (16:30-18:30)
  * Desert activities: early morning (06:00-09:00) or late afternoon (15:30-17:30)
  * Diving/snorkeling: morning (08:00-12:00)
  * Religious sites: respect prayer times, avoid Friday 12:00-14:00
- Add a "best_time_reason" field to each activity explaining WHY that time slot is optimal.

Return JSON:
{
  "mode": "itinerary",
  "message": "Here is your personalized Egypt itinerary!",
  "suggestions": ["Modify this plan", "Add more days", "Change budget"],
  "itinerary": {
    "title": "Trip title",
    "description": "Brief overview",
    "total_days": <number>,
    "start_date": "YYYY-MM-DD",
    "end_date": "YYYY-MM-DD",
    "daily_plans": [
      {
        "day": 1,
        "date": "YYYY-MM-DD",
        "title": "Day title",
        "activities": [
          {
            "title": "Activity name",
            "description": "Detailed description",
            "location_name": "Specific location in Egypt",
            "latitude": 30.0444,
            "longitude": 31.2357,
            "start_time": "07:00",
            "end_time": "10:00",
            "best_time_reason": "Early morning avoids the midday heat and tourist crowds at the Pyramids",
            "duration_minutes": 180,
            "estimated_cost_min": 10,
            "estimated_cost_max": 20,
            "category": "sightseeing",
            "safety_level": "high",
            "tags": ["historical", "cultural"]
          }
        ]
      }
    ],
    "ai_recommendations": {
      "safety_tips": ["tip1", "tip2"],
      "cultural_tips": ["tip1", "tip2"],
      "what_to_pack": ["item1", "item2"]
    },
    "total_estimated_cost": {"min": 500, "max": 1000}
  }
}

RULES:
- ALWAYS respond with **valid JSON only**. No markdown, no code blocks, just raw JSON.
- For itinerary mode, use ONLY the destination info provided in the CONTEXT section below.
- Include realistic GPS coordinates for every Egyptian location.
- Prioritize safety, especially for solo travelers and women travelers.
- Be concise in chat mode; be detailed in itinerary mode.
- Keep cost estimates in USD.
- Today's date is {today}. Use it when the user doesn't specify trip dates.
"""

    async def chat(
        self,
        message: str,
        conversation_id: Optional[str] = None,
        user_context: Optional[Dict[str, Any]] = None,
    ) -> Dict[str, Any]:
        """
        Main entry point – handles both chat and itinerary generation.
        Returns a dict with keys: mode, message, suggestions, and optionally itinerary.
        """
        conv_id = conversation_id or f"plan_{uuid.uuid4().hex[:12]}"

        # --- RAG: always fetch destination context so the LLM has it ---
        rag_context = self._get_rag_context(message)

        # --- Build messages ---
        messages = self._build_messages(message, conv_id, user_context, rag_context)

        # --- Call Groq ---
        try:
            response = self.client.chat.completions.create(
                model=self.model,
                messages=messages,
                temperature=0.7,
                max_tokens=4096,
                response_format={"type": "json_object"},
            )

            raw = response.choices[0].message.content
            data = json.loads(raw)

            # Ensure required keys
            mode = data.get("mode", "chat")
            result_message = data.get("message", "")
            suggestions = data.get("suggestions", [])
            itinerary = data.get("itinerary") if mode == "itinerary" else None

            # Store conversation history
            if conv_id not in self.conversations:
                self.conversations[conv_id] = []
            self.conversations[conv_id].append({"role": "user", "content": message})
            self.conversations[conv_id].append({"role": "assistant", "content": raw})
            # Trim to last 10
            if len(self.conversations[conv_id]) > 10:
                self.conversations[conv_id] = self.conversations[conv_id][-10:]

            return {
                "mode": mode,
                "message": result_message,
                "conversation_id": conv_id,
                "suggestions": suggestions,
                "itinerary": itinerary,
                "timestamp": datetime.now().isoformat(),
            }

        except json.JSONDecodeError:
            # Fallback if JSON parsing fails
            return {
                "mode": "chat",
                "message": raw if raw else "Sorry, I had trouble processing that. Can you try again?",
                "conversation_id": conv_id,
                "suggestions": [],
                "itinerary": None,
                "timestamp": datetime.now().isoformat(),
            }
        except Exception as e:
            print(f"[PlannerService] Error: {e}")
            raise

    # ─── PRIVATE HELPERS ─────────────────────────────────────────────

    def _get_rag_context(self, user_message: str) -> str:
        """Use RAG to fetch relevant Egypt destinations for the user message."""
        try:
            results = self.rag.search_destinations(query=user_message, n_results=8)
            if not results:
                return ""
            lines: List[str] = []
            for d in results:
                attractions = ", ".join(d.get("attractions", [])[:5])
                lines.append(
                    f"- {d['name']}: {d.get('description', '')} "
                    f"Attractions: {attractions}. "
                    f"Safety: {d.get('safety_level', 'medium')}, "
                    f"Accessibility: {d.get('accessibility', 'moderate')}, "
                    f"Budget: ${d.get('avg_budget_low', '?')}-${d.get('avg_budget_high', '?')}/day."
                )
            return "\n".join(lines)
        except Exception as e:
            print(f"[RAG] Error fetching context: {e}")
            return ""

    def _build_messages(
        self,
        user_message: str,
        conv_id: str,
        user_context: Optional[Dict[str, Any]],
        rag_context: str,
    ) -> List[Dict[str, str]]:
        """Build the full messages array for the Groq API call."""
        # Inject today's date into the system prompt
        today_str = datetime.now().strftime("%Y-%m-%d")
        system_prompt_with_date = self.system_prompt.replace("{today}", today_str)

        messages: List[Dict[str, str]] = [
            {"role": "system", "content": system_prompt_with_date},
        ]

        # Inject RAG context
        if rag_context:
            messages.append({
                "role": "system",
                "content": (
                    "CONTEXT — Relevant Egypt destinations from our database:\n"
                    f"{rag_context}\n\n"
                    "Use the above destinations when building itineraries. "
                    "Do NOT invent locations outside this list."
                ),
            })

        # Inject user context
        if user_context:
            ctx = self._format_user_context(user_context)
            if ctx:
                messages.append({"role": "system", "content": ctx})

        # Add conversation history (last 10 turns)
        if conv_id in self.conversations:
            messages.extend(self.conversations[conv_id][-10:])

        # Current user message
        messages.append({"role": "user", "content": user_message})
        return messages

    @staticmethod
    def _format_user_context(ctx: Dict[str, Any]) -> str:
        """Build a user-context system note."""
        parts: List[str] = []
        if ctx.get("gender") == "female":
            parts.append("Female traveler – include women-specific safety tips when relevant.")
        if ctx.get("traveling_alone"):
            parts.append("Solo traveler – mention solo safety tips.")
        if ctx.get("accessibility_needs"):
            parts.append(f"Accessibility needs: {ctx['accessibility_needs']}.")
        if ctx.get("first_time_egypt"):
            parts.append("First-time visitor to Egypt.")
        if parts:
            return "User profile:\n" + "\n".join(parts)
        return ""


# Global singleton
planner_service = PlannerService()
