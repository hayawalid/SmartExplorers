"""
User Messaging Schemas (User-to-User chat)
"""
from pydantic import BaseModel, Field
from typing import List, Optional
from datetime import datetime


class ConversationCreate(BaseModel):
    participant_id: str  # The other user's ID


class ConversationResponse(BaseModel):
    id: str
    participant_ids: List[str]
    other_user_id: str
    other_user_name: str
    other_user_avatar: Optional[str]
    last_message: Optional[str]
    last_message_at: Optional[datetime]
    is_archived: bool
    created_at: datetime

    class Config:
        from_attributes = True


class MessageSend(BaseModel):
    content: str = Field(..., min_length=1, max_length=2000)


class MessageResponse(BaseModel):
    id: str
    conversation_id: str
    sender_id: str
    content: str
    content_moderated: bool
    created_at: datetime

    class Config:
        from_attributes = True


class MessageListResponse(BaseModel):
    messages: List[MessageResponse]
    has_more: bool
    next_cursor: Optional[str] = None