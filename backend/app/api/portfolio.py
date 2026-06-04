"""
Provider Portfolio API – Upload and manage portfolio images
"""
from fastapi import APIRouter, HTTPException, Depends, UploadFile, File, Form
from typing import List
from datetime import datetime
import os
import uuid
from bson import ObjectId

from app.mongodb import get_database, mongodb
from app.schemas.portfolio import PortfolioItemCreate, PortfolioItemResponse, PortfolioUploadResponse
from app.api.auth import get_current_user

router = APIRouter(prefix="/api/v1/providers/portfolio", tags=["Provider Portfolio"])


def _serialize(doc):
    if not doc:
        return doc
    doc["_id"] = str(doc["_id"])
    return doc


@router.get("/", response_model=List[PortfolioItemResponse])
async def list_portfolio(
    current_user: dict = Depends(get_current_user),
    db=Depends(get_database)
):
    """List all portfolio items for the current provider."""
    if current_user.get("account_type") != "service_provider":
        raise HTTPException(403, "Only service providers can manage portfolio")
    cursor = db[mongodb.PORTFOLIO_ITEMS].find({"provider_id": current_user["_id"]}).sort("created_at", -1)
    items = []
    async for doc in cursor:
        items.append(_serialize(doc))
    return items


@router.post("/", response_model=PortfolioUploadResponse)
async def upload_portfolio_item(
    title: str = Form(...),
    category: str = Form(None),
    file: UploadFile = File(...),
    current_user: dict = Depends(get_current_user),
    db=Depends(get_database)
):
    """Upload a portfolio image."""
    if current_user.get("account_type") != "service_provider":
        raise HTTPException(403, "Only service providers can upload portfolio")
    # Save image
    ext = os.path.splitext(file.filename)[1] if file.filename else ".jpg"
    filename = f"{uuid.uuid4().hex}{ext}"
    save_dir = os.path.normpath(os.path.join(os.path.dirname(__file__), "..", "..", "static", "portfolio"))
    os.makedirs(save_dir, exist_ok=True)
    dest_path = os.path.join(save_dir, filename)
    content = await file.read()
    with open(dest_path, "wb") as f:
        f.write(content)
    url = f"/static/portfolio/{filename}"
    # Create portfolio item
    doc = {
        "provider_id": current_user["_id"],
        "title": title,
        "category": category,
        "image_url": url,
        "likes": 0,
        "created_at": datetime.utcnow()
    }
    result = await db[mongodb.PORTFOLIO_ITEMS].insert_one(doc)
    return PortfolioUploadResponse(success=True, portfolio_id=str(result.inserted_id), image_url=url)


@router.delete("/{item_id}")
async def delete_portfolio_item(
    item_id: str,
    current_user: dict = Depends(get_current_user),
    db=Depends(get_database)
):
    """Delete a portfolio item."""
    if not ObjectId.is_valid(item_id):
        raise HTTPException(400, "Invalid item ID")
    item = await db[mongodb.PORTFOLIO_ITEMS].find_one({"_id": ObjectId(item_id)})
    if not item:
        raise HTTPException(404, "Portfolio item not found")
    if item["provider_id"] != current_user["_id"]:
        raise HTTPException(403, "You can only delete your own portfolio items")
    # Optionally delete file from disk
    await db[mongodb.PORTFOLIO_ITEMS].delete_one({"_id": ObjectId(item_id)})
    return {"success": True, "message": "Portfolio item deleted"}