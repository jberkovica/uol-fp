"""Core story processing logic that orchestrates agents."""
import uuid
from typing import Dict, Any, Optional
from datetime import datetime

from ..agents.vision.agent import create_vision_agent
from ..agents.storyteller.agent import create_storyteller_agent
from ..agents.voice.agent import create_voice_agent
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
            # Update status to processing
            await self.supabase.update_story_status(story_id, StoryStatus.PROCESSING)
            
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
            
            # Update story with content
            await self.supabase.update_story(story_id, {
                "title": story_result["title"],
                "content": story_result["content"]
            })
            
            # Step 3: Generate audio
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
                "audio_filename": audio_filename,  # Database stores filename only
            })
            
            # Determine final story status based on parent's approval mode
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
            
            # Update story with content
            await self.supabase.update_story(story_id, {
                "title": story_result["title"],
                "content": story_result["content"]
            })
            
            # Step 2: Generate audio
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
            
            # Determine final story status based on parent's approval mode
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