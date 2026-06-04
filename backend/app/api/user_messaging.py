"""
User-to-User Messaging API
Separate from AI Assistant chat (app/api/chat.py)
"""
from fastapi import APIRouter, HTTPException, Depends, Query
from typing import List, Optional
from datetime import datetime
from bson import ObjectId

from app.mongodb import get_database, mongodb
from app.schemas.user_messaging import (  # see schemas below
    ConversationCreate,
    ConversationResponse,
    MessageSend,
    MessageResponse,
    MessageListResponse
)
from app.api.auth import get_current_user
from app.api.notifications import create_notification
from app.schemas.notification import NotificationCreate, NotificationType

router = APIRouter(prefix="/api/v1/messages", tags=["User Messaging"])


def _serialize(doc):
    if not doc:
        return doc
    doc["_id"] = str(doc["_id"])
    return doc


# Simple profanity filter (replace with a proper library like `better_profanity`)
PROFANITY_LIST = ["badword1", "badword2", "scam", "fraud"]  # expand as needed

def moderate_content(content: str) -> tuple[str, bool, List[str]]:
    """Returns (sanitized_content, was_moderated, flags)"""
    content_lower = content.lower()
    flags = [word for word in PROFANITY_LIST if word in content_lower]
    if flags:
        return "[Message blocked by moderation]", True, flags
    return content, False, []


@router.post("/conversations", response_model=ConversationResponse)
async def start_conversation(
    data: ConversationCreate,
    current_user: dict = Depends(get_current_user),
    db=Depends(get_database)
):
    """Start a new conversation with another user."""
    participant_ids = sorted([current_user["_id"], data.participant_id])
    # Check if conversation already exists
    existing = await db[mongodb.USER_CONVERSATIONS].find_one({
        "participant_ids": participant_ids
    })
    if existing:
        existing = _serialize(existing)
        other_id = data.participant_id
        other_user = await db[mongodb.USERS].find_one({"_id": ObjectId(other_id)})
        return {
            "id": existing["_id"],
            "participant_ids": existing["participant_ids"],
            "other_user_id": other_id,
            "other_user_name": other_user.get("full_name", "Unknown"),
            "other_user_avatar": other_user.get("avatar_url"),
            "last_message": existing.get("last_message"),
            "last_message_at": existing.get("last_message_at"),
            "is_archived": existing.get("is_archived", False),
            "created_at": existing["created_at"],
        }
    # Create new conversation
    now = datetime.utcnow()
    doc = {
        "participant_ids": participant_ids,
        "created_at": now,
        "last_message": None,
        "last_message_at": now,
        "is_archived": False,
        "safety_flags": []
    }
    result = await db[mongodb.USER_CONVERSATIONS].insert_one(doc)
    conv_id = str(result.inserted_id)
    other_user = await db[mongodb.USERS].find_one({"_id": ObjectId(data.participant_id)})
    return {
        "id": conv_id,
        "participant_ids": participant_ids,
        "other_user_id": data.participant_id,
        "other_user_name": other_user.get("full_name", "Unknown"),
        "other_user_avatar": other_user.get("avatar_url"),
        "last_message": None,
        "last_message_at": now,
        "is_archived": False,
        "created_at": now,
    }


@router.get("/conversations", response_model=List[ConversationResponse])
async def list_conversations(
    current_user: dict = Depends(get_current_user),
    db=Depends(get_database)
):
    """List user's conversations, sorted by last_message_at descending, unarchived first."""
    cursor = db[mongodb.USER_CONVERSATIONS].find({
        "participant_ids": current_user["_id"]
    }).sort([("is_archived", 1), ("last_message_at", -1)])
    convs = []
    async for doc in cursor:
        doc = _serialize(doc)
        other_id = next(pid for pid in doc["participant_ids"] if pid != current_user["_id"])
        other_user = await db[mongodb.USERS].find_one({"_id": ObjectId(other_id)})
        convs.append({
            "id": doc["_id"],
            "participant_ids": doc["participant_ids"],
            "other_user_id": other_id,
            "other_user_name": other_user.get("full_name", "Unknown"),
            "other_user_avatar": other_user.get("avatar_url"),
            "last_message": doc.get("last_message"),
            "last_message_at": doc.get("last_message_at"),
            "is_archived": doc.get("is_archived", False),
            "created_at": doc["created_at"],
        })
    return convs


@router.post("/conversations/{conv_id}/messages", response_model=MessageResponse)
async def send_message(
    conv_id: str,
    data: MessageSend,
    current_user: dict = Depends(get_current_user),
    db=Depends(get_database)
):
    """Send a message in a conversation. Auto-moderation applied."""
    if not ObjectId.is_valid(conv_id):
        raise HTTPException(400, "Invalid conversation ID")
    conv = await db[mongodb.USER_CONVERSATIONS].find_one({"_id": ObjectId(conv_id)})
    if not conv:
        raise HTTPException(404, "Conversation not found")
    if current_user["_id"] not in conv["participant_ids"]:
        raise HTTPException(403, "You are not a participant in this conversation")
    # Moderate content
    moderated_content, was_moderated, flags = moderate_content(data.content)
    now = datetime.utcnow()
    msg_doc = {
        "conversation_id": conv_id,
        "sender_id": current_user["_id"],
        "content": moderated_content,
        "content_moderated": was_moderated,
        "moderation_flags": flags,
        "is_deleted": False,
        "created_at": now,
    }
    result = await db[mongodb.MESSAGES].insert_one(msg_doc)
    msg_doc["_id"] = str(result.inserted_id)
    # Update conversation last_message
    await db[mongodb.USER_CONVERSATIONS].update_one(
        {"_id": ObjectId(conv_id)},
        {"$set": {"last_message": moderated_content[:100], "last_message_at": now}}
    )
    # Create notification for the other participant
    other_id = next(pid for pid in conv["participant_ids"] if pid != current_user["_id"])
    await create_notification(
        NotificationCreate(
            user_id=other_id,
            type=NotificationType.NEW_MESSAGE,
            title="New message",
            body=f"{current_user.get('full_name', 'Someone')} sent you a message",
            data={"conversation_id": conv_id}
        ),
        db
    )
    return {
        "id": msg_doc["_id"],
        "conversation_id": conv_id,
        "sender_id": current_user["_id"],
        "content": moderated_content,
        "content_moderated": was_moderated,
        "created_at": now,
    }


@router.get("/conversations/{conv_id}/messages", response_model=MessageListResponse)
async def get_messages(
    conv_id: str,
    limit: int = Query(20, ge=1, le=100),
    before: Optional[str] = Query(None, description="Message ID to paginate before"),
    current_user: dict = Depends(get_current_user),
    db=Depends(get_database)
):
    """Get messages in a conversation, newest first, paginated."""
    if not ObjectId.is_valid(conv_id):
        raise HTTPException(400, "Invalid conversation ID")
    conv = await db[mongodb.USER_CONVERSATIONS].find_one({"_id": ObjectId(conv_id)})
    if not conv:
        raise HTTPException(404, "Conversation not found")
    if current_user["_id"] not in conv["participant_ids"]:
        raise HTTPException(403, "You are not a participant")
    query = {"conversation_id": conv_id}
    if before and ObjectId.is_valid(before):
        query["_id"] = {"$lt": ObjectId(before)}
    cursor = db[mongodb.MESSAGES].find(query).sort("created_at", -1).limit(limit)
    messages = []
    async for doc in cursor:
        doc = _serialize(doc)
        messages.append(doc)
    has_more = len(messages) == limit
    next_cursor = messages[-1]["_id"] if has_more else None
    return MessageListResponse(messages=messages, has_more=has_more, next_cursor=next_cursor)


@router.patch("/conversations/{conv_id}/archive")
async def archive_conversation(
    conv_id: str,
    current_user: dict = Depends(get_current_user),
    db=Depends(get_database)
):
    """Archive or unarchive a conversation."""
    if not ObjectId.is_valid(conv_id):
        raise HTTPException(400, "Invalid conversation ID")
    conv = await db[mongodb.USER_CONVERSATIONS].find_one({"_id": ObjectId(conv_id)})
    if not conv:
        raise HTTPException(404, "Conversation not found")
    if current_user["_id"] not in conv["participant_ids"]:
        raise HTTPException(403, "Not a participant")
    new_archived = not conv.get("is_archived", False)
    await db[mongodb.USER_CONVERSATIONS].update_one(
        {"_id": ObjectId(conv_id)},
        {"$set": {"is_archived": new_archived}}
    )
    return {"success": True, "is_archived": new_archived}