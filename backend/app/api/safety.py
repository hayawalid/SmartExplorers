from fastapi import APIRouter, Body
from typing import Dict, Any
from bson import ObjectId

from app.mongodb import get_database, mongodb

router = APIRouter(prefix="/api/v1/safety", tags=["safety"])


def _serialize(doc: Dict[str, Any]) -> Dict[str, Any]:
    if not doc:
        return doc
    doc["_id"] = str(doc["_id"])
    return doc


@router.get("/{user_id}")
async def get_safety_profile(user_id: str):
    db = get_database()
    doc = await db[mongodb.SAFETY_PROFILES].find_one({"user_id": user_id})
    return _serialize(doc) or {"user_id": user_id, "live_tracking_enabled": False}


@router.put("/{user_id}")
async def upsert_safety_profile(user_id: str, payload: Dict[str, Any] = Body(...)):
    db = get_database()
    payload["user_id"] = user_id
    await db[mongodb.SAFETY_PROFILES].update_one(
        {"user_id": user_id}, {"$set": payload}, upsert=True
    )
    doc = await db[mongodb.SAFETY_PROFILES].find_one({"user_id": user_id})
    return _serialize(doc)


@router.get("/{user_id}/contacts")
async def list_emergency_contacts(user_id: str):
    db = get_database()
    cursor = db[mongodb.EMERGENCY_CONTACTS].find({"user_id": user_id})
    return [_serialize(doc) async for doc in cursor]


@router.post("/{user_id}/contacts")
async def create_emergency_contact(user_id: str, payload: Dict[str, Any] = Body(...)):
    db = get_database()
    payload["user_id"] = user_id
    result = await db[mongodb.EMERGENCY_CONTACTS].insert_one(payload)
    doc = await db[mongodb.EMERGENCY_CONTACTS].find_one({"_id": result.inserted_id})
    return _serialize(doc)


@router.delete("/contacts/{contact_id}")
async def delete_emergency_contact(contact_id: str):
    db = get_database()
    if not ObjectId.is_valid(contact_id):
        return {"detail": "Invalid contact_id"}
    result = await db[mongodb.EMERGENCY_CONTACTS].delete_one({"_id": ObjectId(contact_id)})
    return {"deleted": result.deleted_count == 1}


@router.get("/{user_id}/panic-events")
async def list_panic_events(user_id: str):
    db = get_database()
    cursor = db[mongodb.PANIC_EVENTS].find({"user_id": user_id}).sort("timestamp", -1)
    return [_serialize(doc) async for doc in cursor]


@router.post("/{user_id}/panic-events")
async def create_panic_event(user_id: str, payload: Dict[str, Any] = Body(...)):
    db = get_database()
    payload["user_id"] = user_id
    result = await db[mongodb.PANIC_EVENTS].insert_one(payload)
    doc = await db[mongodb.PANIC_EVENTS].find_one({"_id": result.inserted_id})
    return _serialize(doc)
