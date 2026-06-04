"""
Travel Spaces API – Group travel planning
"""
from fastapi import APIRouter, HTTPException, Depends, Query
from typing import List, Optional
from datetime import datetime
from bson import ObjectId

from app.mongodb import get_database, mongodb
from app.schemas.travel_space import (
    TravelSpaceCreate,
    TravelSpaceResponse,
    TravelSpaceListItem,
    JoinRequestResponse
)
from app.api.auth import get_current_user  # Assuming you have this dependency

router = APIRouter(prefix="/api/v1/travel-spaces", tags=["Travel Spaces"])


def _serialize(doc):
    if not doc:
        return doc
    doc["_id"] = str(doc["_id"])
    return doc


@router.post("/", response_model=TravelSpaceResponse, status_code=201)
async def create_travel_space(
    data: TravelSpaceCreate,
    current_user: dict = Depends(get_current_user),
    db=Depends(get_database)
):
    """Create a new travel space. Creator becomes the first member."""
    now = datetime.utcnow()
    doc = {
        "name": data.name,
        "description": data.description,
        "destination": data.destination,
        "start_date": data.start_date.isoformat(),
        "end_date": data.end_date.isoformat(),
        "creator_id": current_user["_id"],
        "member_ids": [current_user["_id"]],
        "pending_member_ids": [],
        "image_url": data.image_url,
        "tag": data.tag,
        "shared_itinerary": None,
        "is_public": data.is_public,
        "created_at": now,
        "updated_at": now,
    }
    result = await db[mongodb.TRAVEL_SPACES].insert_one(doc)
    doc["_id"] = str(result.inserted_id)
    return doc


@router.get("/", response_model=List[TravelSpaceListItem])
async def list_public_spaces(
    skip: int = Query(0, ge=0),
    limit: int = Query(20, ge=1, le=100),
    db=Depends(get_database)
):
    """List all public travel spaces (paginated)."""
    cursor = db[mongodb.TRAVEL_SPACES].find({"is_public": True}).sort("created_at", -1).skip(skip).limit(limit)
    spaces = []
    async for doc in cursor:
        doc = _serialize(doc)
        spaces.append({
            "id": doc["_id"],
            "name": doc["name"],
            "destination": doc["destination"],
            "image_url": doc.get("image_url"),
            "tag": doc.get("tag"),
            "member_count": len(doc.get("member_ids", [])),
            "created_at": doc["created_at"],
        })
    return spaces


@router.get("/joined", response_model=List[TravelSpaceListItem])
async def get_joined_spaces(
    current_user: dict = Depends(get_current_user),
    db=Depends(get_database)
):
    """List spaces where current user is a member."""
    cursor = db[mongodb.TRAVEL_SPACES].find({"member_ids": current_user["_id"]}).sort("created_at", -1)
    spaces = []
    async for doc in cursor:
        doc = _serialize(doc)
        spaces.append({
            "id": doc["_id"],
            "name": doc["name"],
            "destination": doc["destination"],
            "image_url": doc.get("image_url"),
            "tag": doc.get("tag"),
            "member_count": len(doc.get("member_ids", [])),
            "created_at": doc["created_at"],
        })
    return spaces


@router.get("/{space_id}", response_model=TravelSpaceResponse)
async def get_travel_space(
    space_id: str,
    current_user: dict = Depends(get_current_user),
    db=Depends(get_database)
):
    """Get details of a travel space (only members can view)."""
    if not ObjectId.is_valid(space_id):
        raise HTTPException(400, "Invalid space ID")
    doc = await db[mongodb.TRAVEL_SPACES].find_one({"_id": ObjectId(space_id)})
    if not doc:
        raise HTTPException(404, "Travel space not found")
    if not doc.get("is_public") and current_user["_id"] not in doc.get("member_ids", []):
        raise HTTPException(403, "You are not a member of this private space")
    doc = _serialize(doc)
    # Get creator name
    creator = await db[mongodb.USERS].find_one({"_id": ObjectId(doc["creator_id"])})
    doc["creator_name"] = creator.get("full_name") if creator else "Unknown"
    doc["member_count"] = len(doc.get("member_ids", []))
    return doc


@router.post("/{space_id}/join", response_model=JoinRequestResponse)
async def request_to_join(
    space_id: str,
    current_user: dict = Depends(get_current_user),
    db=Depends(get_database)
):
    """Request to join a travel space. Creator must approve."""
    if not ObjectId.is_valid(space_id):
        raise HTTPException(400, "Invalid space ID")
    space = await db[mongodb.TRAVEL_SPACES].find_one({"_id": ObjectId(space_id)})
    if not space:
        raise HTTPException(404, "Travel space not found")
    if current_user["_id"] in space.get("member_ids", []):
        return JoinRequestResponse(success=False, message="Already a member", pending_members=space.get("pending_member_ids", []))
    if current_user["_id"] in space.get("pending_member_ids", []):
        return JoinRequestResponse(success=False, message="Request already pending", pending_members=space.get("pending_member_ids", []))
    await db[mongodb.TRAVEL_SPACES].update_one(
        {"_id": ObjectId(space_id)},
        {"$addToSet": {"pending_member_ids": current_user["_id"]}, "$set": {"updated_at": datetime.utcnow()}}
    )
    updated = await db[mongodb.TRAVEL_SPACES].find_one({"_id": ObjectId(space_id)})
    return JoinRequestResponse(success=True, message="Join request sent", pending_members=updated.get("pending_member_ids", []))


@router.post("/{space_id}/approve/{user_id}", response_model=JoinRequestResponse)
async def approve_join_request(
    space_id: str,
    user_id: str,
    current_user: dict = Depends(get_current_user),
    db=Depends(get_database)
):
    """Approve a join request (creator only)."""
    if not ObjectId.is_valid(space_id) or not ObjectId.is_valid(user_id):
        raise HTTPException(400, "Invalid ID")
    space = await db[mongodb.TRAVEL_SPACES].find_one({"_id": ObjectId(space_id)})
    if not space:
        raise HTTPException(404, "Travel space not found")
    if space["creator_id"] != current_user["_id"]:
        raise HTTPException(403, "Only the creator can approve requests")
    if user_id not in space.get("pending_member_ids", []):
        raise HTTPException(400, "User has not requested to join")
    await db[mongodb.TRAVEL_SPACES].update_one(
        {"_id": ObjectId(space_id)},
        {
            "$pull": {"pending_member_ids": user_id},
            "$addToSet": {"member_ids": user_id},
            "$set": {"updated_at": datetime.utcnow()}
        }
    )
    updated = await db[mongodb.TRAVEL_SPACES].find_one({"_id": ObjectId(space_id)})
    return JoinRequestResponse(success=True, message="User approved", pending_members=updated.get("pending_member_ids", []))


@router.post("/{space_id}/leave")
async def leave_travel_space(
    space_id: str,
    current_user: dict = Depends(get_current_user),
    db=Depends(get_database)
):
    """Leave a travel space (cannot leave if you are the creator)."""
    if not ObjectId.is_valid(space_id):
        raise HTTPException(400, "Invalid space ID")
    space = await db[mongodb.TRAVEL_SPACES].find_one({"_id": ObjectId(space_id)})
    if not space:
        raise HTTPException(404, "Travel space not found")
    if current_user["_id"] == space["creator_id"]:
        raise HTTPException(400, "Creator cannot leave. Delete the space instead.")
    if current_user["_id"] not in space.get("member_ids", []):
        raise HTTPException(400, "You are not a member")
    await db[mongodb.TRAVEL_SPACES].update_one(
        {"_id": ObjectId(space_id)},
        {"$pull": {"member_ids": current_user["_id"]}, "$set": {"updated_at": datetime.utcnow()}}
    )
    return {"success": True, "message": "You have left the space"}


@router.delete("/{space_id}")
async def delete_travel_space(
    space_id: str,
    current_user: dict = Depends(get_current_user),
    db=Depends(get_database)
):
    """Delete a travel space (creator only)."""
    if not ObjectId.is_valid(space_id):
        raise HTTPException(400, "Invalid space ID")
    space = await db[mongodb.TRAVEL_SPACES].find_one({"_id": ObjectId(space_id)})
    if not space:
        raise HTTPException(404, "Travel space not found")
    if space["creator_id"] != current_user["_id"]:
        raise HTTPException(403, "Only the creator can delete the space")
    await db[mongodb.TRAVEL_SPACES].delete_one({"_id": ObjectId(space_id)})
    return {"success": True, "message": "Travel space deleted"}