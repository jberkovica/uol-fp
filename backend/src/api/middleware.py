"""FastAPI middleware configuration."""
from fastapi import FastAPI, Request, Response
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.trustedhost import TrustedHostMiddleware
from fastapi.responses import JSONResponse
import time
from typing import Dict, Any

from ..core.exceptions import MiraException, ValidationError, NotFoundError
from ..utils.logger import get_logger

logger = get_logger(__name__)


def add_cors_middleware(app: FastAPI, cors_config: Dict[str, Any]) -> None:
    """Add CORS middleware to the app."""
    app.add_middleware(
        CORSMiddleware,
        allow_origins=cors_config.get("allowed_origins", ["*"]),
        allow_credentials=True,
        allow_methods=cors_config.get("allowed_methods", ["*"]),
        allow_headers=cors_config.get("allowed_headers", ["*"]),
    )


def add_security_middleware(app: FastAPI) -> None:
    """Add security middleware."""
    # Add trusted host middleware for production
    # app.add_middleware(TrustedHostMiddleware, allowed_hosts=["example.com", "*.example.com"])
    pass


async def logging_middleware(request: Request, call_next):
    """Log requests and responses."""
    start_time = time.time()
    
    # Log request
    logger.info(
        "Request started",
        extra={
            "method": request.method,
            "url": str(request.url),
            "client_ip": request.client.host if request.client else None,
            "user_agent": request.headers.get("user-agent")
        }
    )
    
    # Process request
    response = await call_next(request)
    
    # Calculate duration
    duration = time.time() - start_time
    
    # Log response
    logger.info(
        "Request completed",
        extra={
            "method": request.method,
            "url": str(request.url),
            "status_code": response.status_code,
            "duration_ms": round(duration * 1000, 2)
        }
    )
    
    return response


def add_exception_handlers(app: FastAPI) -> None:
    """Add custom exception handlers."""
    
    @app.exception_handler(ValidationError)
    async def validation_error_handler(request: Request, exc: ValidationError):
        """Handle validation errors."""
        return JSONResponse(
            status_code=400,
            content={
                "error": exc.message,
                "code": exc.code,
                "detail": "Input validation failed"
            }
        )
    
    @app.exception_handler(NotFoundError)
    async def not_found_error_handler(request: Request, exc: NotFoundError):
        """Handle not found errors."""
        return JSONResponse(
            status_code=404,
            content={
                "error": exc.message,
                "code": exc.code,
                "detail": "Resource not found"
            }
        )
    
    @app.exception_handler(MiraException)
    async def mira_exception_handler(request: Request, exc: MiraException):
        """Handle custom Mira exceptions."""
        return JSONResponse(
            status_code=500,
            content={
                "error": exc.message,
                "code": exc.code,
                "detail": "An application error occurred"
            }
        )
    
    @app.exception_handler(Exception)
    async def general_exception_handler(request: Request, exc: Exception):
        """Handle unexpected exceptions."""
        logger.error(f"Unhandled exception: {exc}", exc_info=True)
        return JSONResponse(
            status_code=500,
            content={
                "error": "Internal server error",
                "code": "INTERNAL_ERROR",
                "detail": "An unexpected error occurred"
            }
        )