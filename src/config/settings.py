"""Configuration management using pydantic-settings"""

from pydantic_settings import BaseSettings, SettingsConfigDict
from typing import Literal


class Settings(BaseSettings):
    """Application settings"""
    
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False
    )
    
    # Environment
    environment: Literal["development", "staging", "production"] = "development"
    
    # API Configuration
    api_host: str = "0.0.0.0"
    api_port: int = 8000
    api_reload: bool = True
    
    # LLM Configuration
    openai_api_key: str = ""
    anthropic_api_key: str = ""
    default_llm_provider: Literal["openai", "anthropic"] = "openai"
    default_model: str = "gpt-4o"
    
    # LangSmith
    langchain_tracing_v2: bool = False
    langchain_project: str = "marketing-agent-dev"
    langchain_api_key: str = ""
    
    # Database
    database_url: str = "postgresql+asyncpg://postgres:postgres@localhost:5432/marketing_agent"
    database_url_sync: str = "postgresql://postgres:postgres@localhost:5432/marketing_agent"
    
    # Redis
    redis_url: str = "redis://localhost:6379/0"
    
    # Monitoring
    sentry_dsn: str = ""
    
    # Agent Configuration
    max_iterations: int = 3
    confidence_threshold: float = 0.6
    recommendation_timeout: int = 60  # seconds
    
    # Cost limits
    max_tokens_per_request: int = 8000
    max_cost_per_recommendation: float = 0.50  # USD


# Global settings instance
settings = Settings()
