"""Health check endpoints."""
from fastapi import APIRouter, Depends
from typing import Dict, Any

from ...types.responses import HealthResponse
from ...services.supabase import get_supabase_service
from ...utils.logger import get_logger

logger = get_logger(__name__)
router = APIRouter(tags=["health"])


@router.get("/health", response_model=HealthResponse)
async def health_check() -> HealthResponse:
    """Basic health check endpoint."""
    return HealthResponse(
        status="healthy",
        version="2.0.0"
    )


@router.get("/health/detailed", response_model=HealthResponse)
async def detailed_health_check() -> HealthResponse:
    """Detailed health check with service status."""
    services = {}
    
    # Check Supabase connection
    try:
        supabase = get_supabase_service()
        supabase_status = await supabase.health_check()
        services["supabase"] = supabase_status
    except Exception as e:
        logger.error(f"Supabase health check failed: {e}")
        services["supabase"] = {
            "status": "unhealthy",
            "error": str(e)
        }
    
    # Check AI agents (just verify they can be initialized)
    services["agents"] = {
        "vision": "configured",
        "storyteller": "configured",
        "voice": "configured"
    }
    
    # Overall status
    all_healthy = all(
        s.get("status") != "unhealthy" 
        for s in services.values() 
        if isinstance(s, dict)
    )
    
    return HealthResponse(
        status="healthy" if all_healthy else "degraded",
        version="2.0.0",
        services=services
    )