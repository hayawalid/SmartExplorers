from fastapi import APIRouter, Body, Request
from typing import Dict, Any, Optional, List
from bson import ObjectId

from app.mongodb import get_database, mongodb

router = APIRouter(prefix="/api/v1/social", tags=["social"])


def _prefix_static(request: Request, url: str) -> str:
    if url.startswith("/"):
        return str(request.base_url).rstrip("/") + url
    return url


def _serialize(doc: Dict[str, Any]) -> Dict[str, Any]:
    if not doc:
        return doc
    doc["_id"] = str(doc["_id"])
    return doc


@router.get("/posts")
async def list_posts(request: Request, author_id: Optional[str] = None, limit: int = 50):
    db = get_database()
    query: Dict[str, Any] = {}
    if author_id:
        query["author_id"] = author_id

    cursor = db[mongodb.POSTS].find(query).sort("created_at", -1).limit(limit)
    results = []
    async for doc in cursor:
        post = _serialize(doc)
        if not post.get("media_url") and post.get("media_urls"):
            post["media_url"] = post["media_urls"][0]
        if post.get("media_url"):
            post["media_url"] = _prefix_static(request, post["media_url"])
        if post.get("media_urls"):
            post["media_urls"] = [
                _prefix_static(request, url) for url in post["media_urls"]
            ]
        author = None
        if post.get("author_id"):
            author = await db[mongodb.USERS].find_one({"_id": ObjectId(post["author_id"])})
        if author:
            post["author_username"] = author.get("username")
            author_avatar = author.get("avatar_url") or author.get("profile_picture_url")
            if author_avatar:
                post["author_avatar"] = _prefix_static(request, author_avatar)
            else:
                post["author_avatar"] = None
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
async def list_stories(request: Request, user_id: Optional[str] = None, limit: int = 50):
    db = get_database()
    query: Dict[str, Any] = {}
    if user_id:
        query["user_id"] = user_id

    cursor = db[mongodb.STORIES].find(query).sort("created_at", -1).limit(limit)
    results = []
    async for doc in cursor:
        story = _serialize(doc)
        if story.get("media_url"):
            story["media_url"] = _prefix_static(request, story["media_url"])
        results.append(story)
    return results


@router.post("/stories")
async def create_story(payload: Dict[str, Any] = Body(...)):
    db = get_database()
    result = await db[mongodb.STORIES].insert_one(payload)
    doc = await db[mongodb.STORIES].find_one({"_id": result.inserted_id})
    return _serialize(doc)


@router.get("/photos")
async def list_photos(request: Request, user_id: Optional[str] = None, limit: int = 100):
    db = get_database()
    query: Dict[str, Any] = {}
    if user_id:
        query["user_id"] = user_id

    cursor = db[mongodb.PHOTOS].find(query).sort("created_at", -1).limit(limit)
    results = []
    async for doc in cursor:
        photo = _serialize(doc)
        if photo.get("media_url"):
            photo["media_url"] = _prefix_static(request, photo["media_url"])
        results.append(photo)
    return results


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
