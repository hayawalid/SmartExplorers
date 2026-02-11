"""
UPDATED main.py - WITH SMART MATCHING SYSTEM INTEGRATED

This shows how to integrate the matching system into your existing main.py
Copy the relevant sections to your actual /mnt/project/main.py
"""
from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager

from app.config import settings
from app.mongodb import connect_to_mongo, close_mongo_connection, mongodb
from app.api.chat import router as chat_router
from app.api.users import router as users_router
from app.api.profiles import router as profiles_router
from app.api.social import router as social_router
from app.api.marketplace import router as marketplace_router
from app.api.safety import router as safety_router
from app.api.preferences import router as preferences_router

# ====== NEW: Import matching system ======
from matching_api import router as matching_router, initialize_matching_system
# =========================================
# from app.api.itineraries import router as itinerary_router  # Add when ready
from app.api.verification import router as verification_router

# Add after existing routers


@asynccontextmanager
async def lifespan(app: FastAPI):
    """
    Lifespan context manager for startup/shutdown events
    """
    # Startup
    print(f"Starting {settings.PROJECT_NAME} v{settings.VERSION}")
    await connect_to_mongo()
    
    # ====== NEW: Initialize matching system on startup ======
    try:
        print("Initializing Smart Matching System...")
        db = mongodb.client[mongodb.DATABASE_NAME]
        await initialize_matching_system(db, n_clusters=5)
        print("✅ Smart Matching System initialized")
    except Exception as e:
        print(f"⚠️  Matching system initialization warning: {e}")
        print("   You can manually train the model by calling POST /api/matching/train")
    # ========================================================
    
    print("✅ Application started successfully")
    
    yield
    
    # Shutdown
    await close_mongo_connection()
    print("✅ Application shutdown complete")


# Create FastAPI app
app = FastAPI(
    title=settings.PROJECT_NAME,
    description="AI-Powered Safe Tourism Platform for Egypt with MongoDB + Smart Matching",
    version=settings.VERSION,
    lifespan=lifespan
)

# Static files (avatars, post images)
app.mount("/static", StaticFiles(directory="static"), name="static")

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.allowed_origins_list,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(chat_router)
app.include_router(users_router)
app.include_router(profiles_router)
app.include_router(social_router)
app.include_router(marketplace_router)
app.include_router(safety_router)
app.include_router(preferences_router)

# ====== NEW: Include matching router ======
app.include_router(matching_router)
# ==========================================
app.include_router(verification_router)
# app.include_router(itinerary_router)  # Add when ready


@app.get("/")
async def root():
    """Root endpoint - Health check"""
    return {
        "status": "healthy",
        "service": settings.PROJECT_NAME,
        "version": settings.VERSION,
        "database": "MongoDB",
        "features": ["AI Chat", "Social Feed", "Marketplace", "Safety", "Smart Matching"]  # NEW
    }


@app.get("/health")
async def health_check():
    """Detailed health check"""
    from matching_api import _model_trained  # NEW
    
    # Check MongoDB connection
    db_status = "connected" if mongodb.client else "disconnected"
    
    return {
        "status": "healthy",
        "database": db_status,
        "database_type": "MongoDB",
        "database_name": mongodb.DATABASE_NAME,
        "ai_service": "ready" if settings.GROQ_API_KEY else "not_configured",
        "matching_system": "trained" if _model_trained else "not_trained"  # NEW
    }


if __name__ == "__main__":
    import uvicorn
    uvicorn.run("app.main:app", host="0.0.0.0", port=8000, reload=True)