from fastapi import APIRouter, HTTPException, Body
from typing import Dict, Any
from bson import ObjectId

from app.mongodb import get_database, mongodb

router = APIRouter(prefix="/api/v1/users", tags=["users"])


def _serialize_user(doc: Dict[str, Any]) -> Dict[str, Any]:
    if not doc:
        return doc
    doc["_id"] = str(doc["_id"])
    doc.pop("hashed_password", None)
    return doc


@router.get("/{user_id}")
async def get_user(user_id: str):
    db = get_database()
    if not ObjectId.is_valid(user_id):
        raise HTTPException(status_code=400, detail="Invalid user_id")

    doc = await db[mongodb.USERS].find_one({"_id": ObjectId(user_id)})
    if not doc:
        raise HTTPException(status_code=404, detail="User not found")

    return _serialize_user(doc)


@router.get("/by-username/{username}")
async def get_user_by_username(username: str):
    db = get_database()
    doc = await db[mongodb.USERS].find_one({"username": username})
    if not doc:
        raise HTTPException(status_code=404, detail="User not found")

    return _serialize_user(doc)


@router.patch("/{user_id}")
async def update_user(user_id: str, payload: Dict[str, Any] = Body(...)):
    db = get_database()
    if not ObjectId.is_valid(user_id):
        raise HTTPException(status_code=400, detail="Invalid user_id")

    allowed_fields = {
        "full_name",
        "phone_number",
        "bio",
        "avatar_url",
        "profile_picture_url",
        "username",
    }
    update_data = {k: v for k, v in payload.items() if k in allowed_fields}

    if not update_data:
        raise HTTPException(status_code=400, detail="No valid fields to update")

    result = await db[mongodb.USERS].update_one(
        {"_id": ObjectId(user_id)}, {"$set": update_data}
    )

    if result.matched_count == 0:
        raise HTTPException(status_code=404, detail="User not found")

    doc = await db[mongodb.USERS].find_one({"_id": ObjectId(user_id)})
    return _serialize_user(doc)
