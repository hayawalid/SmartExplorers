"""
Notifications API – In-app alerts
"""
from fastapi import APIRouter, HTTPException, Depends, Query
from typing import List
from datetime import datetime
from bson import ObjectId

from app.mongodb import get_database, mongodb
from app.schemas.notification import (
    NotificationCreate,
    NotificationResponse,
    MarkReadResponse
)
from app.api.auth import get_current_user

router = APIRouter(prefix="/api/v1/notifications", tags=["Notifications"])


def _serialize(doc):
    if not doc:
        return doc
    doc["_id"] = str(doc["_id"])
    return doc


@router.get("/", response_model=List[NotificationResponse])
async def get_notifications(
    limit: int = Query(50, ge=1, le=100),
    skip: int = Query(0, ge=0),
    unread_first: bool = Query(True),
    current_user: dict = Depends(get_current_user),
    db=Depends(get_database)
):
    """Get user's notifications, newest first, optionally unread first."""
    query = {"user_id": current_user["_id"]}
    sort = [("is_read", 1 if unread_first else -1), ("created_at", -1)]
    cursor = db[mongodb.NOTIFICATIONS].find(query).sort(sort).skip(skip).limit(limit)
    notifications = []
    async for doc in cursor:
        notifications.append(_serialize(doc))
    return notifications


@router.patch("/{notification_id}/read", response_model=MarkReadResponse)
async def mark_as_read(
    notification_id: str,
    current_user: dict = Depends(get_current_user),
    db=Depends(get_database)
):
    """Mark a single notification as read."""
    if not ObjectId.is_valid(notification_id):
        raise HTTPException(400, "Invalid notification ID")
    result = await db[mongodb.NOTIFICATIONS].update_one(
        {"_id": ObjectId(notification_id), "user_id": current_user["_id"]},
        {"$set": {"is_read": True}}
    )
    if result.modified_count == 0:
        raise HTTPException(404, "Notification not found or already read")
    return MarkReadResponse(success=True, notification_id=notification_id)


@router.post("/mark-all-read")
async def mark_all_read(
    current_user: dict = Depends(get_current_user),
    db=Depends(get_database)
):
    """Mark all of user's notifications as read."""
    await db[mongodb.NOTIFICATIONS].update_many(
        {"user_id": current_user["_id"], "is_read": False},
        {"$set": {"is_read": True}}
    )
    return {"success": True, "message": "All notifications marked as read"}


@router.delete("/{notification_id}")
async def delete_notification(
    notification_id: str,
    current_user: dict = Depends(get_current_user),
    db=Depends(get_database)
):
    """Delete a notification."""
    if not ObjectId.is_valid(notification_id):
        raise HTTPException(400, "Invalid notification ID")
    result = await db[mongodb.NOTIFICATIONS].delete_one(
        {"_id": ObjectId(notification_id), "user_id": current_user["_id"]}
    )
    if result.deleted_count == 0:
        raise HTTPException(404, "Notification not found")
    return {"success": True, "message": "Notification deleted"}


async def create_notification(notification: NotificationCreate, db):
    """Helper to create a notification (called from other modules)."""
    doc = notification.dict()
    doc["is_read"] = False
    doc["created_at"] = datetime.utcnow()
    await db[mongodb.NOTIFICATIONS].insert_one(doc)