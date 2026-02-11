from fastapi import APIRouter, Body
from typing import Dict, Any

from app.mongodb import get_database, mongodb

router = APIRouter(prefix="/api/v1/preferences", tags=["preferences"])


def _serialize(doc: Dict[str, Any]) -> Dict[str, Any]:
    if not doc:
        return doc
    doc["_id"] = str(doc["_id"])
    return doc


@router.get("/{user_id}")
async def get_preferences(user_id: str):
    db = get_database()
    doc = await db[mongodb.USER_PREFERENCES].find_one({"user_id": user_id})
    return _serialize(doc) or {"user_id": user_id}


@router.put("/{user_id}")
async def upsert_preferences(user_id: str, payload: Dict[str, Any] = Body(...)):
    db = get_database()
    payload["user_id"] = user_id
    await db[mongodb.USER_PREFERENCES].update_one(
        {"user_id": user_id}, {"$set": payload}, upsert=True
    )
    doc = await db[mongodb.USER_PREFERENCES].find_one({"user_id": user_id})
    return _serialize(doc)
