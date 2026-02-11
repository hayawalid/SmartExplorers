#!/usr/bin/env python3
"""
Simple server script to run the FastAPI backend
Usage: python3 server.py
"""
import uvicorn
from app.config import settings
from app.mongodb import get_sync_client


def _safe_uri(uri: str) -> str:
    if "@" in uri and ":" in uri:
        return uri.split("//")[0] + "//***:***@" + uri.split("@")[-1]
    return uri


def _mongo_preflight() -> None:
    """Validate MongoDB connection and log counts for sanity checks."""
    try:
        db = get_sync_client()
        users_count = db.users.count_documents({})
        posts_count = db.posts.count_documents({})
        conversations_count = db.conversations.count_documents({})

        print("\n=== MongoDB Preflight ===")
        print(f"URI: {_safe_uri(settings.MONGODB_URI)}")
        print(f"Database: {db.name}")
        print(f"Users: {users_count}")
        print(f"Posts: {posts_count}")
        print(f"Conversations: {conversations_count}")
        print("=========================\n")
    except Exception as exc:
        print("\n=== MongoDB Preflight Failed ===")
        print(f"URI: {_safe_uri(settings.MONGODB_URI)}")
        print(f"Error: {exc}")
        print("================================\n")

if __name__ == "__main__":
    print("=" * 60)
    print("  SmartExplorers Backend Server")
    print("=" * 60)
    print("\n🚀 Starting server on http://0.0.0.0:8000")
    print("📚 API docs available at http://localhost:8000/docs")
    print("💬 Chat endpoint: http://localhost:8000/api/v1/chat/")
    print("\nPress CTRL+C to stop the server\n")

    _mongo_preflight()
    
    uvicorn.run(
        "app.main:app",
        host="0.0.0.0",
        port=8000,
        reload=True,
        log_level="info",
        access_log=True,
    )
