"""
SmartExplorers FastAPI Application with MongoDB
"""
from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager

from app.config import settings
from app.mongodb import connect_to_mongo, close_mongo_connection
from app.api.chat import router as chat_router
from app.api.users import router as users_router
from app.api.profiles import router as profiles_router
from app.api.social import router as social_router
from app.api.marketplace import router as marketplace_router
from app.api.safety import router as safety_router
from app.api.preferences import router as preferences_router
# from app.api.itineraries import router as itinerary_router  # Add when ready


@asynccontextmanager
async def lifespan(app: FastAPI):
    """
    Lifespan context manager for startup/shutdown events
    """
    # Startup
    print(f"Starting {settings.PROJECT_NAME} v{settings.VERSION}")
    await connect_to_mongo()
    print("✓ Application started successfully")
    
    yield
    
    # Shutdown
    await close_mongo_connection()
    print("✓ Application shutdown complete")


# Create FastAPI app
app = FastAPI(
    title=settings.PROJECT_NAME,
    description="AI-Powered Safe Tourism Platform for Egypt with MongoDB",
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
# app.include_router(itinerary_router)  # Add when ready


@app.get("/")
async def root():
    """Root endpoint - Health check"""
    return {
        "status": "healthy",
        "service": settings.PROJECT_NAME,
        "version": settings.VERSION,
        "database": "MongoDB"
    }


@app.get("/health")
async def health_check():
    """Detailed health check"""
    from app.mongodb import mongodb
    
    # Check MongoDB connection
    db_status = "connected" if mongodb.client else "disconnected"
    
    return {
        "status": "healthy",
        "database": db_status,
        "database_type": "MongoDB",
        "database_name": mongodb.DATABASE_NAME,
        "ai_service": "ready" if settings.GROQ_API_KEY else "not_configured"
    }


if __name__ == "__main__":
    import uvicorn
    uvicorn.run("app.main:app", host="0.0.0.0", port=8000, reload=True)