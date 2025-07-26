"""FastAPI application factory."""
import os
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
    
    # Add main API endpoints for Flutter app compatibility
    add_main_endpoints(app)
    
    return app


def add_main_endpoints(app: FastAPI):
    """Add main API endpoints that the Flutter app uses."""
    from fastapi import HTTPException, BackgroundTasks
    from ..types.requests import GenerateStoryRequest
    from ..types.responses import GenerateStoryResponse
    from ..types.domain import StoryStatus, Language
    from ..services.supabase import get_supabase_service
    from ..core.story_processor import get_story_processor
    from ..core.validators import validate_base64_image, validate_uuid
    from ..core.exceptions import NotFoundError, ValidationError
    from ..utils.logger import get_logger
    
    logger = get_logger(__name__)
    
    @app.post("/generate-story-from-image/")
    async def generate_story_from_image(
        request: GenerateStoryRequest,
        background_tasks: BackgroundTasks
    ):
        """Main endpoint for story generation from image."""
        try:
            # Validate input
            validate_base64_image(request.image_data)
            validate_uuid(request.kid_id, "kid_id")
            
            # Verify kid exists
            supabase = get_supabase_service()
            kid = await supabase.get_kid(request.kid_id)
            if not kid:
                raise NotFoundError("Kid profile", request.kid_id)
            
            # Create story record (matching old backend format)
            story_data = {
                "kid_id": request.kid_id,
                "child_name": kid.name,  # Required field - kid's name
                "title": "New Story",
                "content": "",
                "language": request.language.value,
                "status": StoryStatus.PENDING.value
            }
            story = await supabase.create_story(story_data)
            
            # Process story in background (matching old backend pattern)
            background_tasks.add_task(
                process_story_generation_background,
                story.id,
                request.image_data,
                request.kid_id,
                request.language
            )
            
            return {
                "story_id": story.id,
                "status": "processing",
                "message": "Story generation started"
            }
            
        except (NotFoundError, ValidationError) as e:
            raise HTTPException(status_code=400, detail=str(e))
        except Exception as e:
            import traceback
            logger.error(f"Story generation failed: {e}")
            logger.error(f"Traceback: {traceback.format_exc()}")
            raise HTTPException(status_code=500, detail=f"Failed to start story generation: {str(e)}")
    
    @app.get("/story/{story_id}")
    async def get_story(story_id: str):
        """Main endpoint for getting a story."""
        try:
            validate_uuid(story_id, "story_id")
            
            supabase = get_supabase_service()
            story = await supabase.get_story(story_id)
            
            if not story:
                raise NotFoundError("Story", story_id)
                
            return {
                "story_id": story.id,  # Flutter expects 'story_id', not 'id'
                "kid_id": story.kid_id,
                "title": story.title,
                "content": story.content,
                "audio_url": story.audio_filename,  # Database stores as audio_filename
                "status": story.status.value,
                "language": story.language.value,
                "created_at": story.created_at.isoformat(),
                "updated_at": story.updated_at.isoformat() if story.updated_at else None
            }
            
        except NotFoundError as e:
            raise HTTPException(status_code=404, detail=str(e))
        except ValidationError as e:
            raise HTTPException(status_code=400, detail=str(e))
        except Exception as e:
            raise HTTPException(status_code=500, detail="Failed to get story")
    
    @app.get("/kids/")
    async def get_kids():
        """Main endpoint for getting all kids."""
        try:
            # For now, return empty list - in real implementation would need user_id
            return {"kids": [], "total": 0}
        except Exception as e:
            raise HTTPException(status_code=500, detail="Failed to get kids")
    
    @app.get("/users/{user_id}/kids")
    async def get_user_kids(user_id: str):
        """Main endpoint for getting user's kids."""
        try:
            validate_uuid(user_id, "user_id")
            
            supabase = get_supabase_service()
            kids = await supabase.get_kids_for_user(user_id)
            
            # Return just the array of kids, not wrapped in an object
            return [
                {
                    "kid_id": kid.id,  # Flutter expects 'kid_id', not 'id'
                    "name": kid.name,
                    "age": kid.age,  # Uses the @property method
                    "avatar_type": kid.avatar_type,
                    "created_at": kid.created_at.isoformat()
                }
                for kid in kids
            ]
            
        except ValidationError as e:
            raise HTTPException(status_code=400, detail=str(e))
        except Exception as e:
            # Add logging to see what's actually failing
            import traceback
            print(f"Error in get_user_kids: {e}")
            print(f"Traceback: {traceback.format_exc()}")
            raise HTTPException(status_code=500, detail=f"Failed to get user kids: {str(e)}")


async def process_story_generation_background(
    story_id: str,
    image_data: str,
    kid_id: str,
    language
):
    """Background task for story generation - matches old backend pattern."""
    try:
        # Import required types, services and logger
        from ..types.domain import StoryStatus, Language
        from ..utils.logger import get_logger
        from ..services.supabase import get_supabase_service
        
        logger = get_logger(__name__)
        logger.info(f"Processing story generation for ID: {story_id}")
        
        # Get configuration
        config = load_config()
        
        # Create agents
        from ..agents.vision.agent import create_vision_agent
        from ..agents.storyteller.agent import create_storyteller_agent
        from ..agents.voice.agent import create_voice_agent
        
        vision_agent = create_vision_agent(config["agents"]["vision"])
        storyteller_agent = create_storyteller_agent(config["agents"]["storyteller"])
        voice_agent = create_voice_agent(config["agents"]["voice"])
        
        supabase = get_supabase_service()
        
        # Update status to processing
        await supabase.update_story_status(story_id, StoryStatus.PROCESSING)
        
        # Step 1: Analyze image
        logger.info(f"Analyzing image for story {story_id}")
        image_description = await vision_agent.process(image_data)
        
        # Step 2: Generate story
        logger.info(f"Generating story content for {story_id}")
        story_result = await storyteller_agent.process(image_description, language=language)
        
        # Step 3: Generate audio
        logger.info(f"Generating audio for story {story_id}")
        audio_data, content_type = await voice_agent.process(
            story_result["content"],
            language=language.value
        )
        
        # Upload audio to storage
        filename = f"{story_id}.mp3"
        audio_url = await supabase.upload_audio(audio_data, filename)
        
        # Update story with all results and mark as approved (matching old backend)
        updates = {
            "image_caption": image_description,
            "title": story_result["title"],
            "content": story_result["content"],
            "audio_filename": audio_url,
            "status": StoryStatus.APPROVED.value
        }
        
        await supabase.update_story(story_id, updates)
        logger.info(f"Story {story_id} completed successfully")
        
    except Exception as e:
        # Import logger and services for error handling
        from ..utils.logger import get_logger
        from ..types.domain import StoryStatus
        from ..services.supabase import get_supabase_service
        
        logger = get_logger(__name__)
        logger.error(f"Story processing failed for {story_id}: {e}")
        
        # Update story status to error
        supabase = get_supabase_service()
        await supabase.update_story(story_id, {
            "status": StoryStatus.ERROR.value
            # Note: metadata column doesn't exist in database
        })