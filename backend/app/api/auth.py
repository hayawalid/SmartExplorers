"""
Authentication endpoints – signup & login
"""
from datetime import datetime, timedelta
from typing import Dict, Any, List, Optional

from fastapi import APIRouter, HTTPException, Body, Request
from pydantic import BaseModel, EmailStr
import bcrypt
from jose import jwt

from app.config import settings
from app.mongodb import get_database, mongodb

router = APIRouter(prefix="/api/v1/auth", tags=["auth"])

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _hash_password(password: str) -> str:
    return bcrypt.hashpw(password.encode("utf-8"), bcrypt.gensalt()).decode("utf-8")


def _verify_password(plain: str, hashed: str) -> bool:
    return bcrypt.checkpw(plain.encode("utf-8"), hashed.encode("utf-8"))


def _create_access_token(data: dict, expires_minutes: Optional[int] = None) -> str:
    to_encode = data.copy()
    expire = datetime.utcnow() + timedelta(
        minutes=expires_minutes or settings.ACCESS_TOKEN_EXPIRE_MINUTES or 1440
    )
    to_encode["exp"] = expire
    return jwt.encode(
        to_encode,
        settings.SECRET_KEY or "dev-secret-key-change-in-production",
        algorithm=settings.ALGORITHM or "HS256",
    )


def _serialize_user(request: Request, doc: Dict[str, Any]) -> Dict[str, Any]:
    """Return a safe copy of the user document (no password)."""
    if not doc:
        return doc
    out = {**doc}
    out["_id"] = str(out["_id"])
    out.pop("hashed_password", None)
    out.pop("password", None)
    if out.get("avatar_url") and out["avatar_url"].startswith("/"):
        out["avatar_url"] = str(request.base_url).rstrip("/") + out["avatar_url"]
    if out.get("profile_picture_url") and out["profile_picture_url"].startswith("/"):
        out["profile_picture_url"] = str(request.base_url).rstrip("/") + out["profile_picture_url"]
    return out


# ---------------------------------------------------------------------------
# Request / Response schemas
# ---------------------------------------------------------------------------

class SignupRequest(BaseModel):
    email: EmailStr
    username: str
    password: str
    full_name: str
    account_type: str = "traveler"  # traveler | service_provider
    phone_number: Optional[str] = None
    # Traveler-specific onboarding fields (optional, sent together)
    country_of_origin: Optional[str] = None
    preferred_language: Optional[str] = None
    travel_interests: Optional[List[str]] = None
    accessibility_needs: Optional[List[str]] = None
    # Common optional fields
    date_of_birth: Optional[str] = None
    gender: Optional[str] = None
    # Provider-specific onboarding fields (optional)
    service_type: Optional[str] = None
    bio: Optional[str] = None


class LoginRequest(BaseModel):
    email: EmailStr
    password: str


# ---------------------------------------------------------------------------
# Endpoints
# ---------------------------------------------------------------------------

@router.post("/signup")
async def signup(body: SignupRequest, request: Request):
    db = get_database()

    # Check for duplicate email / username
    existing = await db[mongodb.USERS].find_one({"email": body.email})
    if existing:
        raise HTTPException(status_code=409, detail="Email already registered")

    existing = await db[mongodb.USERS].find_one({"username": body.username})
    if existing:
        raise HTTPException(status_code=409, detail="Username already taken")

    # Build user document
    now = datetime.utcnow()
    user_doc = {
        "email": body.email,
        "username": body.username,
        "hashed_password": _hash_password(body.password),
        "full_name": body.full_name,
        "account_type": body.account_type,
        "phone_number": body.phone_number,
        "avatar_url": None,
        "bio": body.bio,
        "date_of_birth": body.date_of_birth,
        "gender": body.gender,
        "is_verified": False,
        "is_active": True,
        "created_at": now,
        "updated_at": now,
    }

    result = await db[mongodb.USERS].insert_one(user_doc)
    user_id = str(result.inserted_id)

    # ── Save profile based on account type ──
    if body.account_type == "traveler":
        profile_doc = {
            "user_id": user_id,
            "full_name": body.full_name,
            "phone_number": body.phone_number,
            "country_of_origin": body.country_of_origin,
            "preferred_language": body.preferred_language,
            "travel_interests": body.travel_interests or [],
            "accessibility_needs": body.accessibility_needs or [],
            "wheelchair_access": "Wheelchair Access" in (body.accessibility_needs or []),
            "visual_assistance": "Visual Assistance" in (body.accessibility_needs or []),
            "hearing_assistance": "Hearing Assistance" in (body.accessibility_needs or []),
            "mobility_support": "Mobility Support" in (body.accessibility_needs or []),
            "dietary_restrictions_flag": "Dietary Restrictions" in (body.accessibility_needs or []),
            "sensory_sensitivity": "Sensory Sensitivity" in (body.accessibility_needs or []),
            "created_at": now,
            "updated_at": now,
        }
        await db[mongodb.TRAVELER_PROFILES].update_one(
            {"user_id": user_id}, {"$set": profile_doc}, upsert=True
        )
    else:
        profile_doc = {
            "user_id": user_id,
            "full_legal_name": body.full_name,
            "phone_number": body.phone_number,
            "bio": body.bio,
            "service_type": body.service_type,
            "verification_status": "pending",
            "verified_flag": False,
            "created_at": now,
            "updated_at": now,
        }
        await db[mongodb.SERVICE_PROVIDER_PROFILES].update_one(
            {"user_id": user_id}, {"$set": profile_doc}, upsert=True
        )

    # ── Save default preferences ──
    prefs_doc = {
        "user_id": user_id,
        "theme": "system",
        "travel_interests": body.travel_interests or [],
        "accessibility_needs": body.accessibility_needs or [],
        "preferred_language": body.preferred_language,
        "country_of_origin": body.country_of_origin,
        "created_at": now,
        "updated_at": now,
    }
    await db[mongodb.USER_PREFERENCES].update_one(
        {"user_id": user_id}, {"$set": prefs_doc}, upsert=True
    )

    # ── Build response ──
    user_doc["_id"] = result.inserted_id
    token = _create_access_token({"sub": user_id, "username": body.username})

    return {
        "access_token": token,
        "token_type": "bearer",
        "user": _serialize_user(request, user_doc),
    }


@router.post("/login")
async def login(body: LoginRequest, request: Request):
    db = get_database()

    user = await db[mongodb.USERS].find_one({"email": body.email})
    if not user:
        raise HTTPException(status_code=401, detail="Invalid email or password")

    hashed = user.get("hashed_password", "")
    if not hashed or not _verify_password(body.password, hashed):
        raise HTTPException(status_code=401, detail="Invalid email or password")

    user_id = str(user["_id"])
    token = _create_access_token({"sub": user_id, "username": user.get("username", "")})

    return {
        "access_token": token,
        "token_type": "bearer",
        "user": _serialize_user(request, user),
    }
