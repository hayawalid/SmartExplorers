#!/usr/bin/env python3
"""
Simple server script to run the FastAPI backend
Usage: python3 server.py
"""
import uvicorn

if __name__ == "__main__":
    print("=" * 60)
    print("  SmartExplorers Backend Server")
    print("=" * 60)
    print("\n🚀 Starting server on http://0.0.0.0:8000")
    print("📚 API docs available at http://localhost:8000/docs")
    print("💬 Chat endpoint: http://localhost:8000/api/v1/chat/")
    print("\nPress CTRL+C to stop the server\n")
    
    uvicorn.run(
        "app.main:app",
        host="0.0.0.0",
        port=8000,
        reload=True,
        log_level="info"
    )
