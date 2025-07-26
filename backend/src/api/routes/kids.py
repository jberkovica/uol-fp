"""Kid profile management endpoints."""
from fastapi import APIRouter, HTTPException, Depends
from typing import List

from ...types.requests import CreateKidRequest, UpdateKidRequest
from ...types.responses import KidResponse, KidListResponse, StoryResponse
from ...services.supabase import get_supabase_service
from ...core.validators import validate_kid_name, validate_age, validate_uuid
from ...core.exceptions import NotFoundError, ValidationError
from ...utils.logger import get_logger

logger = get_logger(__name__)
router = APIRouter(prefix="/kids", tags=["kids"])


@router.post("/", response_model=KidResponse)
async def create_kid(request: CreateKidRequest) -> KidResponse:
    """Create a new kid profile."""
    try:
        # Validate input
        validate_kid_name(request.name)
        validate_age(request.age)
        validate_uuid(request.user_id, "user_id")
        
        # Create kid profile
        supabase = get_supabase_service()
        kid = await supabase.create_kid(request)
        
        # Get stories count
        stories = await supabase.get_stories_for_kid(kid.id, limit=1)
        
        return KidResponse(
            id=kid.id,
            user_id=kid.user_id,
            name=kid.name,
            age=kid.age,
            avatar_type=kid.avatar_type,
            stories_count=0,
            created_at=kid.created_at
        )
        
    except ValidationError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        logger.error(f"Failed to create kid profile: {e}")
        raise HTTPException(status_code=500, detail="Failed to create kid profile")


@router.get("/{kid_id}", response_model=KidResponse)
async def get_kid(kid_id: str) -> KidResponse:
    """Get a kid profile by ID."""
    try:
        validate_uuid(kid_id, "kid_id")
        
        supabase = get_supabase_service()
        kid = await supabase.get_kid(kid_id)
        
        if not kid:
            raise NotFoundError("Kid profile", kid_id)
            
        # Get stories count
        stories = await supabase.get_stories_for_kid(kid_id)
        
        return KidResponse(
            id=kid.id,
            user_id=kid.user_id,
            name=kid.name,
            age=kid.age,
            avatar_type=kid.avatar_type,
            stories_count=len(stories),
            created_at=kid.created_at
        )
        
    except NotFoundError as e:
        raise HTTPException(status_code=404, detail=str(e))
    except ValidationError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        logger.error(f"Failed to get kid profile: {e}")
        raise HTTPException(status_code=500, detail="Failed to get kid profile")


@router.get("/user/{user_id}", response_model=KidListResponse)
async def get_kids_for_user(user_id: str) -> KidListResponse:
    """Get all kid profiles for a user."""
    try:
        validate_uuid(user_id, "user_id")
        
        supabase = get_supabase_service()
        kids = await supabase.get_kids_for_user(user_id)
        
        # Convert to response format with story counts
        kid_responses = []
        for kid in kids:
            stories = await supabase.get_stories_for_kid(kid.id)
            kid_responses.append(
                KidResponse(
                    id=kid.id,
                    user_id=kid.user_id,
                    name=kid.name,
                    age=kid.age,
                    avatar_type=kid.avatar_type,
                    stories_count=len(stories),
                    created_at=kid.created_at
                )
            )
        
        return KidListResponse(
            kids=kid_responses,
            total=len(kid_responses)
        )
        
    except ValidationError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        logger.error(f"Failed to get kids for user: {e}")
        raise HTTPException(status_code=500, detail="Failed to get kid profiles")


@router.put("/{kid_id}", response_model=KidResponse)
async def update_kid(kid_id: str, request: UpdateKidRequest) -> KidResponse:
    """Update a kid profile."""
    try:
        validate_uuid(kid_id, "kid_id")
        
        # Validate fields if provided
        if request.name is not None:
            validate_kid_name(request.name)
        if request.age is not None:
            validate_age(request.age)
            
        supabase = get_supabase_service()
        kid = await supabase.update_kid(kid_id, request)
        
        if not kid:
            raise NotFoundError("Kid profile", kid_id)
            
        # Get stories count
        stories = await supabase.get_stories_for_kid(kid_id)
        
        return KidResponse(
            id=kid.id,
            user_id=kid.user_id,
            name=kid.name,
            age=kid.age,
            avatar_type=kid.avatar_type,
            stories_count=len(stories),
            created_at=kid.created_at
        )
        
    except NotFoundError as e:
        raise HTTPException(status_code=404, detail=str(e))
    except ValidationError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        logger.error(f"Failed to update kid profile: {e}")
        raise HTTPException(status_code=500, detail="Failed to update kid profile")


@router.delete("/{kid_id}")
async def delete_kid(kid_id: str):
    """Delete a kid profile."""
    try:
        validate_uuid(kid_id, "kid_id")
        
        supabase = get_supabase_service()
        deleted = await supabase.delete_kid(kid_id)
        
        if not deleted:
            raise NotFoundError("Kid profile", kid_id)
            
        return {"message": "Kid profile deleted successfully"}
        
    except NotFoundError as e:
        raise HTTPException(status_code=404, detail=str(e))
    except ValidationError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        logger.error(f"Failed to delete kid profile: {e}")
        raise HTTPException(status_code=500, detail="Failed to delete kid profile")


@router.get("/{kid_id}/stories", response_model=List[dict])
async def get_kid_stories(kid_id: str):
    """Get all stories for a specific kid - matches old backend format."""
    try:
        validate_uuid(kid_id, "kid_id")
        
        supabase = get_supabase_service()
        
        # Verify kid exists first
        kid = await supabase.get_kid(kid_id)
        if not kid:
            raise NotFoundError("Kid", kid_id)
        
        # Get stories for the kid
        stories = await supabase.get_stories_for_kid(kid_id)
        
        # Return in format expected by Flutter app (matching old backend)
        return [
            {
                "story_id": story.id,
                "kid_id": story.kid_id,
                "title": story.title,
                "content": story.content,
                "caption": story.image_description,
                "audio_url": story.audio_filename,  # Database stores as audio_filename
                "status": story.status.value,
                "created_at": story.created_at.isoformat(),
                "child_name": kid.name
            }
            for story in stories
        ]
        
    except NotFoundError as e:
        raise HTTPException(status_code=404, detail=str(e))
    except ValidationError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        logger.error(f"Failed to get stories for kid {kid_id}: {e}")
        raise HTTPException(status_code=500, detail="Failed to get kid stories")