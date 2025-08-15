"""Kid profile management endpoints."""
from fastapi import APIRouter, HTTPException, Depends
from typing import List

from ...types.requests import CreateKidRequest, UpdateKidRequest, ExtractAppearanceRequest
from ...types.responses import KidResponse, KidListResponse, StoryResponse, ExtractAppearanceResponse
from ...services.supabase import get_supabase_service
from ...core.validators import validate_kid_name, validate_age, validate_uuid
from ...core.exceptions import NotFoundError, ValidationError
from ...utils.logger import get_logger
from ...agents.appearance.agent import create_appearance_agent
from ...utils.config import get_config

logger = get_logger(__name__)
router = APIRouter(prefix="/kids", tags=["kids"])


@router.post("/", response_model=KidResponse)
async def create_kid(request: CreateKidRequest) -> KidResponse:
    """Create a new kid profile."""
    try:
        # Validate input
        validate_kid_name(request.name)
        if request.age is not None:
            validate_age(request.age)
        validate_uuid(request.user_id, "user_id")
        
        # Create kid profile
        supabase = get_supabase_service()
        kid = await supabase.create_kid(request)
        
        # Get all stories count (for parent dashboard)
        stories = await supabase.get_all_stories_for_kid(kid.id, limit=1)
        
        return KidResponse(
            id=kid.id,
            user_id=kid.user_id,
            name=kid.name,
            age=kid.age,
            gender=kid.gender,
            avatar_type=kid.avatar_type,
            appearance_method=kid.appearance_method,
            appearance_description=kid.appearance_description,
            appearance_extracted_at=kid.appearance_extracted_at,
            appearance_metadata=kid.appearance_metadata,
            favorite_genres=kid.favorite_genres,
            parent_notes=kid.parent_notes,
            preferred_language=kid.preferred_language,
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
            
        # Get all stories count (for parent dashboard)
        stories = await supabase.get_all_stories_for_kid(kid_id)
        
        return KidResponse(
            id=kid.id,
            user_id=kid.user_id,
            name=kid.name,
            age=kid.age,
            gender=kid.gender,
            avatar_type=kid.avatar_type,
            appearance_method=kid.appearance_method,
            appearance_description=kid.appearance_description,
            appearance_extracted_at=kid.appearance_extracted_at,
            appearance_metadata=kid.appearance_metadata,
            favorite_genres=kid.favorite_genres,
            parent_notes=kid.parent_notes,
            preferred_language=kid.preferred_language,
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
            stories = await supabase.get_all_stories_for_kid(kid.id)
            kid_responses.append(
                KidResponse(
                    id=kid.id,
                    user_id=kid.user_id,
                    name=kid.name,
                    age=kid.age,
                    gender=kid.gender,
                    avatar_type=kid.avatar_type,
                    appearance_method=kid.appearance_method,
                    appearance_description=kid.appearance_description,
                    appearance_extracted_at=kid.appearance_extracted_at,
                    appearance_metadata=kid.appearance_metadata,
                    favorite_genres=kid.favorite_genres,
                    parent_notes=kid.parent_notes,
                    preferred_language=kid.preferred_language,
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
            
        # Get all stories count (for parent dashboard)
        stories = await supabase.get_all_stories_for_kid(kid_id)
        
        return KidResponse(
            id=kid.id,
            user_id=kid.user_id,
            name=kid.name,
            age=kid.age,
            gender=kid.gender,
            avatar_type=kid.avatar_type,
            appearance_method=kid.appearance_method,
            appearance_description=kid.appearance_description,
            appearance_extracted_at=kid.appearance_extracted_at,
            appearance_metadata=kid.appearance_metadata,
            favorite_genres=kid.favorite_genres,
            parent_notes=kid.parent_notes,
            preferred_language=kid.preferred_language,
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
                "audio_url": supabase.build_audio_url(story.audio_filename) if story.audio_filename else None,
                "background_music_url": story.background_music_url,
                "cover_image_url": story.cover_image_url,
                "cover_image_thumbnail_url": story.cover_image_thumbnail_url,
                "is_favourite": story.is_favourite,
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


@router.post("/extract-appearance", response_model=ExtractAppearanceResponse)
async def extract_appearance_from_photo(request: ExtractAppearanceRequest) -> ExtractAppearanceResponse:
    """Extract appearance description from a child's photo using AI."""
    try:
        # Validate inputs
        validate_kid_name(request.kid_name)
        validate_age(request.age)
        
        # Get appearance agent configuration
        config = get_config()
        agent_config = config["agents"]["appearance"]
        
        # Create appearance extraction agent
        agent = create_appearance_agent(agent_config)
        
        # Extract appearance description
        result = await agent.extract_appearance(
            image_data=request.image_data,
            kid_name=request.kid_name,
            age=request.age
        )
        
        # Return structured response
        return ExtractAppearanceResponse(
            description=result["description"],
            extracted_at=result["extracted_at"],
            model_used=result["model_used"],
            vendor=result["vendor"],
            confidence=result["confidence"],
            word_count=result["word_count"],
            extraction_method=result["extraction_method"]
        )
        
    except ValidationError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        logger.error(f"Failed to extract appearance from photo: {e}")
        raise HTTPException(status_code=500, detail="Failed to extract appearance from photo")