from fastapi import APIRouter, Body
from typing import Dict, Any, Optional, List
from bson import ObjectId

from app.mongodb import get_database, mongodb

router = APIRouter(prefix="/api/v1/social", tags=["social"])


def _serialize(doc: Dict[str, Any]) -> Dict[str, Any]:
    if not doc:
        return doc
    doc["_id"] = str(doc["_id"])
    return doc


@router.get("/posts")
async def list_posts(author_id: Optional[str] = None, limit: int = 50):
    db = get_database()
    query: Dict[str, Any] = {}
    if author_id:
        query["author_id"] = author_id

    cursor = db[mongodb.POSTS].find(query).sort("created_at", -1).limit(limit)
    results = []
    async for doc in cursor:
        post = _serialize(doc)
        author = None
        if post.get("author_id"):
            author = await db[mongodb.USERS].find_one({"_id": ObjectId(post["author_id"])})
        if author:
            post["author_username"] = author.get("username")
            post["author_avatar"] = author.get("avatar_url") or author.get("profile_picture_url")
            post["author_verified"] = author.get("verified_flag", False)
        results.append(post)
    return results


@router.post("/posts")
async def create_post(payload: Dict[str, Any] = Body(...)):
    db = get_database()
    result = await db[mongodb.POSTS].insert_one(payload)
    doc = await db[mongodb.POSTS].find_one({"_id": result.inserted_id})
    return _serialize(doc)


@router.get("/stories")
async def list_stories(user_id: Optional[str] = None, limit: int = 50):
    db = get_database()
    query: Dict[str, Any] = {}
    if user_id:
        query["user_id"] = user_id

    cursor = db[mongodb.STORIES].find(query).sort("created_at", -1).limit(limit)
    return [_serialize(doc) async for doc in cursor]


@router.post("/stories")
async def create_story(payload: Dict[str, Any] = Body(...)):
    db = get_database()
    result = await db[mongodb.STORIES].insert_one(payload)
    doc = await db[mongodb.STORIES].find_one({"_id": result.inserted_id})
    return _serialize(doc)


@router.get("/photos")
async def list_photos(user_id: Optional[str] = None, limit: int = 100):
    db = get_database()
    query: Dict[str, Any] = {}
    if user_id:
        query["user_id"] = user_id

    cursor = db[mongodb.PHOTOS].find(query).sort("created_at", -1).limit(limit)
    return [_serialize(doc) async for doc in cursor]


@router.post("/photos")
async def create_photo(payload: Dict[str, Any] = Body(...)):
    db = get_database()
    result = await db[mongodb.PHOTOS].insert_one(payload)
    doc = await db[mongodb.PHOTOS].find_one({"_id": result.inserted_id})
    return _serialize(doc)


@router.get("/reviews")
async def list_reviews(
    author_id: Optional[str] = None,
    provider_id: Optional[str] = None,
    limit: int = 100,
):
    db = get_database()
    query: Dict[str, Any] = {}
    if author_id:
        query["author_id"] = author_id
    if provider_id:
        query["provider_id"] = provider_id

    cursor = db[mongodb.REVIEWS].find(query).sort("created_at", -1).limit(limit)
    return [_serialize(doc) async for doc in cursor]


@router.post("/reviews")
async def create_review(payload: Dict[str, Any] = Body(...)):
    db = get_database()
    result = await db[mongodb.REVIEWS].insert_one(payload)
    doc = await db[mongodb.REVIEWS].find_one({"_id": result.inserted_id})
    return _serialize(doc)
