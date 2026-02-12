from pydantic_settings import BaseSettings
from typing import List
import os
from pathlib import Path 

BACKEND_DIR = Path(__file__).resolve().parent.parent
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent
env_file = BASE_DIR / ".env"


class Settings(BaseSettings):
    """Application settings loaded from environment variables"""
    
    # Database
    DATABASE_URL: str = "sqlite:///./smartexplorers.db"
    MONGODB_URI: str = "mongodb://localhost:27017"
    
    # AI Services
    OPENAI_API_KEY: str = ""
    OPENAI_MODEL: str = "gpt-4o-mini"
    GROQ_MODEL: str = "llama-3.3-70b-versatile"
    GROQ_API_KEY: str = ""
    
    # Map verification uses FREE APIs (Nominatim + Overpass) - no key needed
    
    # Social Media Verification (optional)
    FACEBOOK_ACCESS_TOKEN: str = ""
    
    # AI Assistant settings
    AI_TEMPERATURE: float = 0.7
    AI_MAX_TOKENS: int = 1000
    
    # Encryption (for identity verification)
    # Generate with: python -c 'from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())'
    ENCRYPTION_MASTER_KEY: str = ""
    
    
    
    # ⬇️ ADD THESE NEW SETTINGS ⬇️
    # AI Assistant Settings
    AI_MODEL: str = "gpt-4"          # NEW
    AI_TEMPERATURE: float = 0.7      # NEW
    AI_MAX_TOKENS: int = 1000        # NEW

    # Security
    SECRET_KEY: str = ""
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    
    # Application
    DEBUG: bool = True
    API_V1_PREFIX: str = "/api"
    PROJECT_NAME: str = "SmartExplorers API"
    VERSION: str = "1.0.0"
    
    # CORS
    ALLOWED_ORIGINS: str = "*"
    
    @property
    def allowed_origins_list(self) -> List[str]:
        """Convert comma-separated origins to list"""
        if self.ALLOWED_ORIGINS == "*":
            return ["*"]
        return [origin.strip() for origin in self.ALLOWED_ORIGINS.split(",")]
    
    class Config:
        # env_file = ".env"
        env_file = str(env_file)
        extra = "ignore"
        case_sensitive = True


# Global settings instance
settings = Settings()