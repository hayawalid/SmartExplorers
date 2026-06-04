"""
Location Sharing API – Live tracking for safety
"""
from fastapi import APIRouter, HTTPException, Depends
from typing import List
from datetime import datetime, timedelta
from bson import ObjectId

from app.mongodb import get_database, mongodb
from app.api.auth import get_current_user
from pydantic import BaseModel

router = APIRouter(prefix="/api/v1/location", tags=["Location"])


class LocationShare(BaseModel):
    latitude: float
    longitude: float
    accuracy: float


@router.post("/share")
async def share_location(
    data: LocationShare,
    current_user: dict = Depends(get_current_user),
    db=Depends(get_database)
):
    """Store current user location (for live tracking)."""
    doc = {
        "user_id": current_user["_id"],
        "latitude": data.latitude,
        "longitude": data.longitude,
        "accuracy": data.accuracy,
        "shared_at": datetime.utcnow()
    }
    await db[mongodb.LOCATION_SHARES].insert_one(doc)
    return {"success": True, "message": "Location recorded"}


@router.get("/history", response_model=List[dict])
async def get_location_history(
    limit: int = 10,
    current_user: dict = Depends(get_current_user),
    db=Depends(get_database)
):
    """Get user's recent location history (last 10 by default)."""
    cursor = db[mongodb.LOCATION_SHARES].find(
        {"user_id": current_user["_id"]}
    ).sort("shared_at", -1).limit(limit)
    history = []
    async for doc in cursor:
        doc["_id"] = str(doc["_id"])
        history.append(doc)
    return history