"""
Chat API endpoints for AI Travel Assistant
Handles all chat-related API routes
"""
from fastapi import APIRouter, HTTPException, status
from typing import Dict, List
from datetime import datetime

from app.schemas.chat import (
    ChatRequest, 
    ChatResponse, 
    ConversationHistoryResponse,
    ConversationClearResponse,
    ChatMessage
)
from app.services.ai_assistant import ai_assistant
from app.mongodb import get_database, mongodb

# Create router with prefix and tags
router = APIRouter(
    prefix="/api/v1/chat",
    tags=["AI Travel Assistant"]
)


@router.post("/", response_model=ChatResponse, status_code=status.HTTP_200_OK)
async def send_message(request: ChatRequest):
    """
    Send a message to the AI travel assistant
    
    The AI assistant provides:
    - Egypt-specific travel advice
    - Safety recommendations
    - Cultural guidance
    - Accessibility information
    - Scam awareness
    - Emergency information
    
    Context awareness:
    - Gender-specific safety tips (especially for women)
    - Solo travel recommendations
    - Accessibility accommodations
    - First-time visitor guidance
    
    Args:
        request: ChatRequest with message, optional conversation_id, and user_context
        
    Returns:
        ChatResponse with AI message, conversation_id, and suggestions
        
    Raises:
        HTTPException: If chat processing fails
    
    Example:
        ```json
        {
            "message": "I'm arriving at Cairo Airport tomorrow",
            "user_context": {
                "gender": "female",
                "traveling_alone": true
            }
        }
        ```
    """
    try:
        result = await ai_assistant.chat(
            message=request.message,
            conversation_id=request.conversation_id,
            user_context=request.user_context
        )

        # Persist conversation to MongoDB
        db = get_database()
        conv_id = result["conversation_id"]
        now = result["timestamp"]
        messages = [
            {"role": "user", "content": request.message, "timestamp": now},
            {"role": "assistant", "content": result["message"], "timestamp": now},
        ]

        await db[mongodb.CONVERSATIONS].update_one(
            {"conversation_id": conv_id},
            {
                "$setOnInsert": {
                    "conversation_id": conv_id,
                    "created_at": now,
                    "is_active": True,
                    "is_archived": False,
                },
                "$push": {"messages": {"$each": messages}},
                "$set": {
                    "last_message_at": now,
                    "last_suggestions": result.get("suggestions") or [],
                    "user_context": request.user_context,
                },
                "$inc": {"message_count": 2},
            },
            upsert=True,
        )
        
        return ChatResponse(**result)
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to process chat request: {str(e)}"
        )


@router.get("/conversation/{conversation_id}", response_model=ConversationHistoryResponse)
async def get_conversation_history(conversation_id: str):
    """
    Get conversation history by ID
    
    Args:
        conversation_id: The conversation ID to retrieve
        
    Returns:
        ConversationHistoryResponse with full message history
        
    Raises:
        HTTPException: If conversation not found
    """
    history = ai_assistant.get_conversation_history(conversation_id)
    
    if history is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Conversation '{conversation_id}' not found"
        )
    
    # Convert to ChatMessage objects
    messages = [
        ChatMessage(role=msg["role"], content=msg["content"]) 
        for msg in history
    ]
    
    return ConversationHistoryResponse(
        conversation_id=conversation_id,
        messages=messages,
        created_at=datetime.now(),  # TODO: Get from database
        updated_at=datetime.now()
    )


@router.delete("/conversation/{conversation_id}", response_model=ConversationClearResponse)
async def clear_conversation(conversation_id: str):
    """
    Clear conversation history
    
    Useful for:
    - Starting a fresh conversation
    - Managing memory/context
    - Privacy/GDPR compliance
    
    Args:
        conversation_id: The conversation ID to clear
        
    Returns:
        ConversationClearResponse confirming deletion
        
    Raises:
        HTTPException: If conversation not found
    """
    success = ai_assistant.clear_conversation(conversation_id)
    
    if not success:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Conversation '{conversation_id}' not found"
        )
    
    return ConversationClearResponse(
        message="Conversation cleared successfully",
        conversation_id=conversation_id
    )


@router.get("/conversations", response_model=Dict[str, int])
async def list_all_conversations():
    """
    List all active conversations
    
    Returns:
        Dict mapping conversation_id to message count
        
    Note:
        In production, this should be user-specific and paginated
    """
    conversations = ai_assistant.get_all_conversations()
    
    return conversations


@router.post("/test", response_model=ChatResponse)
async def test_chat():
    """
    Test endpoint - sends a predefined message
    
    Useful for:
    - Verifying API is working
    - Testing AI integration
    - Demo purposes
    
    Returns:
        ChatResponse from AI assistant
    """
    test_request = ChatRequest(
        message="What are the top 3 safety tips for visiting Egypt?",
        user_context={
            "first_time_egypt": True
        }
    )
    
    try:
        result = await ai_assistant.chat(
            message=test_request.message,
            user_context=test_request.user_context
        )
        
        return ChatResponse(**result)
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Test request failed: {str(e)}"
        )