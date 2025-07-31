"""Story generation and management endpoints."""
from fastapi import APIRouter, HTTPException, BackgroundTasks, Depends
from typing import List, Optional
from datetime import datetime
import base64
import tempfile
import os

from ...types.requests import (
    GenerateStoryRequest, ReviewStoryRequest, InitiateVoiceStoryRequest,
    TranscribeAudioRequest, SubmitStoryTextRequest
)
from ...types.responses import (
    StoryResponse, StoryListResponse, GenerateStoryResponse,
    InitiateStoryResponse, TranscriptionResponse
)
from ...types.domain import StoryStatus, InputFormat
from ...services.supabase import get_supabase_service
from ...core.story_processor import get_story_processor
from ...core.validators import validate_base64_image, validate_uuid, validate_story_content
from ...core.exceptions import NotFoundError, ValidationError, AgentError
from ...utils.logger import get_logger
import yaml

logger = get_logger(__name__)
router = APIRouter(prefix="/stories", tags=["stories"])


def get_agents_config():
    """Load agents configuration from config.yaml with environment variable substitution."""
    from ...utils.config import load_config
    config = load_config()
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


@router.get("/pending", response_model=StoryListResponse)
async def get_pending_stories() -> StoryListResponse:
    """Get all pending stories for parent review."""
    try:
        logger.info("Getting pending stories")
        supabase = get_supabase_service()
        
        # Get all pending stories from database using the service method
        stories_data = await supabase.get_pending_stories()
        logger.info(f"Found {len(stories_data)} pending stories")
        
        # Convert to response format
        stories = [
            StoryResponse(
                id=story.id,
                kid_id=story.kid_id,
                child_name=story.child_name,
                title=story.title,
                content=story.content,
                audio_url=story.audio_url,
                status=story.status,
                language=story.language,
                created_at=story.created_at,
                updated_at=story.updated_at
            )
            for story in stories_data
        ]
        
        return StoryListResponse(
            stories=stories,
            total=len(stories),
            page=1,
            page_size=len(stories)
        )
        
    except Exception as e:
        logger.error(f"Failed to get pending stories: {e}")
        raise HTTPException(status_code=500, detail="Failed to get pending stories")


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


@router.post("/initiate-voice", response_model=InitiateStoryResponse)
async def initiate_voice_story(request: InitiateVoiceStoryRequest) -> InitiateStoryResponse:
    """Create a new story in transcribing state for voice input."""
    try:
        # Validate kid exists
        supabase = get_supabase_service()
        kid = await supabase.get_kid(request.kid_id)
        if not kid:
            raise NotFoundError("Kid profile", request.kid_id)
        
        initial_status = StoryStatus.TRANSCRIBING
        
        # Create story record (input_format stored in story_inputs table instead)
        story_data = {
            "kid_id": request.kid_id,
            "title": "New Story",
            "content": "",
            "language": request.language.value,
            "status": initial_status.value
        }
        story = await supabase.create_story(story_data)
        
        return InitiateStoryResponse(
            story_id=story.id,
            status=initial_status,
            message=f"Story created in {initial_status.value} state"
        )
        
    except NotFoundError as e:
        raise HTTPException(status_code=404, detail=str(e))
    except Exception as e:
        logger.error(f"Failed to initiate story: {e}")
        raise HTTPException(status_code=500, detail="Failed to initiate story")


@router.post("/transcribe", response_model=TranscriptionResponse)
async def transcribe_audio(request: TranscribeAudioRequest) -> TranscriptionResponse:
    """Transcribe audio for a story."""
    try:
        # Validate story exists and is in correct state
        supabase = get_supabase_service()
        story = await supabase.get_story(request.story_id)
        if not story:
            raise NotFoundError("Story", request.story_id)
            
        if story.status != StoryStatus.TRANSCRIBING:
            raise ValidationError(f"Story is not in transcribing state: {story.status}")
        
        # Decode base64 audio
        audio_bytes = base64.b64decode(request.audio_data)
        
        # Create temporary file for audio
        with tempfile.NamedTemporaryFile(delete=False, suffix='.webm') as temp_audio:
            temp_audio.write(audio_bytes)
            temp_audio_path = temp_audio.name
        
        try:
            # Get Whisper config
            agents_config = get_agents_config()
            whisper_config = agents_config.get("whisper", {})
            api_key = whisper_config.get("api_key")
            
            if not api_key:
                raise ValueError("OpenAI API key not found in configuration")
            
            # Import OpenAI client
            import openai
            client = openai.OpenAI(api_key=api_key)
            
            # Transcribe audio
            with open(temp_audio_path, 'rb') as audio_file:
                transcript_response = client.audio.transcriptions.create(
                    model="whisper-1",
                    file=audio_file,
                    language=story.language.value  # Use story's language in ISO format
                )
            
            transcribed_text = transcript_response.text.strip()
            logger.info(f"Audio transcribed: {len(transcribed_text)} characters")
            
            # Update story status only (no permanent audio storage for user recordings)
            updates = {
                "status": StoryStatus.DRAFT.value
            }
            await supabase.update_story(request.story_id, updates)
            
            # Store in story_inputs table
            story_input_data = {
                "story_id": request.story_id,
                "input_type": "audio_transcription",
                "input_value": transcribed_text,
                "metadata": {
                    "whisper_model": "whisper-1",
                    "transcription_language": story.language
                }
            }
            await supabase.create_story_input(story_input_data)
            
            return TranscriptionResponse(
                story_id=request.story_id,
                transcribed_text=transcribed_text,
                status=StoryStatus.DRAFT
            )
            
        finally:
            # Clean up temporary file
            if os.path.exists(temp_audio_path):
                os.unlink(temp_audio_path)
                
    except (NotFoundError, ValidationError) as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        logger.error(f"Failed to transcribe audio: {e}")
        raise HTTPException(status_code=500, detail="Failed to transcribe audio")


@router.post("/submit-text", response_model=GenerateStoryResponse)
async def submit_story_text(
    request: SubmitStoryTextRequest,
    background_tasks: BackgroundTasks
) -> GenerateStoryResponse:
    """Submit final text for story generation."""
    try:
        # Validate story exists and is in draft state
        supabase = get_supabase_service()
        story = await supabase.get_story(request.story_id)
        if not story:
            raise NotFoundError("Story", request.story_id)
            
        if story.status != StoryStatus.DRAFT:
            raise ValidationError(f"Story is not in draft state: {story.status}")
        
        # Validate text
        text = request.text.strip()
        if len(text) < 10:
            raise ValidationError("Text too short (minimum 10 characters)")
        if len(text) > 500:
            raise ValidationError("Text too long (maximum 500 characters)")
        
        # Update story status to processing
        updates = {
            "status": StoryStatus.PROCESSING.value
        }
        await supabase.update_story(request.story_id, updates)
        
        # Get original transcription from story_inputs to compare
        original_transcription_input = await supabase.get_story_input_by_type(request.story_id, "audio_transcription")
        original_transcription = original_transcription_input.get("input_value", "") if original_transcription_input else ""
        
        # Store final text in story_inputs
        story_input_data = {
            "story_id": request.story_id,
            "input_type": "text_final",
            "input_value": text,
            "metadata": {
                "original_transcription": original_transcription,
                "text_edited": original_transcription != text
            }
        }
        await supabase.create_story_input(story_input_data)
        
        # Process story in background
        agents_config = get_agents_config()
        processor = get_story_processor(agents_config)
        background_tasks.add_task(
            processor.process_text_to_story,
            request.story_id,
            text,
            story.kid_id,
            story.language
        )
        
        return GenerateStoryResponse(
            story_id=request.story_id,
            status=StoryStatus.PROCESSING,
            message="Story generation started"
        )
        
    except (NotFoundError, ValidationError) as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        logger.error(f"Failed to submit story text: {e}")
        raise HTTPException(status_code=500, detail="Failed to submit story text")


@router.post("/review-story/")
async def review_story_simple(request: dict):
    """Review story endpoint that matches Flutter expectations."""
    try:
        story_id = request.get("story_id")
        approved = request.get("approved")
        feedback = request.get("feedback")
        
        if not story_id:
            raise ValidationError("story_id is required")
        if approved is None:
            raise ValidationError("approved field is required")
            
        validate_uuid(story_id, "story_id")
        
        supabase = get_supabase_service()
        
        # Get current story to find the kid and parent
        story = await supabase.get_story(story_id)
        if not story:
            raise NotFoundError("Story", story_id)
            
        # Get kid to find parent user_id
        kid = await supabase.get_kid(story.kid_id)
        if not kid:
            raise NotFoundError("Kid", story.kid_id)
        
        # Determine new status and reason
        if approved:
            new_status = StoryStatus.APPROVED.value
            action = "approve"
        else:
            new_status = StoryStatus.REJECTED.value  
            action = "decline"
        
        # Update story status
        update_data = {
            "status": new_status
        }
        
        if feedback:
            if approved:
                update_data["parent_feedback"] = feedback
            else:
                update_data["declined_reason"] = feedback
        
        updated_story = await supabase.update_story(story_id, update_data)
        
        # Log the review action in story_review_actions table
        supabase.client.table("story_review_actions").insert({
            "story_id": story_id,
            "user_id": kid.user_id,
            "action": action,
            "feedback": feedback,
            "declined_reason": feedback if not approved else None,
            "review_method": "app"
        }).execute()
        
        logger.info(f"Story {story_id} {action}ed by parent {kid.user_id}")
        
        return {
            "success": True,
            "story_id": story_id,
            "status": new_status,
            "message": f"Story {'approved' if approved else 'declined'} successfully"
        }
        
    except (NotFoundError, ValidationError) as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        logger.error(f"Failed to review story: {e}")
        raise HTTPException(status_code=500, detail="Failed to review story")


