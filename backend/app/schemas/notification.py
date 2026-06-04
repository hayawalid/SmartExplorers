"""
Notification Schemas
"""
from pydantic import BaseModel, Field
from typing import Optional, Dict, Any
from datetime import datetime
from enum import Enum


class NotificationType(str, Enum):
    BOOKING_UPDATE = "booking_update"
    NEW_MESSAGE = "new_message"
    REVIEW_RECEIVED = "review_received"
    SYSTEM = "system"


class NotificationCreate(BaseModel):
    user_id: str
    type: NotificationType
    title: str
    body: str
    data: Optional[Dict[str, Any]] = None


class NotificationResponse(BaseModel):
    id: str
    user_id: str
    type: NotificationType
    title: str
    body: str
    data: Optional[Dict[str, Any]] = None
    is_read: bool
    created_at: datetime

    class Config:
        from_attributes = True


class MarkReadResponse(BaseModel):
    success: bool
    notification_id: str