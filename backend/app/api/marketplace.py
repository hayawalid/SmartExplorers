from fastapi import APIRouter, Body
from typing import Dict, Any, Optional
from bson import ObjectId

from app.mongodb import get_database, mongodb

router = APIRouter(prefix="/api/v1/marketplace", tags=["marketplace"])


def _serialize(doc: Dict[str, Any]) -> Dict[str, Any]:
    if not doc:
        return doc
    doc["_id"] = str(doc["_id"])
    return doc


@router.get("/listings")
async def list_listings(category: Optional[str] = None, featured: Optional[bool] = None, limit: int = 100):
    db = get_database()
    query: Dict[str, Any] = {}
    if category and category != "All":
        query["category"] = category
    if featured is not None:
        query["featured_flag"] = featured

    cursor = db[mongodb.SERVICE_LISTINGS].find(query).limit(limit)
    return [_serialize(doc) async for doc in cursor]


@router.get("/listings/{listing_id}")
async def get_listing(listing_id: str):
    db = get_database()
    if not ObjectId.is_valid(listing_id):
        return {"detail": "Invalid listing_id"}
    doc = await db[mongodb.SERVICE_LISTINGS].find_one({"_id": ObjectId(listing_id)})
    return _serialize(doc)


@router.post("/listings")
async def create_listing(payload: Dict[str, Any] = Body(...)):
    db = get_database()
    result = await db[mongodb.SERVICE_LISTINGS].insert_one(payload)
    doc = await db[mongodb.SERVICE_LISTINGS].find_one({"_id": result.inserted_id})
    return _serialize(doc)


@router.post("/favorites")
async def create_favorite(payload: Dict[str, Any] = Body(...)):
    db = get_database()
    result = await db[mongodb.FAVORITES].insert_one(payload)
    doc = await db[mongodb.FAVORITES].find_one({"_id": result.inserted_id})
    return _serialize(doc)


@router.get("/favorites/{user_id}")
async def list_favorites(user_id: str):
    db = get_database()
    cursor = db[mongodb.FAVORITES].find({"user_id": user_id})
    return [_serialize(doc) async for doc in cursor]


@router.post("/bookings")
async def create_booking(payload: Dict[str, Any] = Body(...)):
    db = get_database()
    result = await db[mongodb.BOOKINGS].insert_one(payload)
    doc = await db[mongodb.BOOKINGS].find_one({"_id": result.inserted_id})
    return _serialize(doc)


@router.get("/bookings")
async def list_bookings(user_id: Optional[str] = None, provider_id: Optional[str] = None):
    db = get_database()
    query: Dict[str, Any] = {}
    if user_id:
        query["user_id"] = user_id
    if provider_id:
        query["provider_id"] = provider_id

    cursor = db[mongodb.BOOKINGS].find(query).sort("created_at", -1)
    return [_serialize(doc) async for doc in cursor]
