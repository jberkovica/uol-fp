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
            
            # Select random background music
            from ..services.background_music_service import background_music_service
            background_music_filename = background_music_service.get_random_track()
            if background_music_filename:
                logger.info(f"Selected background music: {background_music_filename}")
            else:
                logger.warning("No background music tracks available")
            
            # Create story record (matching old backend format)
            story_data = {
                "kid_id": request.kid_id,
                "child_name": kid.name,  # Required field - kid's name
                "title": "New Story",
                "content": "",
                "language": request.language.value,
                "status": StoryStatus.PENDING.value,
                "background_music_filename": background_music_filename
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
    
    @app.post("/generate-story-from-text/")
    async def generate_story_from_text(
        request: dict,  # Using dict to accept text_input field
        background_tasks: BackgroundTasks
    ):
        """Main endpoint for story generation from text input."""
        try:
            # Extract and validate input
            text_input = request.get("text_input", "").strip()
            kid_id = request.get("kid_id")
            language = request.get("language", "en")
            
            if not text_input:
                raise ValidationError("text_input is required")
            if len(text_input) < 10:
                raise ValidationError("text_input must be at least 10 characters")
            if len(text_input) > 500:
                raise ValidationError("text_input must be less than 500 characters")
            
            validate_uuid(kid_id, "kid_id")
            
            # Verify kid exists
            supabase = get_supabase_service()
            kid = await supabase.get_kid(kid_id)
            if not kid:
                raise NotFoundError("Kid profile", kid_id)
            
            # Select random background music
            from ..services.background_music_service import background_music_service
            background_music_filename = background_music_service.get_random_track()
            if background_music_filename:
                logger.info(f"Selected background music: {background_music_filename}")
            else:
                logger.warning("No background music tracks available")
            
            # Create story record
            story_data = {
                "kid_id": kid_id,
                "child_name": kid.name,
                "title": "New Story",
                "content": "",
                "language": language,
                "status": StoryStatus.PENDING.value,
                "background_music_filename": background_music_filename
            }
            story = await supabase.create_story(story_data)
            
            # Process story in background with text input
            background_tasks.add_task(
                process_text_story_generation_background,
                story.id,
                text_input,
                kid_id,
                Language(language)
            )
            
            return {
                "story_id": story.id,
                "status": "processing",
                "message": "Story generation from text started"
            }
            
        except (NotFoundError, ValidationError) as e:
            raise HTTPException(status_code=400, detail=str(e))
        except Exception as e:
            import traceback
            logger.error(f"Text story generation failed: {e}")
            logger.error(f"Traceback: {traceback.format_exc()}")
            raise HTTPException(status_code=500, detail=f"Failed to start text story generation: {str(e)}")
    
    @app.post("/generate-story-from-audio/")
    async def generate_story_from_audio(
        request: dict,  # Using dict to accept audio_data field
        background_tasks: BackgroundTasks
    ):
        """Main endpoint for story generation from audio input."""
        try:
            # Extract and validate input
            audio_data = request.get("audio_data", "").strip()
            kid_id = request.get("kid_id")
            language = request.get("language", "en")
            
            if not audio_data:
                raise ValidationError("audio_data is required")
            
            validate_uuid(kid_id, "kid_id")
            
            # Verify kid exists
            supabase = get_supabase_service()
            kid = await supabase.get_kid(kid_id)
            if not kid:
                raise NotFoundError("Kid profile", kid_id)
            
            # Select random background music
            from ..services.background_music_service import background_music_service
            background_music_filename = background_music_service.get_random_track()
            if background_music_filename:
                logger.info(f"Selected background music: {background_music_filename}")
            else:
                logger.warning("No background music tracks available")
            
            # Create story record
            story_data = {
                "kid_id": kid_id,
                "child_name": kid.name,
                "title": "New Story",
                "content": "",
                "language": language,
                "status": StoryStatus.PENDING.value,
                "background_music_filename": background_music_filename
            }
            story = await supabase.create_story(story_data)
            
            # Process story in background with audio input
            background_tasks.add_task(
                process_audio_story_generation_background,
                story.id,
                audio_data,
                kid_id,
                Language(language)
            )
            
            return {
                "story_id": story.id,
                "status": "processing",
                "message": "Story generation from audio started"
            }
            
        except (NotFoundError, ValidationError) as e:
            raise HTTPException(status_code=400, detail=str(e))
        except Exception as e:
            import traceback
            logger.error(f"Audio story generation failed: {e}")
            logger.error(f"Traceback: {traceback.format_exc()}")
            raise HTTPException(status_code=500, detail=f"Failed to start audio story generation: {str(e)}")
    
    @app.get("/story/{story_id}")
    async def get_story(story_id: str):
        """Main endpoint for getting a story."""
        try:
            validate_uuid(story_id, "story_id")
            
            supabase = get_supabase_service()
            story = await supabase.get_story(story_id)
            
            if not story:
                raise NotFoundError("Story", story_id)
            
            # Get story input data for caption
            story_input = await supabase.get_story_input(story_id)
            caption = story_input.get("input_value", "") if story_input else ""
                
            return {
                "story_id": story.id,  # Flutter expects 'story_id', not 'id'
                "kid_id": story.kid_id,
                "title": story.title,
                "content": story.content,
                "caption": caption,  # Include caption from story_inputs
                "audio_url": story.audio_url,  # Use computed URL, not filename
                "background_music_url": story.background_music_url,  # Include background music URL
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
        audio_filename = await supabase.upload_audio(audio_data, filename)
        
        # Get kid and user approval mode to determine final status
        kid = await supabase.get_kid(kid_id)
        approval_mode = await supabase.get_user_approval_mode(kid.user_id)
        logger.info(f"User {kid.user_id} approval mode: {approval_mode}")
        
        # Set status based on approval mode
        final_status = StoryStatus.APPROVED.value if approval_mode == "auto" else StoryStatus.PENDING.value
        
        # Update story with all results
        updates = {
            "title": story_result["title"],
            "content": story_result["content"],
            "audio_filename": audio_filename,
            "status": final_status
        }
        
        await supabase.update_story(story_id, updates)
        
        # Insert story input data into dedicated table
        story_input_data = {
            "story_id": story_id,
            "input_type": "image",
            "input_value": image_description,
            "metadata": {
                "vision_model": config["agents"]["vision"]["model"],
                "vision_provider": config["agents"]["vision"]["vendor"],
                "processing_timestamp": datetime.utcnow().isoformat()
            }
        }
        await supabase.create_story_input(story_input_data)
        
        # Send email notification if email approval mode
        if approval_mode == "email":
            try:
                parent_email = await supabase.get_user_email(kid.user_id)
                story = await supabase.get_story(story_id)
                
                logger.info(f"Sending email notification to {parent_email} for {kid.name}'s story")
                
                # Clean story content to avoid JSON issues
                import json
                story_content = story.content[:500] + "..." if len(story.content) > 500 else story.content
                
                payload = {
                    "storyId": story_id,
                    "parentEmail": parent_email,
                    "storyTitle": story.title,
                    "storyContent": story_content,
                    "childName": kid.name,
                    "approvalMode": approval_mode
                }
                
                result = supabase.client.functions.invoke(
                    "send-story-notification",
                    {"body": payload}
                )
                
                # Parse response if it's bytes
                if isinstance(result, bytes):
                    try:
                        response_data = json.loads(result.decode('utf-8'))
                        if response_data.get('success'):
                            logger.info(f"Email notification sent successfully for story {story_id}. Email ID: {response_data.get('emailId')}")
                        else:
                            logger.error(f"Email notification failed: {response_data.get('error')}")
                    except Exception as e:
                        logger.error(f"Failed to parse Edge function response: {e}")
                else:
                    logger.warning(f"Unexpected response type from Edge function: {type(result)}")
            except Exception as email_error:
                logger.error(f"Failed to send email notification for story {story_id}: {email_error}")
                import traceback
                logger.error(f"Traceback: {traceback.format_exc()}")
        
        logger.info(f"Story {story_id} completed successfully with status: {final_status}")
        
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


async def process_text_story_generation_background(
    story_id: str,
    text_input: str,
    kid_id: str,
    language
):
    """Background task for text-based story generation."""
    try:
        # Import required types, services and logger
        from ..types.domain import StoryStatus, Language
        from ..utils.logger import get_logger
        from ..services.supabase import get_supabase_service
        
        logger = get_logger(__name__)
        logger.info(f"Processing text-based story generation for ID: {story_id}")
        logger.debug(f"Text input: {text_input[:50]}..." if len(text_input) > 50 else f"Text input: {text_input}")
        
        # Get configuration
        config = load_config()
        
        # Create agents
        from ..agents.storyteller.agent import create_storyteller_agent
        from ..agents.voice.agent import create_voice_agent
        
        storyteller_agent = create_storyteller_agent(config["agents"]["storyteller"])
        voice_agent = create_voice_agent(config["agents"]["voice"])
        
        supabase = get_supabase_service()
        
        # Update status to processing
        await supabase.update_story_status(story_id, StoryStatus.PROCESSING)
        
        # Step 1: Generate story directly from text input (skip vision step)
        logger.info(f"Generating story content from text for {story_id}")
        story_result = await storyteller_agent.process(text_input, language=language)
        
        # Step 2: Generate audio
        logger.info(f"Generating audio for story {story_id}")
        audio_data, content_type = await voice_agent.process(
            story_result["content"],
            language=language.value
        )
        
        # Upload audio to storage
        filename = f"{story_id}.mp3"
        audio_filename = await supabase.upload_audio(audio_data, filename)
        
        # Get kid and user approval mode to determine final status
        kid = await supabase.get_kid(kid_id)
        approval_mode = await supabase.get_user_approval_mode(kid.user_id)
        logger.info(f"User {kid.user_id} approval mode: {approval_mode}")
        
        # Set status based on approval mode
        final_status = StoryStatus.APPROVED.value if approval_mode == "auto" else StoryStatus.PENDING.value
        
        # Update story with all results
        updates = {
            "title": story_result["title"],
            "content": story_result["content"],
            "audio_filename": audio_filename,
            "status": final_status
        }
        
        await supabase.update_story(story_id, updates)
        
        # Insert story input data into dedicated table
        story_input_data = {
            "story_id": story_id,
            "input_type": "text",
            "input_value": text_input,
            "metadata": {
                "direct_input": True,
                "character_count": len(text_input),
                "processing_timestamp": datetime.utcnow().isoformat()
            }
        }
        await supabase.create_story_input(story_input_data)
        
        # Send email notification if email approval mode
        if approval_mode == "email":
            try:
                parent_email = await supabase.get_user_email(kid.user_id)
                story = await supabase.get_story(story_id)
                
                logger.info(f"Sending email notification to {parent_email} for {kid.name}'s story")
                
                # Clean story content to avoid JSON issues
                import json
                story_content = story.content[:500] + "..." if len(story.content) > 500 else story.content
                
                payload = {
                    "storyId": story_id,
                    "parentEmail": parent_email,
                    "storyTitle": story.title,
                    "storyContent": story_content,
                    "childName": kid.name,
                    "approvalMode": approval_mode
                }
                
                result = supabase.client.functions.invoke(
                    "send-story-notification",
                    {"body": payload}
                )
                
                # Parse response if it's bytes
                if isinstance(result, bytes):
                    try:
                        response_data = json.loads(result.decode('utf-8'))
                        if response_data.get('success'):
                            logger.info(f"Email notification sent successfully for story {story_id}. Email ID: {response_data.get('emailId')}")
                        else:
                            logger.error(f"Email notification failed: {response_data.get('error')}")
                    except Exception as e:
                        logger.error(f"Failed to parse Edge function response: {e}")
                else:
                    logger.warning(f"Unexpected response type from Edge function: {type(result)}")
            except Exception as email_error:
                logger.error(f"Failed to send email notification for story {story_id}: {email_error}")
                import traceback
                logger.error(f"Traceback: {traceback.format_exc()}")
        
        logger.info(f"Text-based story {story_id} completed successfully with status: {final_status}")
        
    except Exception as e:
        # Import logger and services for error handling
        from ..utils.logger import get_logger
        from ..types.domain import StoryStatus
        from ..services.supabase import get_supabase_service
        
        logger = get_logger(__name__)
        logger.error(f"Text story processing failed for {story_id}: {e}")
        import traceback
        logger.error(f"Traceback: {traceback.format_exc()}")
        
        # Update story status to error
        supabase = get_supabase_service()
        await supabase.update_story(story_id, {
            "status": StoryStatus.ERROR.value
        })


async def process_audio_story_generation_background(
    story_id: str,
    audio_data: str,
    kid_id: str,
    language
):
    """Background task for audio-based story generation with Whisper transcription."""
    try:
        # Import required types, services and logger
        from ..types.domain import StoryStatus, Language
        from ..utils.logger import get_logger
        from ..services.supabase import get_supabase_service
        
        logger = get_logger(__name__)
        logger.info(f"Processing audio-based story generation for ID: {story_id}")
        
        # Get configuration
        config = load_config()
        
        # Create agents
        from ..agents.storyteller.agent import create_storyteller_agent
        from ..agents.voice.agent import create_voice_agent
        
        storyteller_agent = create_storyteller_agent(config["agents"]["storyteller"])
        voice_agent = create_voice_agent(config["agents"]["voice"])
        
        supabase = get_supabase_service()
        
        # Update status to processing
        await supabase.update_story_status(story_id, StoryStatus.PROCESSING)
        
        # Step 1: Convert audio to text using OpenAI Whisper
        logger.info(f"Transcribing audio for story {story_id}")
        import base64
        import tempfile
        import os
        
        # Decode base64 audio data
        audio_bytes = base64.b64decode(audio_data)
        
        # Create temporary file for audio
        with tempfile.NamedTemporaryFile(delete=False, suffix='.m4a') as temp_audio:
            temp_audio.write(audio_bytes)
            temp_audio_path = temp_audio.name
        
        try:
            # Call OpenAI Whisper API for transcription
            import openai
            
            # Get OpenAI API key from config
            whisper_config = config["agents"]["whisper"]
            api_key = whisper_config.get("api_key")
            
            logger.debug(f"Whisper config: {whisper_config}")
            logger.debug(f"API key type: {type(api_key)}, value: {api_key}")
            
            if not api_key:
                raise Exception("OpenAI API key not found in configuration")
            
            # Ensure api_key is a string
            api_key = str(api_key)
            
            client = openai.OpenAI(api_key=api_key)
            
            # Transcribe audio file using user's selected language
            with open(temp_audio_path, 'rb') as audio_file:
                transcript_response = client.audio.transcriptions.create(
                    model="whisper-1",
                    file=audio_file,
                    language=language.value  # Use app's selected language directly
                )
            
            transcribed_text = transcript_response.text
            logger.info(f"Audio transcribed to text: {transcribed_text[:100]}...")
            
        finally:
            # Clean up temporary file
            if os.path.exists(temp_audio_path):
                os.unlink(temp_audio_path)
        
        # Step 2: Generate story from transcribed text
        logger.info(f"Generating story content from transcribed text for {story_id}")
        story_result = await storyteller_agent.process(transcribed_text, language=language)
        
        # Step 3: Generate audio narration
        logger.info(f"Generating audio for story {story_id}")
        audio_data, content_type = await voice_agent.process(
            story_result["content"],
            language=language.value
        )
        
        # Upload audio to storage
        filename = f"{story_id}.mp3"
        audio_filename = await supabase.upload_audio(audio_data, filename)
        
        # Get kid and user approval mode to determine final status
        kid = await supabase.get_kid(kid_id)
        approval_mode = await supabase.get_user_approval_mode(kid.user_id)
        logger.info(f"User {kid.user_id} approval mode: {approval_mode}")
        
        # Set status based on approval mode
        final_status = StoryStatus.APPROVED.value if approval_mode == "auto" else StoryStatus.PENDING.value
        
        # Update story with all results
        updates = {
            "title": story_result["title"],
            "content": story_result["content"],
            "audio_filename": audio_filename,
            "status": final_status
        }
        
        await supabase.update_story(story_id, updates)
        
        # Insert story input data into dedicated table
        story_input_data = {
            "story_id": story_id,
            "input_type": "audio",
            "input_value": transcribed_text,
            "metadata": {
                "whisper_model": config["agents"]["whisper"]["model"],
                "whisper_provider": config["agents"]["whisper"]["vendor"],
                "transcription_language": language.value,
                "transcription_length": len(transcribed_text),
                "processing_timestamp": datetime.utcnow().isoformat()
            }
        }
        await supabase.create_story_input(story_input_data)
        
        # Send email notification if email approval mode
        if approval_mode == "email":
            try:
                parent_email = await supabase.get_user_email(kid.user_id)
                story = await supabase.get_story(story_id)
                
                logger.info(f"Sending email notification to {parent_email} for {kid.name}'s story")
                
                # Clean story content to avoid JSON issues
                import json
                story_content = story.content[:500] + "..." if len(story.content) > 500 else story.content
                
                payload = {
                    "storyId": story_id,
                    "parentEmail": parent_email,
                    "storyTitle": story.title,
                    "storyContent": story_content,
                    "childName": kid.name,
                    "approvalMode": approval_mode
                }
                
                result = supabase.client.functions.invoke(
                    "send-story-notification",
                    {"body": payload}
                )
                
                # Parse response if it's bytes
                if isinstance(result, bytes):
                    try:
                        response_data = json.loads(result.decode('utf-8'))
                        if response_data.get('success'):
                            logger.info(f"Email notification sent successfully for story {story_id}. Email ID: {response_data.get('emailId')}")
                        else:
                            logger.error(f"Email notification failed: {response_data.get('error')}")
                    except Exception as e:
                        logger.error(f"Failed to parse Edge function response: {e}")
                else:
                    logger.warning(f"Unexpected response type from Edge function: {type(result)}")
            except Exception as email_error:
                logger.error(f"Failed to send email notification for story {story_id}: {email_error}")
                import traceback
                logger.error(f"Traceback: {traceback.format_exc()}")
        
        logger.info(f"Audio-based story {story_id} completed successfully with status: {final_status}")
        
    except Exception as e:
        # Import logger and services for error handling
        from ..utils.logger import get_logger
        from ..types.domain import StoryStatus
        from ..services.supabase import get_supabase_service
        
        logger = get_logger(__name__)
        logger.error(f"Audio story processing failed for {story_id}: {e}")
        import traceback
        logger.error(f"Traceback: {traceback.format_exc()}")
        
        # Update story status to error
        supabase = get_supabase_service()
        await supabase.update_story(story_id, {
            "status": StoryStatus.ERROR.value
        })