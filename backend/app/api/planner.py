"""
Planner API – unified chat + itinerary generation + save endpoint
"""
from fastapi import APIRouter, HTTPException, status
from pydantic import BaseModel, Field
from typing import Optional, Dict, List, Any
from datetime import datetime

from app.services.planner_service import planner_service
from app.mongodb import get_database, mongodb

router = APIRouter(
    prefix="/api/v1/planner",
    tags=["AI Planner"],
)


# ── Request / Response Schemas ──────────────────────────────────────

class PlannerChatRequest(BaseModel):
    message: str = Field(..., min_length=1, max_length=2000)
    conversation_id: Optional[str] = None
    user_context: Optional[Dict[str, Any]] = None


class PlannerChatResponse(BaseModel):
    mode: str  # "chat" or "itinerary"
    message: str
    conversation_id: str
    suggestions: List[str] = Field(default_factory=list)
    itinerary: Optional[Dict[str, Any]] = None
    timestamp: str


class SaveItineraryRequest(BaseModel):
    """Body sent when the user clicks 'Apply this plan'."""
    itinerary: Dict[str, Any] = Field(..., description="The itinerary object from the LLM")
    user_id: Optional[str] = None
    conversation_id: Optional[str] = None


class SaveItineraryResponse(BaseModel):
    success: bool
    itinerary_id: str
    message: str


class GetItineraryResponse(BaseModel):
    found: bool
    itinerary: Optional[Dict[str, Any]] = None


# ── Endpoints ────────────────────────────────────────────────────────

@router.post("/chat", response_model=PlannerChatResponse)
async def planner_chat(request: PlannerChatRequest):
    """
    Unified chat + itinerary endpoint.
    The LLM decides whether to return a plain chat reply or a full itinerary.
    """
    try:
        result = await planner_service.chat(
            message=request.message,
            conversation_id=request.conversation_id,
            user_context=request.user_context,
        )

        # Persist conversation turn to MongoDB
        db = get_database()
        now = datetime.utcnow()
        conv_id = result["conversation_id"]

        messages_to_push = [
            {"role": "user", "content": request.message, "timestamp": now},
            {"role": "assistant", "content": result["message"], "timestamp": now},
        ]

        await db[mongodb.CONVERSATIONS].update_one(
            {"conversation_id": conv_id},
            {
                "$setOnInsert": {
                    "conversation_id": conv_id,
                    "created_at": now,
                    "is_active": True,
                    "type": "planner",
                },
                "$push": {"messages": {"$each": messages_to_push}},
                "$set": {
                    "last_message_at": now,
                    "last_suggestions": result.get("suggestions", []),
                    "user_context": request.user_context,
                },
                "$inc": {"message_count": 2},
            },
            upsert=True,
        )

        return PlannerChatResponse(
            mode=result["mode"],
            message=result["message"],
            conversation_id=result["conversation_id"],
            suggestions=result.get("suggestions", []),
            itinerary=result.get("itinerary"),
            timestamp=result.get("timestamp", datetime.utcnow().isoformat()),
        )

    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Planner error: {str(e)}",
        )


@router.post("/save", response_model=SaveItineraryResponse)
async def save_itinerary(request: SaveItineraryRequest):
    """
    Save a generated itinerary to the database.
    Called when the user clicks 'Apply this plan to your itinerary'.
    """
    try:
        db = get_database()
        now = datetime.utcnow()

        doc = {
            "user_id": request.user_id,
            "conversation_id": request.conversation_id,
            "itinerary": request.itinerary,
            "status": "active",
            "created_at": now,
            "updated_at": now,
        }

        result = await db[mongodb.ITINERARIES].insert_one(doc)
        itinerary_id = str(result.inserted_id)

        return SaveItineraryResponse(
            success=True,
            itinerary_id=itinerary_id,
            message="Itinerary saved successfully!",
        )

    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to save itinerary: {str(e)}",
        )


@router.get("/my-itinerary/{user_id}", response_model=GetItineraryResponse)
async def get_my_itinerary(user_id: str):
    """
    Return the most-recently saved itinerary for a given user.
    """
    try:
        db = get_database()
        doc = await db[mongodb.ITINERARIES].find_one(
            {"user_id": user_id, "status": "active"},
            sort=[("created_at", -1)],
        )
        if doc is None:
            return GetItineraryResponse(found=False, itinerary=None)

        # Remove MongoDB _id (not JSON-serializable)
        it = doc.get("itinerary", {})
        return GetItineraryResponse(found=True, itinerary=it)

    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch itinerary: {str(e)}",
        )
