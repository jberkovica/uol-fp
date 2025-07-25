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
        
    async def process_image_to_story(self, request: GenerateStoryRequest) -> Story:
        """
        Process an image through the full pipeline to generate a story.
        
        Steps:
        1. Create story record with pending status
        2. Analyze image to get description
        3. Generate story from description
        4. Generate audio from story
        5. Update story with results
        """
        story_id = str(uuid.uuid4())
        
        # Create initial story record
        story_data = {
            "id": story_id,
            "kid_id": request.kid_id,
            "title": "New Story",
            "content": "",
            "input_format": InputFormat.IMAGE.value,
            "language": request.language.value,
            "status": StoryStatus.PENDING.value,
        }
        
        story = await self.supabase.create_story(story_data)
        
        try:
            # Update status to processing
            await self.supabase.update_story_status(story_id, StoryStatus.PROCESSING)
            
            # Step 1: Analyze image
            logger.info(f"Analyzing image for story {story_id}")
            image_description = await self.vision_agent.process(request.image_data)
            
            # Update story with image description
            await self.supabase.update_story(story_id, {
                "image_description": image_description
            })
            
            # Step 2: Generate story
            logger.info(f"Generating story content for {story_id}")
            story_result = await self.storyteller_agent.process(
                image_description,
                language=request.language
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
            audio_url = await self.supabase.upload_audio(audio_data, filename)
            
            # Update story with audio URL and mark as approved
            story = await self.supabase.update_story(story_id, {
                "audio_filename": audio_url,  # Database stores as audio_filename
                "status": StoryStatus.APPROVED.value
            })
            
            logger.info(f"Story {story_id} completed successfully")
            return story
            
        except Exception as e:
            logger.error(f"Story processing failed for {story_id}: {e}")
            # Update story status to error
            await self.supabase.update_story(story_id, {
                "status": StoryStatus.ERROR.value,
                "metadata": {"error": str(e)}
            })
            raise
    
    async def process_text_to_story(self, prompt: str, kid_id: str, language: Language = Language.ENGLISH) -> Story:
        """
        Future: Process text prompt to generate a story.
        """
        # This will skip the vision agent and go directly to storyteller
        raise NotImplementedError("Text-to-story not yet implemented")
    
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