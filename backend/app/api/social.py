from fastapi import APIRouter, Body, Request, UploadFile, File, HTTPException
import os
import uuid
from typing import Dict, Any, Optional, List
from bson import ObjectId
from datetime import datetime

from app.mongodb import get_database, mongodb

router = APIRouter(prefix="/api/v1/social", tags=["social"])


def _prefix_static(request: Request, url: str) -> str:
    if url.startswith("/"):
        return str(request.base_url).rstrip("/") + url
    return url


def _serialize(doc: Dict[str, Any]) -> Dict[str, Any]:
    if not doc:
        return doc
    return _json_safe(doc)


def _json_safe(value: Any) -> Any:
    if isinstance(value, ObjectId):
        return str(value)
    if isinstance(value, dict):
        return {key: _json_safe(item) for key, item in value.items()}
    if isinstance(value, list):
        return [_json_safe(item) for item in value]
    if isinstance(value, tuple):
        return [_json_safe(item) for item in value]
    return value


def _to_post_snapshot(payload: Dict[str, Any]) -> Dict[str, Any]:
    return {
        "post_id": payload.get("post_id"),
        "user_id": payload.get("user_id"),
        "author_id": payload.get("author_id"),
        "author_name": payload.get("author_name"),
        "author_username": payload.get("author_username"),
        "author_avatar": payload.get("author_avatar"),
        "text": payload.get("text"),
        "media_url": payload.get("media_url"),
        "created_at": payload.get("created_at"),
        "saved_at": payload.get("saved_at"),
    }


@router.get("/posts")
async def list_posts(
    request: Request,
    author_id: Optional[str] = None,
    user_id: Optional[str] = None,
    limit: int = 50,
):
    db = get_database()
    query: Dict[str, Any] = {}
    if author_id:
        query["author_id"] = author_id

    saved_post_ids = set()
    if user_id:
        cursor = db[mongodb.SAVED_POSTS].find({"user_id": user_id}, {"post_id": 1})
        async for doc in cursor:
            post_id = doc.get("post_id")
            if post_id:
                saved_post_ids.add(str(post_id))

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
        post_id = str(post.get("_id", ""))
        if post_id:
            post["bookmarked"] = post_id in saved_post_ids
        results.append(post)
    return results


@router.post("/posts")
async def create_post(payload: Dict[str, Any] = Body(...)):
    db = get_database()
    result = await db[mongodb.POSTS].insert_one(payload)
    doc = await db[mongodb.POSTS].find_one({"_id": result.inserted_id})
    return _serialize(doc)


@router.post("/upload")
async def upload_media(file: UploadFile = File(...)):
    try:
        ext = os.path.splitext(file.filename)[1] if file.filename else ""
        filename = f"{uuid.uuid4().hex}{ext}"
        save_dir = os.path.normpath(os.path.join(os.path.dirname(__file__), "..", "..", "static", "posts"))
        os.makedirs(save_dir, exist_ok=True)
        dest_path = os.path.join(save_dir, filename)
        content = await file.read()
        with open(dest_path, "wb") as f:
            f.write(content)
        return {"path": f"/static/posts/{filename}"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.delete("/posts/{post_id}")
async def delete_post(post_id: str, author_id: str):
    db = get_database()
    result = await db[mongodb.POSTS].delete_one(
        {"_id": ObjectId(post_id), "author_id": author_id}
    )
    if result.deleted_count == 0:
        return {"deleted": False, "detail": "Post not found"}

    await db[mongodb.SAVED_POSTS].delete_many({"post_id": post_id})
    return {"deleted": True, "post_id": post_id}


@router.post("/posts/{post_id}/comments")
async def add_comment(post_id: str, payload: Dict[str, Any] = Body(...)):
    db = get_database()
    comment = {
        "_id": ObjectId(),
        "author_id": payload.get("author_id"),
        "text": payload.get("text"),
        "created_at": datetime.utcnow(),
    }
    await db[mongodb.POSTS].update_one({"_id": ObjectId(post_id)}, {"$push": {"comments": comment}})
    doc = await db[mongodb.POSTS].find_one({"_id": ObjectId(post_id)})
    return _serialize(doc)


@router.post("/posts/{post_id}/likes")
async def add_like(post_id: str, payload: Dict[str, Any] = Body(...)):
    db = get_database()
    user_id = payload.get("user_id")
    if not user_id:
        return {"error": "user_id is required"}
    # Use addToSet to avoid duplicate likes
    await db[mongodb.POSTS].update_one({"_id": ObjectId(post_id)}, {"$addToSet": {"likes": user_id}})
    doc = await db[mongodb.POSTS].find_one({"_id": ObjectId(post_id)})
    post = _serialize(doc)
    post["likes_count"] = len(post.get("likes", []))
    return post


@router.get("/favorites")
async def list_favorites(user_id: str):
    db = get_database()
    cursor = db[mongodb.SAVED_POSTS].find({"user_id": user_id}).sort("saved_at", -1)
    return [_serialize(doc) async for doc in cursor]


@router.post("/favorites")
async def save_favorite(payload: Dict[str, Any] = Body(...)):
    db = get_database()
    user_id = payload.get("user_id")
    post_id = payload.get("post_id")
    if not user_id or not post_id:
        return {"detail": "user_id and post_id are required"}

    favorite = _to_post_snapshot(payload)
    favorite["saved_at"] = favorite.get("saved_at") or datetime.utcnow()
    await db[mongodb.SAVED_POSTS].update_one(
        {"user_id": user_id, "post_id": post_id},
        {"$set": favorite},
        upsert=True,
    )
    doc = await db[mongodb.SAVED_POSTS].find_one({"user_id": user_id, "post_id": post_id})
    return _serialize(doc)


@router.delete("/favorites")
async def remove_favorite(user_id: str, post_id: str):
    db = get_database()
    result = await db[mongodb.SAVED_POSTS].delete_one({"user_id": user_id, "post_id": post_id})
    return {"deleted": result.deleted_count == 1}


@router.delete("/posts/{post_id}/likes")
async def remove_like(post_id: str, user_id: str):
    db = get_database()
    await db[mongodb.POSTS].update_one({"_id": ObjectId(post_id)}, {"$pull": {"likes": user_id}})
    doc = await db[mongodb.POSTS].find_one({"_id": ObjectId(post_id)})
    post = _serialize(doc)
    post["likes_count"] = len(post.get("likes", []))
    return post


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
    # After review creation
    from app.api.notifications import create_notification
    from app.schemas.notification import NotificationCreate, NotificationType

    provider_id = payload.get("provider_id")
    if provider_id:
        await create_notification(
            NotificationCreate(
                user_id=provider_id,
                type=NotificationType.REVIEW_RECEIVED,
                title="New review",
                body=f"Someone left a {payload.get('rating')}-star review for you.",
                data={"review_id": str(result.inserted_id)}
            ),
            db
        )
    doc = await db[mongodb.REVIEWS].find_one({"_id": result.inserted_id})

    # Re-run verification for the provider so score reflects new review
    review_provider_id = payload.get("provider_id")
    if review_provider_id and str(review_provider_id).strip():
        try:
            from app.services.provider_verification_service import provider_verification_service
            import asyncio
            print(f"  [INFO] Triggering re-verification for provider: {review_provider_id}")
            asyncio.create_task(provider_verification_service.verify_provider_complete(str(review_provider_id)))
        except Exception as e:
            print(f"  [WARN] Re-verification task failed to schedule: {e}")
            pass  # Non-blocking

    return _serialize(doc)
