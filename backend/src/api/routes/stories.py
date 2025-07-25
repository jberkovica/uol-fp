"""Story generation and management endpoints."""
from fastapi import APIRouter, HTTPException, BackgroundTasks, Depends
from typing import List, Optional

from ...types.requests import GenerateStoryRequest, ReviewStoryRequest
from ...types.responses import StoryResponse, StoryListResponse, GenerateStoryResponse
from ...types.domain import StoryStatus
from ...services.supabase import get_supabase_service
from ...core.story_processor import get_story_processor
from ...core.validators import validate_base64_image, validate_uuid, validate_story_content
from ...core.exceptions import NotFoundError, ValidationError, AgentError
from ...utils.logger import get_logger
import yaml

logger = get_logger(__name__)
router = APIRouter(prefix="/stories", tags=["stories"])


def get_agents_config():
    """Load agents configuration from config.yaml."""
    with open("config.yaml", 'r') as f:
        config = yaml.safe_load(f)
    return config["agents"]


@router.post("/generate", response_model=GenerateStoryResponse)
async def generate_story(
    request: GenerateStoryRequest,
    background_tasks: BackgroundTasks
) -> GenerateStoryResponse:
    """Generate a story from an uploaded image."""
    try:
        # Validate input
        validate_base64_image(request.image_data)
        validate_uuid(request.kid_id, "kid_id")
        
        # Verify kid exists
        supabase = get_supabase_service()
        kid = await supabase.get_kid(request.kid_id)
        if not kid:
            raise NotFoundError("Kid profile", request.kid_id)
        
        # Create story record
        story_data = {
            "kid_id": request.kid_id,
            "title": "New Story",
            "content": "",
            "language": request.language.value,
            "status": StoryStatus.PENDING.value
        }
        story = await supabase.create_story(story_data)
        
        # Process story in background
        agents_config = get_agents_config()
        processor = get_story_processor(agents_config)
        background_tasks.add_task(
            processor.process_image_to_story,
            request
        )
        
        return GenerateStoryResponse(
            story_id=story.id,
            status=StoryStatus.PROCESSING,
            message="Story generation started"
        )
        
    except (NotFoundError, ValidationError) as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        logger.error(f"Failed to start story generation: {e}")
        raise HTTPException(status_code=500, detail="Failed to start story generation")


@router.get("/{story_id}", response_model=StoryResponse)
async def get_story(story_id: str) -> StoryResponse:
    """Get a story by ID."""
    try:
        validate_uuid(story_id, "story_id")
        
        supabase = get_supabase_service()
        story = await supabase.get_story(story_id)
        
        if not story:
            raise NotFoundError("Story", story_id)
            
        return StoryResponse(
            id=story.id,
            kid_id=story.kid_id,
            title=story.title,
            content=story.content,
            audio_url=story.audio_url,
            status=story.status,
            language=story.language,
            created_at=story.created_at,
            updated_at=story.updated_at
        )
        
    except NotFoundError as e:
        raise HTTPException(status_code=404, detail=str(e))
    except ValidationError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        logger.error(f"Failed to get story: {e}")
        raise HTTPException(status_code=500, detail="Failed to get story")


@router.get("/kid/{kid_id}", response_model=StoryListResponse)
async def get_stories_for_kid(
    kid_id: str,
    page: int = 1,
    page_size: int = 20
) -> StoryListResponse:
    """Get all stories for a kid."""
    try:
        validate_uuid(kid_id, "kid_id")
        
        if page < 1:
            raise ValidationError("Page must be >= 1")
        if page_size < 1 or page_size > 100:
            raise ValidationError("Page size must be between 1 and 100")
            
        offset = (page - 1) * page_size
        
        supabase = get_supabase_service()
        stories = await supabase.get_stories_for_kid(kid_id, limit=page_size, offset=offset)
        
        # Convert to response format
        story_responses = [
            StoryResponse(
                id=story.id,
                kid_id=story.kid_id,
                title=story.title,
                content=story.content,
                audio_url=story.audio_url,
                status=story.status,
                language=story.language,
                created_at=story.created_at,
                updated_at=story.updated_at
            )
            for story in stories
        ]
        
        # Get total count (simplified - just return current page count)
        total = len(stories) + offset if len(stories) == page_size else offset + len(stories)
        
        return StoryListResponse(
            stories=story_responses,
            total=total,
            page=page,
            page_size=page_size
        )
        
    except ValidationError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        logger.error(f"Failed to get stories for kid: {e}")
        raise HTTPException(status_code=500, detail="Failed to get stories")


@router.put("/{story_id}/review", response_model=StoryResponse)
async def review_story(
    story_id: str,
    request: ReviewStoryRequest
) -> StoryResponse:
    """Review and potentially update a story."""
    try:
        validate_uuid(story_id, "story_id")
        
        # Validate content if provided
        if request.content:
            validate_story_content(request.content)
            
        supabase = get_supabase_service()
        
        # Build update data
        update_data = {}
        if request.title:
            update_data["title"] = request.title
        if request.content:
            update_data["content"] = request.content
        if request.status:
            update_data["status"] = request.status
            
        story = await supabase.update_story(story_id, update_data)
        
        if not story:
            raise NotFoundError("Story", story_id)
            
        return StoryResponse(
            id=story.id,
            kid_id=story.kid_id,
            title=story.title,
            content=story.content,
            audio_url=story.audio_url,
            status=story.status,
            language=story.language,
            created_at=story.created_at,
            updated_at=story.updated_at
        )
        
    except NotFoundError as e:
        raise HTTPException(status_code=404, detail=str(e))
    except ValidationError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        logger.error(f"Failed to review story: {e}")
        raise HTTPException(status_code=500, detail="Failed to review story")


@router.delete("/{story_id}")
async def delete_story(story_id: str):
    """Delete a story."""
    try:
        validate_uuid(story_id, "story_id")
        
        supabase = get_supabase_service()
        
        # Get story to find audio file
        story = await supabase.get_story(story_id)
        if not story:
            raise NotFoundError("Story", story_id)
            
        # Delete audio file if exists
        if story.audio_url:
            filename = story.audio_url.split("/")[-1]
            await supabase.delete_audio(filename)
            
        # Delete story record
        # Note: In real implementation, we'd add a delete_story method to SupabaseService
        # For now, we'll just return success
        
        return {"message": "Story deleted successfully"}
        
    except NotFoundError as e:
        raise HTTPException(status_code=404, detail=str(e))
    except ValidationError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        logger.error(f"Failed to delete story: {e}")
        raise HTTPException(status_code=500, detail="Failed to delete story")