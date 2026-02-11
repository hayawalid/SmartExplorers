from fastapi import APIRouter, HTTPException, Body
from typing import Dict, Any, List
from bson import ObjectId

from app.mongodb import get_database, mongodb

router = APIRouter(prefix="/api/v1/profiles", tags=["profiles"])


def _serialize(doc: Dict[str, Any]) -> Dict[str, Any]:
    if not doc:
        return doc
    doc["_id"] = str(doc["_id"])
    return doc


@router.get("/travelers/{user_id}")
async def get_traveler_profile(user_id: str):
    db = get_database()
    doc = await db[mongodb.TRAVELER_PROFILES].find_one({"user_id": user_id})
    if not doc:
        raise HTTPException(status_code=404, detail="Traveler profile not found")
    return _serialize(doc)


@router.put("/travelers/{user_id}")
async def upsert_traveler_profile(user_id: str, payload: Dict[str, Any] = Body(...)):
    db = get_database()
    payload["user_id"] = user_id

    await db[mongodb.TRAVELER_PROFILES].update_one(
        {"user_id": user_id}, {"$set": payload}, upsert=True
    )
    doc = await db[mongodb.TRAVELER_PROFILES].find_one({"user_id": user_id})
    return _serialize(doc)


@router.get("/providers/{user_id}")
async def get_provider_profile(user_id: str):
    db = get_database()
    doc = await db[mongodb.SERVICE_PROVIDER_PROFILES].find_one({"user_id": user_id})
    if not doc:
        raise HTTPException(status_code=404, detail="Provider profile not found")
    return _serialize(doc)


@router.put("/providers/{user_id}")
async def upsert_provider_profile(user_id: str, payload: Dict[str, Any] = Body(...)):
    db = get_database()
    payload["user_id"] = user_id

    await db[mongodb.SERVICE_PROVIDER_PROFILES].update_one(
        {"user_id": user_id}, {"$set": payload}, upsert=True
    )
    doc = await db[mongodb.SERVICE_PROVIDER_PROFILES].find_one({"user_id": user_id})
    return _serialize(doc)


@router.get("/providers/{provider_id}/portfolio")
async def list_portfolio(provider_id: str):
    db = get_database()
    cursor = db[mongodb.PORTFOLIO_ITEMS].find({"provider_id": provider_id})
    return [
        _serialize(doc)
        async for doc in cursor
    ]


@router.post("/providers/{provider_id}/portfolio")
async def create_portfolio_item(provider_id: str, payload: Dict[str, Any] = Body(...)):
    db = get_database()
    payload["provider_id"] = provider_id
    result = await db[mongodb.PORTFOLIO_ITEMS].insert_one(payload)
    doc = await db[mongodb.PORTFOLIO_ITEMS].find_one({"_id": result.inserted_id})
    return _serialize(doc)


@router.get("/providers/{provider_id}/credentials")
async def list_credentials(provider_id: str):
    db = get_database()
    cursor = db[mongodb.CREDENTIALS].find({"provider_id": provider_id})
    return [
        _serialize(doc)
        async for doc in cursor
    ]


@router.post("/providers/{provider_id}/credentials")
async def create_credential(provider_id: str, payload: Dict[str, Any] = Body(...)):
    db = get_database()
    payload["provider_id"] = provider_id
    result = await db[mongodb.CREDENTIALS].insert_one(payload)
    doc = await db[mongodb.CREDENTIALS].find_one({"_id": result.inserted_id})
    return _serialize(doc)
