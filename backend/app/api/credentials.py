"""
Provider Credentials API – Upload and manage certifications
"""
from fastapi import APIRouter, HTTPException, Depends, UploadFile, File, Form
from typing import List
from datetime import datetime
import os
import uuid
from bson import ObjectId

from app.mongodb import get_database, mongodb
from app.schemas.credential import CredentialCreate, CredentialResponse, CredentialUploadResponse
from app.api.auth import get_current_user

router = APIRouter(prefix="/api/v1/providers/credentials", tags=["Provider Credentials"])


def _serialize(doc):
    if not doc:
        return doc
    doc["_id"] = str(doc["_id"])
    return doc


@router.get("/", response_model=List[CredentialResponse])
async def list_credentials(
    current_user: dict = Depends(get_current_user),
    db=Depends(get_database)
):
    """List all credentials for the current provider."""
    if current_user.get("account_type") != "service_provider":
        raise HTTPException(403, "Only service providers can manage credentials")
    cursor = db[mongodb.CREDENTIALS].find({"provider_id": current_user["_id"]}).sort("date_issued", -1)
    creds = []
    async for doc in cursor:
        creds.append(_serialize(doc))
    return creds


@router.post("/", response_model=CredentialUploadResponse)
async def upload_credential(
    title: str = Form(...),
    issuer: str = Form(...),
    date_issued: str = Form(...),
    expiry_date: str = Form(None),
    file: UploadFile = File(...),
    current_user: dict = Depends(get_current_user),
    db=Depends(get_database)
):
    """Upload a credential (PDF or image)."""
    if current_user.get("account_type") != "service_provider":
        raise HTTPException(403, "Only service providers can upload credentials")
    # Save file
    ext = os.path.splitext(file.filename)[1] if file.filename else ".pdf"
    filename = f"{uuid.uuid4().hex}{ext}"
    save_dir = os.path.normpath(os.path.join(os.path.dirname(__file__), "..", "..", "static", "creds"))
    os.makedirs(save_dir, exist_ok=True)
    dest_path = os.path.join(save_dir, filename)
    content = await file.read()
    with open(dest_path, "wb") as f:
        f.write(content)
    url = f"/static/creds/{filename}"
    # Create credential document
    doc = {
        "provider_id": current_user["_id"],
        "title": title,
        "issuer": issuer,
        "date_issued": datetime.strptime(date_issued, "%Y-%m-%d"),
        "expiry_date": datetime.strptime(expiry_date, "%Y-%m-%d") if expiry_date else None,
        "certificate_url": url,
        "is_verified": False,  # Admin verification later
        "created_at": datetime.utcnow()
    }
    result = await db[mongodb.CREDENTIALS].insert_one(doc)
    return CredentialUploadResponse(success=True, credential_id=str(result.inserted_id), certificate_url=url)


@router.delete("/{cred_id}")
async def delete_credential(
    cred_id: str,
    current_user: dict = Depends(get_current_user),
    db=Depends(get_database)
):
    """Delete a credential."""
    if not ObjectId.is_valid(cred_id):
        raise HTTPException(400, "Invalid credential ID")
    cred = await db[mongodb.CREDENTIALS].find_one({"_id": ObjectId(cred_id)})
    if not cred:
        raise HTTPException(404, "Credential not found")
    if cred["provider_id"] != current_user["_id"]:
        raise HTTPException(403, "You can only delete your own credentials")
    # Optionally delete file from disk
    await db[mongodb.CREDENTIALS].delete_one({"_id": ObjectId(cred_id)})
    return {"success": True, "message": "Credential deleted"}