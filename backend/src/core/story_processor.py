"""Core story processing logic that orchestrates agents."""
import uuid
import asyncio
from typing import Dict, Any, Optional
from datetime import datetime

from ..agents.vision.agent import create_vision_agent
from ..agents.storyteller.agent import create_storyteller_agent
from ..agents.voice.agent import create_voice_agent
from ..agents.artist.agent import ArtistAgent
from ..services.supabase import get_supabase_service
from ..types.domain import Story, StoryStatus, InputFormat, Language
from ..types.requests import GenerateStoryRequest
from ..utils.logger import get_logger

logger = get_logger(__name__)


class StoryProcessor:
    """Orchestrates the story generation pipeline."""
    
    def __init__(self, agents_config: Dict[str, Any]):
        """Initialize with agents configuration."""
        self.vision_agent = create_vision_agent(agents_config["vision"])
        self.storyteller_agent = create_storyteller_agent(agents_config["storyteller"])
        self.voice_agent = create_voice_agent(agents_config["voice"])
        # Initialize artist agent if configured
        self.artist_agent = None
        if "artist" in agents_config:
            try:
                logger.info("Initializing artist agent...")
                self.artist_agent = ArtistAgent(agents_config["artist"])
                logger.info(f"Artist agent initialized successfully with vendor: {self.artist_agent.vendor}")
            except Exception as e:
                logger.error(f"Failed to initialize artist agent: {e}", exc_info=True)
                self.artist_agent = None
        self.supabase = get_supabase_service()
        
    async def process_image_to_story(self, request: GenerateStoryRequest, story_id: str) -> Story:
        """
        Process an image through the full pipeline to generate a story.
        
        Steps:
        1. Update story status to processing
        2. Analyze image to get description
        3. Generate story from description
        4. Generate audio from story
        5. Update story with results
        
        Args:
            request: The story generation request
            story_id: ID of the existing story record to update
        """
        
        try:
            # Story already created with PROCESSING status - no need to update
            
            # Step 1: Analyze image
            logger.info(f"Analyzing image for story {story_id}")
            image_description = await self.vision_agent.process(request.image_data)
            
            # Store image description in story_inputs table (not in stories table)
            from ..utils.config import load_config
            config = load_config()
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
            await self.supabase.create_story_input(story_input_data)
            
            # Step 2: Generate story - need to get kid info first
            logger.info(f"Generating story content for {story_id}")
            
            # Get kid information for personalized story
            kid = await self.supabase.get_kid(request.kid_id)
            if not kid:
                raise ValueError(f"Kid not found: {request.kid_id}")
            
            story_result = await self.storyteller_agent.process(
                image_description,
                language=request.language,
                kid_name=kid.name,
                age=kid.age,
                appearance=kid.appearance_description,
                genres=kid.favorite_genres or [],
                parent_notes=kid.parent_notes
            )
            
            # Update story with content and cover description
            await self.supabase.update_story(story_id, {
                "title": story_result["title"],
                "content": story_result["content"],
                "cover_description": story_result.get("cover_description", "")
            })
            
            # Steps 3 & 4: Generate audio and cover image in parallel
            logger.info(f"Starting parallel generation of audio and cover image for story {story_id}")
            
            # Create tasks for parallel execution
            tasks = []
            
            # Task 1: Generate audio
            async def generate_audio():
                try:
                    logger.info(f"Generating audio for story {story_id}")
                    audio_data, content_type = await self.voice_agent.process(
                        story_result["content"],
                        language=request.language.value
                    )
                    
                    # Upload audio to storage
                    filename = f"{story_id}.mp3"
                    audio_filename = await self.supabase.upload_audio(audio_data, filename)
                    
                    # Update story with audio filename
                    await self.supabase.update_story(story_id, {
                        "audio_filename": audio_filename,
                    })
                    
                    logger.info(f"Audio generation completed for story {story_id}")
                    return {"success": True, "audio_filename": audio_filename}
                except Exception as e:
                    logger.error(f"Audio generation failed for story {story_id}: {e}", exc_info=True)
                    return {"success": False, "error": str(e)}
            
            # Task 2: Generate cover image (if artist agent is available)
            async def generate_image():
                if not self.artist_agent:
                    logger.warning("Artist agent not available - no cover image will be generated")
                    return {"success": False, "reason": "Artist agent not available"}
                
                try:
                    logger.info(f"Starting cover image generation for story {story_id}")
                    logger.info(f"Artist vendor: {self.artist_agent.vendor}, model: {self.artist_agent.model}")
                    image_result = await self.artist_agent.process({
                        "story": {
                            "id": story_id,
                            "title": story_result["title"],
                            "cover_description": story_result.get("cover_description", "")  # Use new field
                        },
                        "kid": {
                            "name": kid.name,
                            "appearance_description": kid.appearance_description
                        }
                        # No longer passing image_data or image_description
                    })
                    
                    logger.info(f"Cover image generated successfully for story {story_id}")
                    return {"success": True, "image_result": image_result}
                except Exception as e:
                    logger.error(f"Failed to generate cover image for story {story_id}: {e}", exc_info=True)
                    return {"success": False, "error": str(e)}
            
            # Add tasks
            tasks.append(generate_audio())
            tasks.append(generate_image())
            
            # Execute tasks in parallel
            results = await asyncio.gather(*tasks, return_exceptions=True)
            audio_result, image_result = results
            
            # Log results
            logger.info(f"Audio generation result: {audio_result.get('success', False) if isinstance(audio_result, dict) else 'Exception occurred'}")
            logger.info(f"Image generation result: {image_result.get('success', False) if isinstance(image_result, dict) else 'Exception occurred'}")
            
            # Handle exceptions in results
            if isinstance(audio_result, Exception):
                logger.error(f"Audio generation raised exception: {audio_result}")
                audio_result = {"success": False, "error": str(audio_result)}
            
            if isinstance(image_result, Exception):
                logger.error(f"Image generation raised exception: {image_result}")
                image_result = {"success": False, "error": str(image_result)}
            
            # Audio is optional - continue even if it fails
            if not audio_result.get("success", False):
                logger.warning(f"Audio generation failed for story {story_id}, continuing without audio: {audio_result.get('error', 'Unknown error')}")
                # Store audio error for potential retry later
                await self.supabase.update_story(story_id, {
                    "audio_error": audio_result.get('error', 'Unknown error'),
                    "audio_failed_at": datetime.utcnow().isoformat()
                })
            
            # Handle image generation failure with fallback to default cover
            if not image_result.get("success", False):
                logger.info(f"Image generation failed for story {story_id}, assigning default cover")
                await self._assign_default_cover(story_id, story_result.get("content", ""))
            
            # Only determine final status after ALL processing is complete
            final_status = await self._determine_story_status(request.kid_id, story_id)
            story = await self.supabase.update_story(story_id, {
                "status": final_status.value
            })
            
            logger.info(f"Story {story_id} completed with status: {final_status.value}")
            return story
            
        except Exception as e:
            logger.error(f"Story processing failed for {story_id}: {e}")
            # Update story status to error
            await self.supabase.update_story(story_id, {
                "status": StoryStatus.ERROR.value
            })
            raise
    
    async def _determine_story_status(self, kid_id: str, story_id: str) -> StoryStatus:
        """
        Determine the final story status based on parent's approval mode.
        """
        try:
            # Get kid profile to find parent user_id
            kid = await self.supabase.get_kid(kid_id)
            if not kid:
                logger.error(f"Kid profile not found: {kid_id}")
                return StoryStatus.PENDING  # Safe fallback
            
            # Get parent's approval mode
            approval_mode = await self.supabase.get_user_approval_mode(kid.user_id)
            logger.info(f"Parent approval mode for kid {kid_id}: {approval_mode}")
            
            if approval_mode == 'auto':
                # Auto-approve stories
                return StoryStatus.APPROVED
            elif approval_mode == 'app':
                # Require parent review in app
                return StoryStatus.PENDING
            elif approval_mode == 'email':
                # Require parent review via email - send notification
                await self._send_email_notification(story_id, kid)
                return StoryStatus.PENDING
            else:
                # Unknown mode, default to pending for safety
                logger.warning(f"Unknown approval mode: {approval_mode}, defaulting to pending")
                return StoryStatus.PENDING
                
        except Exception as e:
            logger.error(f"Error determining story status: {e}")
            return StoryStatus.PENDING  # Safe fallback
    
    async def _send_email_notification(self, story_id: str, kid):
        """
        Send email notification to parent for story review.
        """
        try:
            # Get parent's email address
            parent_email = await self.supabase.get_user_email(kid.user_id)
            if not parent_email:
                logger.error(f"No email found for parent of kid {kid.id}")
                return
            
            # Get story details
            story = await self.supabase.get_story(story_id)
            if not story:
                logger.error(f"Story not found: {story_id}")
                return
            
            # Get approval mode to determine email type
            approval_mode = await self.supabase.get_user_approval_mode(kid.user_id)
            
            # Call Supabase Edge Function for email notification
            result = await self.supabase.client.functions.invoke(
                "send-story-notification",
                {"body": {
                    "storyId": story_id,
                    "kidId": kid.id,
                    "parentEmail": parent_email,
                    "parentName": parent_email.split('@')[0],  # Extract name from email as fallback
                    "kidName": kid.name,
                    "storyTitle": story.title,
                    "approvalMode": approval_mode
                }}
            )
            
            if result.get("error"):
                logger.error(f"Failed to send email notification for story {story_id}: {result['error']}")
            else:
                logger.info(f"Email notification sent for story {story_id} to {parent_email}")
                
        except Exception as e:
            logger.error(f"Error sending email notification for story {story_id}: {e}")
            # Don't raise - email failure shouldn't stop story processing
    
    async def _assign_default_cover(self, story_id: str, story_content: str) -> None:
        """Assign a default cover image when AI generation fails."""
        try:
            # Build URL for default cover in Supabase Storage
            # Format: https://[project].supabase.co/storage/v1/object/public/story-covers/default/general.png
            supabase_service = get_supabase_service()
            base_url = supabase_service.client.supabase_url
            
            # Using single default cover for now
            cover_url = f"{base_url}/storage/v1/object/public/story-covers/default/general.png"
            thumbnail_url = f"{base_url}/storage/v1/object/public/story-covers/default/general-thumbnail.png"
            
            # Update story with default cover URLs
            await supabase_service.update_story(story_id, {
                'cover_image_url': cover_url,
                'cover_image_thumbnail_url': thumbnail_url,
                'cover_image_metadata': {
                    'type': 'default',
                    'assigned_at': datetime.now().isoformat(),
                    'reason': 'AI generation failed'
                }
            })
            
            logger.info(f"Assigned default cover for story {story_id}")
            
        except Exception as e:
            logger.error(f"Error assigning default cover for story {story_id}: {e}")
            # Don't raise - this is a fallback, shouldn't block story completion
    
    async def process_text_to_story(self, story_id: str, text: str, kid_id: str, language: str) -> None:
        """
        Process text to generate a story (used for both text input and transcribed audio).
        
        Steps:
        1. Generate story from text
        2. Generate audio from story
        3. Update story with results
        """
        try:
            logger.info(f"Processing text to story for {story_id}")
            
            # Step 1: Generate story from text - need to get kid info first
            logger.info(f"Generating story content for {story_id} from text: {text[:50]}...")
            
            # Get kid information for personalized story
            kid = await self.supabase.get_kid(kid_id)
            if not kid:
                raise ValueError(f"Kid not found: {kid_id}")
            
            story_result = await self.storyteller_agent.process(
                text,
                language=Language(language),
                kid_name=kid.name,
                age=kid.age,
                appearance=kid.appearance_description,
                genres=kid.favorite_genres or [],
                parent_notes=kid.parent_notes
            )
            
            # Update story with content and cover description
            await self.supabase.update_story(story_id, {
                "title": story_result["title"],
                "content": story_result["content"],
                "cover_description": story_result.get("cover_description", "")
            })
            
            # Steps 2 & 3: Generate audio and cover image in parallel
            logger.info(f"Starting parallel generation of audio and cover image for story {story_id}")
            
            # Create tasks for parallel execution
            tasks = []
            
            # Task 1: Generate audio
            async def generate_audio():
                try:
                    logger.info(f"Generating audio for story {story_id}")
                    audio_data, content_type = await self.voice_agent.process(
                        story_result["content"],
                        language=language
                    )
                    
                    # Upload audio to storage
                    filename = f"{story_id}.mp3"
                    audio_filename = await self.supabase.upload_audio(audio_data, filename)
                    
                    # Update story with audio filename
                    await self.supabase.update_story(story_id, {
                        "audio_filename": audio_filename,
                    })
                    
                    logger.info(f"Audio generation completed for story {story_id}")
                    return {"success": True, "audio_filename": audio_filename}
                except Exception as e:
                    logger.error(f"Audio generation failed for story {story_id}: {e}", exc_info=True)
                    return {"success": False, "error": str(e)}
            
            # Task 2: Generate cover image (if artist agent is available)
            async def generate_image():
                if not self.artist_agent:
                    logger.warning("Artist agent not available - no cover image will be generated")
                    return {"success": False, "reason": "Artist agent not available"}
                
                try:
                    logger.info(f"Starting cover image generation for story {story_id}")
                    logger.info(f"Artist vendor: {self.artist_agent.vendor}, model: {self.artist_agent.model}")
                    image_result = await self.artist_agent.process({
                        "story": {
                            "id": story_id,
                            "title": story_result["title"],
                            "cover_description": story_result.get("cover_description", "")  # Use new field
                        },
                        "kid": {
                            "name": kid.name,
                            "appearance_description": kid.appearance_description
                        }
                        # No image_data or text description for text stories
                    })
                    
                    logger.info(f"Cover image generated successfully for story {story_id}")
                    return {"success": True, "image_result": image_result}
                except Exception as e:
                    logger.error(f"Failed to generate cover image for story {story_id}: {e}", exc_info=True)
                    return {"success": False, "error": str(e)}
            
            # Add tasks
            tasks.append(generate_audio())
            tasks.append(generate_image())
            
            # Execute tasks in parallel
            results = await asyncio.gather(*tasks, return_exceptions=True)
            audio_result, image_result = results
            
            # Log results
            logger.info(f"Audio generation result: {audio_result.get('success', False) if isinstance(audio_result, dict) else 'Exception occurred'}")
            logger.info(f"Image generation result: {image_result.get('success', False) if isinstance(image_result, dict) else 'Exception occurred'}")
            
            # Handle exceptions in results
            if isinstance(audio_result, Exception):
                logger.error(f"Audio generation raised exception: {audio_result}")
                audio_result = {"success": False, "error": str(audio_result)}
            
            if isinstance(image_result, Exception):
                logger.error(f"Image generation raised exception: {image_result}")
                image_result = {"success": False, "error": str(image_result)}
            
            # Audio is optional - continue even if it fails
            if not audio_result.get("success", False):
                logger.warning(f"Audio generation failed for story {story_id}, continuing without audio: {audio_result.get('error', 'Unknown error')}")
                # Store audio error for potential retry later
                await self.supabase.update_story(story_id, {
                    "audio_error": audio_result.get('error', 'Unknown error'),
                    "audio_failed_at": datetime.utcnow().isoformat()
                })

            # Handle image generation failure with fallback to default cover
            if not image_result.get("success", False):
                logger.info(f"Image generation failed for story {story_id}, assigning default cover")
                await self._assign_default_cover(story_id, story_result.get("content", ""))
            
            # Only determine final status after ALL processing is complete
            final_status = await self._determine_story_status(kid_id, story_id)
            await self.supabase.update_story(story_id, {
                "status": final_status.value
            })
            
            logger.info(f"Story {story_id} completed with status: {final_status.value}")
            
        except Exception as e:
            logger.error(f"Story processing failed for {story_id}: {e}")
            # Update story status to error
            await self.supabase.update_story(story_id, {
                "status": StoryStatus.ERROR.value
            })
            raise
    
    async def process_voice_to_story(self, audio_data: str, kid_id: str, language: Language = Language.ENGLISH) -> Story:
        """
        Future: Process voice recording to generate a story.
        """
        # This will use speech agent -> storyteller -> voice agent
        raise NotImplementedError("Voice-to-story not yet implemented")


# Global processor instance
_story_processor: Optional[StoryProcessor] = None


def get_story_processor(agents_config: Dict[str, Any]) -> StoryProcessor:
    """Get or create story processor instance."""
    global _story_processor
    if not _story_processor:
        _story_processor = StoryProcessor(agents_config)
    return _story_processor