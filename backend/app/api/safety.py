from fastapi import APIRouter, Body, Query
from typing import Dict, Any, Optional, List
from bson import ObjectId

from app.mongodb import get_database, mongodb

router = APIRouter(prefix="/api/v1/safety", tags=["safety"])

# ── Embassy / Consulate directory for Egypt ──────────────────────────
# Keyed by ISO country name (lowercase). Numbers for embassies in Cairo.
EMBASSY_DIRECTORY: Dict[str, Dict[str, str]] = {
    "united states": {"name": "U.S. Embassy Cairo", "number": "+20 2 2797 3300", "address": "5 Tawfik Diab St, Garden City, Cairo"},
    "united kingdom": {"name": "British Embassy Cairo", "number": "+20 2 2791 6000", "address": "7 Ahmed Ragheb St, Garden City, Cairo"},
    "germany": {"name": "German Embassy Cairo", "number": "+20 2 2728 2000", "address": "2 Berlin St, Zamalek, Cairo"},
    "france": {"name": "French Embassy Cairo", "number": "+20 2 3567 3200", "address": "29 Charles de Gaulle St, Giza"},
    "italy": {"name": "Italian Embassy Cairo", "number": "+20 2 2794 3194", "address": "15 Abdel Rahman Fahmy St, Garden City, Cairo"},
    "spain": {"name": "Spanish Embassy Cairo", "number": "+20 2 2735 5813", "address": "41 Ismail Mohamed St, Zamalek, Cairo"},
    "canada": {"name": "Canadian Embassy Cairo", "number": "+20 2 2461 2200", "address": "Nile City Towers, Corniche El Nil, Cairo"},
    "australia": {"name": "Australian Embassy Cairo", "number": "+20 2 2770 6600", "address": "World Trade Center, Corniche El Nil, Cairo"},
    "japan": {"name": "Japanese Embassy Cairo", "number": "+20 2 2528 5910", "address": "81 Corniche El Nil, Maadi, Cairo"},
    "china": {"name": "Chinese Embassy Cairo", "number": "+20 2 2736 1219", "address": "14 Bahgat Ali St, Zamalek, Cairo"},
    "india": {"name": "Indian Embassy Cairo", "number": "+20 2 2736 0052", "address": "5 Aziz Abaza St, Zamalek, Cairo"},
    "brazil": {"name": "Brazilian Embassy Cairo", "number": "+20 2 2736 9538", "address": "1125 Corniche El Nil, Cairo"},
    "south korea": {"name": "Korean Embassy Cairo", "number": "+20 2 2761 1234", "address": "3 Boulos Hanna St, Dokki, Cairo"},
    "netherlands": {"name": "Dutch Embassy Cairo", "number": "+20 2 2739 5500", "address": "18 Hassan Sabry St, Zamalek, Cairo"},
    "saudi arabia": {"name": "Saudi Embassy Cairo", "number": "+20 2 2736 1922", "address": "2 Ahmed Nessim St, Giza"},
    "turkey": {"name": "Turkish Embassy Cairo", "number": "+20 2 2736 5718", "address": "25 Falaki St, Cairo"},
    "russia": {"name": "Russian Embassy Cairo", "number": "+20 2 2748 9353", "address": "95 El Giza St, Giza"},
    "south africa": {"name": "South African Embassy Cairo", "number": "+20 2 2571 7238", "address": "55 Road 18, Maadi, Cairo"},
    "mexico": {"name": "Mexican Embassy Cairo", "number": "+20 2 2735 9848", "address": "10 South St, Zamalek, Cairo"},
    "sweden": {"name": "Swedish Embassy Cairo", "number": "+20 2 2269 3700", "address": "Kent Acre Bldg, Corniche El Nil, Cairo"},
    "switzerland": {"name": "Swiss Embassy Cairo", "number": "+20 2 2575 8284", "address": "10 Abdel Khalek Sarwat St, Cairo"},
    "egypt": {"name": "Local Emergency Services", "number": "122", "address": "Egypt"},
}

# Standard Egypt emergency numbers
EGYPT_EMERGENCY_NUMBERS = [
    {"name": "Tourist Police", "number": "126", "icon": "shield", "category": "local"},
    {"name": "Ambulance", "number": "123", "icon": "heart_pulse", "category": "local"},
    {"name": "Fire Department", "number": "180", "icon": "flame", "category": "local"},
    {"name": "Local Police", "number": "122", "icon": "siren", "category": "local"},
    {"name": "Traffic Police", "number": "128", "icon": "car", "category": "local"},
]


def _serialize(doc: Dict[str, Any]) -> Dict[str, Any]:
    if not doc:
        return doc
    doc["_id"] = str(doc["_id"])
    return doc


@router.get("/{user_id}")
async def get_safety_profile(user_id: str):
    db = get_database()
    doc = await db[mongodb.SAFETY_PROFILES].find_one({"user_id": user_id})
    return _serialize(doc) or {"user_id": user_id, "live_tracking_enabled": False}


@router.put("/{user_id}")
async def upsert_safety_profile(user_id: str, payload: Dict[str, Any] = Body(...)):
    db = get_database()
    payload["user_id"] = user_id
    await db[mongodb.SAFETY_PROFILES].update_one(
        {"user_id": user_id}, {"$set": payload}, upsert=True
    )
    doc = await db[mongodb.SAFETY_PROFILES].find_one({"user_id": user_id})
    return _serialize(doc)


@router.get("/{user_id}/contacts")
async def list_emergency_contacts(user_id: str):
    db = get_database()
    cursor = db[mongodb.EMERGENCY_CONTACTS].find({"user_id": user_id})
    return [_serialize(doc) async for doc in cursor]


@router.post("/{user_id}/contacts")
async def create_emergency_contact(user_id: str, payload: Dict[str, Any] = Body(...)):
    db = get_database()
    payload["user_id"] = user_id
    result = await db[mongodb.EMERGENCY_CONTACTS].insert_one(payload)
    doc = await db[mongodb.EMERGENCY_CONTACTS].find_one({"_id": result.inserted_id})
    return _serialize(doc)


@router.delete("/contacts/{contact_id}")
async def delete_emergency_contact(contact_id: str):
    db = get_database()
    if not ObjectId.is_valid(contact_id):
        return {"detail": "Invalid contact_id"}
    result = await db[mongodb.EMERGENCY_CONTACTS].delete_one({"_id": ObjectId(contact_id)})
    return {"deleted": result.deleted_count == 1}


@router.get("/{user_id}/panic-events")
async def list_panic_events(user_id: str):
    db = get_database()
    cursor = db[mongodb.PANIC_EVENTS].find({"user_id": user_id}).sort("timestamp", -1)
    return [_serialize(doc) async for doc in cursor]


@router.post("/{user_id}/panic-events")
async def create_panic_event(user_id: str, payload: Dict[str, Any] = Body(...)):
    db = get_database()
    payload["user_id"] = user_id
    result = await db[mongodb.PANIC_EVENTS].insert_one(payload)
    doc = await db[mongodb.PANIC_EVENTS].find_one({"_id": result.inserted_id})
    return _serialize(doc)


@router.get("/emergency-numbers/{country}")
async def get_emergency_numbers(country: str):
    """
    Return local Egypt emergency numbers + the user's home country embassy info.
    Country should be the user's country of origin (e.g., 'Germany', 'United States').
    """
    numbers = list(EGYPT_EMERGENCY_NUMBERS)

    # Look up embassy for the user's home country
    key = country.lower().strip()
    embassy = EMBASSY_DIRECTORY.get(key)
    if embassy:
        numbers.append({
            "name": embassy["name"],
            "number": embassy["number"],
            "icon": "landmark",
            "category": "embassy",
            "address": embassy["address"],
        })

    return {"country": country, "emergency_numbers": numbers}


@router.get("/embassies")
async def list_all_embassies():
    """Return full embassy directory."""
    return {"embassies": EMBASSY_DIRECTORY}

