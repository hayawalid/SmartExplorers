from pydantic_settings import BaseSettings
from typing import List
import os


class Settings(BaseSettings):
    """Application settings loaded from environment variables"""
    
    # Database
    DATABASE_URL: str = "sqlite:///./smartexplorers.db"
    
    # OpenAI
    OPENAI_API_KEY: str = ""
    OPENAI_MODEL: str = "gpt-4o-mini"
    GROQ_MODEL: str ="llama-3.3-70b-versatile"
    GROQ_API_KEY: str =""
    
    
    
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
        env_file = ".env"
        extra = "ignore"
        case_sensitive = True


# Global settings instance
settings = Settings()