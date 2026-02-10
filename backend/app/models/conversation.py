"""
Conversation model for AI Travel Assistant
Stores chat history in database
"""
from sqlalchemy import Column, String, Text, DateTime, JSON, Integer
from sqlalchemy.sql import func
from app.database import Base


class Conversation(Base):
    """Conversation model - stores chat history"""
    __tablename__ = "conversations"
    
    id = Column(Integer, primary_key=True, index=True)
    conversation_id = Column(String(50), unique=True, index=True, nullable=False)
    user_id = Column(Integer, nullable=True)  # Optional: link to user if authenticated
    
    # Conversation metadata
    messages = Column(JSON, default=list)  # Store messages as JSON array
    user_context = Column(JSON, nullable=True)  # Store user context
    
    # Timestamps
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    
    def __repr__(self):
        return f"<Conversation {self.conversation_id}>"


class ConversationMessage(Base):
    """Individual message model - alternative to storing in JSON"""
    __tablename__ = "conversation_messages"
    
    id = Column(Integer, primary_key=True, index=True)
    conversation_id = Column(String(50), index=True, nullable=False)
    
    # Message content
    role = Column(String(20), nullable=False)  # 'user' or 'assistant'
    content = Column(Text, nullable=False)
    
    # Metadata
    user_context = Column(JSON, nullable=True)
    
    # Timestamp
    timestamp = Column(DateTime(timezone=True), server_default=func.now())
    
    def __repr__(self):
        return f"<Message {self.conversation_id} - {self.role}>"