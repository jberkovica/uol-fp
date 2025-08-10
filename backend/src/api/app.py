"""FastAPI application factory."""
import os
from datetime import datetime
from fastapi import FastAPI
from contextlib import asynccontextmanager

from .routes import health, kids, stories, email_review
from .middleware import add_cors_middleware, add_security_middleware, add_exception_handlers
from ..utils.logger import setup_logging, get_logger
from ..utils.config import load_config


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Manage application lifespan."""
    # Startup
    logger = get_logger(__name__)
    logger.info("Mira Storyteller backend starting up...")
    
    yield
    
    # Shutdown
    logger.info("Mira Storyteller backend shutting down...")


def create_app() -> FastAPI:
    """Create and configure FastAPI application."""
    # Load configuration
    config = load_config()
    
    # Setup logging
    logging_config = config.get("logging", {})
    setup_logging(
        level=logging_config.get("level", "INFO"),
        format_type=logging_config.get("format", "json")
    )
    
    # Create FastAPI app
    app_config = config.get("app", {})
    app = FastAPI(
        title=app_config.get("name", "Mira Storyteller API"),
        version=app_config.get("version", "2.0.0"),
        description="AI-powered children's storytelling API",
        lifespan=lifespan
    )
    
    # Add middleware
    from .middleware import logging_middleware
    api_config = config.get("api", {})
    add_cors_middleware(app, api_config.get("cors", {}))
    add_security_middleware(app)
    add_exception_handlers(app)
    app.middleware("http")(logging_middleware)
    
    # Include routers
    app.include_router(health.router)
    app.include_router(kids.router)
    app.include_router(stories.router)
    app.include_router(email_review.router)
    
    # Legacy endpoints removed - Flutter app now uses proper /stories routes
    
    return app