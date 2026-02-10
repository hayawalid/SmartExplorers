"""
Chat schemas for AI Travel Assistant
Separate from itinerary schemas to avoid conflicts
"""
from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime


class ChatMessage(BaseModel):
    """Single chat message in conversation"""
    role: str = Field(..., description="Message role: 'user' or 'assistant'")
    content: str = Field(..., description="Message content")
    timestamp: Optional[datetime] = None


class ChatRequest(BaseModel):
    """Request schema for chat endpoint"""
    message: str = Field(
        ..., 
        min_length=1, 
        max_length=2000, 
        description="User's message to the AI assistant"
    )
    conversation_id: Optional[str] = Field(
        None, 
        description="Optional conversation ID to continue existing conversation"
    )
    user_context: Optional[dict] = Field(
        None, 
        description="User context: gender, traveling_alone, accessibility_needs, etc."
    )
    
    class Config:
        json_schema_extra = {
            "example": {
                "message": "I'm arriving at Cairo Airport tomorrow. What should I know?",
                "user_context": {
                    "gender": "female",
                    "traveling_alone": True,
                    "accessibility_needs": []
                }
            }
        }


class ChatResponse(BaseModel):
    """Response schema from AI assistant"""
    message: str = Field(..., description="AI assistant's response")
    conversation_id: str = Field(..., description="Conversation ID for context continuity")
    suggestions: Optional[List[str]] = Field(
        default=None, 
        description="Suggested follow-up questions"
    )
    timestamp: datetime = Field(default_factory=datetime.now)
    
    class Config:
        json_schema_extra = {
            "example": {
                "message": "Welcome to Egypt! Here are key things about Cairo Airport...",
                "conversation_id": "conv_abc123def",
                "suggestions": [
                    "How do I get from the airport to my hotel safely?",
                    "What are common scams to avoid?",
                    "Do I need a visa on arrival?"
                ],
                "timestamp": "2026-02-10T17:00:00"
            }
        }


class ConversationHistoryResponse(BaseModel):
    """Response schema for conversation history"""
    conversation_id: str
    messages: List[ChatMessage]
    created_at: datetime
    updated_at: datetime


class ConversationClearResponse(BaseModel):
    """Response when clearing a conversation"""
    message: str
    conversation_id: str
    cleared_at: datetime = Field(default_factory=datetime.now)
