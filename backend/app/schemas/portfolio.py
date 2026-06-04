"""
Portfolio Schemas for provider images
"""
from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime


class PortfolioItemCreate(BaseModel):
    title: str = Field(..., max_length=200)
    category: Optional[str] = Field(None, max_length=50)


class PortfolioItemResponse(BaseModel):
    id: str
    provider_id: str
    title: str
    image_url: str
    category: Optional[str]
    likes: int
    created_at: datetime

    class Config:
        from_attributes = True


class PortfolioUploadResponse(BaseModel):
    success: bool
    portfolio_id: str
    image_url: str