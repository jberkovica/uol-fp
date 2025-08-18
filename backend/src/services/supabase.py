"""Supabase service for database and storage operations."""
import os
from typing import List, Optional, Dict, Any
from datetime import datetime
import uuid
from supabase import create_client, Client
from ..types.domain import Kid, Story, StoryStatus, Language
from ..types.requests import CreateKidRequest, UpdateKidRequest
from ..utils.logger import get_logger
from ..utils.config import get_config

logger = get_logger(__name__)


class SupabaseService:
    """Service for all Supabase operations."""
    
    def __init__(self, url: str = None, key: str = None):
        """Initialize Supabase client."""
        self.config = get_config()
        self.url = url or os.getenv("SUPABASE_URL")
        self.key = key or os.getenv("SUPABASE_SERVICE_KEY")
        self.storage_bucket = self.config["supabase"]["storage"]["bucket"]
        
        if not self.url or not self.key:
            raise ValueError("Supabase URL and KEY must be provided")
            
        self.client: Client = create_client(self.url, self.key)
        logger.info("Supabase client initialized")
    
    # Kid Profile Operations
    async def create_kid(self, request: CreateKidRequest) -> Kid:
        """Create a new kid profile."""
        kid_id = str(uuid.uuid4())
        data = {
            "id": kid_id,
            "user_id": request.user_id,
            "name": request.name,
            "age": request.age,
            "gender": request.gender,
            "avatar_type": request.avatar_type,
            "appearance_method": request.appearance_method,
            "appearance_description": request.appearance_description,
            "favorite_genres": request.favorite_genres,
            "parent_notes": request.parent_notes,
            "preferred_language": request.preferred_language,
            "created_at": datetime.utcnow().isoformat(),
        }
        
        result = self.client.table("kids").insert(data).execute()
        return Kid(**result.data[0])
    
    async def get_kid(self, kid_id: str) -> Optional[Kid]:
        """Get a kid profile by ID."""
        result = self.client.table("kids").select("*").eq("id", kid_id).execute()
        if result.data:
            return Kid(**result.data[0])
        return None
    
    async def get_kids_for_user(self, user_id: str) -> List[Kid]:
        """Get all kid profiles for a user."""
        result = self.client.table("kids").select("*").eq("user_id", user_id).execute()
        return [Kid(**kid) for kid in result.data]
    
    async def get_kids_with_story_counts(self, user_id: str) -> List[Dict]:
        """Get all kid profiles for a user with their story counts in a single query.
        This is MUCH faster than calling get_all_stories_for_kid for each kid separately.
        """
        # Use Supabase's ability to count related records efficiently
        # This creates a single query with a LEFT JOIN to count stories
        result = self.client.table("kids").select(
            "*, stories(count)"
        ).eq("user_id", user_id).execute()
        
        kids_with_counts = []
        for kid_data in result.data:
            # Extract story count from the nested response
            stories_data = kid_data.get("stories", [])
            story_count = stories_data[0].get("count", 0) if stories_data else 0
            
            # Remove the stories field and create kid dict with count
            kid_dict = {k: v for k, v in kid_data.items() if k != "stories"}
            kid_dict["stories_count"] = story_count
            
            kids_with_counts.append(kid_dict)
        
        return kids_with_counts
    
    async def update_kid(self, kid_id: str, request: UpdateKidRequest) -> Optional[Kid]:
        """Update a kid profile."""
        update_data = request.dict(exclude_unset=True)
        update_data["updated_at"] = datetime.utcnow().isoformat()
        
        result = self.client.table("kids").update(update_data).eq("id", kid_id).execute()
        if result.data:
            return Kid(**result.data[0])
        return None
    
    async def delete_kid(self, kid_id: str) -> bool:
        """Delete a kid profile."""
        result = self.client.table("kids").delete().eq("id", kid_id).execute()
        return len(result.data) > 0
    
    # Story Operations
    async def create_story(self, story_data: Dict[str, Any]) -> Story:
        """Create a new story."""
        story_id = str(uuid.uuid4())
        data = {
            "id": story_id,
            **story_data,
            "created_at": datetime.utcnow().isoformat(),
        }
        
        result = self.client.table("stories").insert(data).execute()
        return Story(**result.data[0])
    
    async def get_story(self, story_id: str) -> Optional[Story]:
        """Get a story by ID."""
        result = self.client.table("stories").select("*").eq("id", story_id).execute()
        if result.data:
            story_data = result.data[0]
            # Convert audio_filename to audio_url
            audio_filename = story_data.get("audio_filename")
            if audio_filename:
                story_data["audio_url"] = self.build_audio_url(audio_filename)
            # Convert background_music_filename to background_music_url
            background_music_filename = story_data.get("background_music_filename")
            if background_music_filename:
                story_data["background_music_url"] = self.build_background_music_url(background_music_filename)
            return Story(**story_data)
        return None
    
    async def get_stories_for_kid(self, kid_id: str, limit: int = 20, offset: int = 0) -> List[Story]:
        """Get all approved stories for a kid (children should only see approved stories)."""
        result = (
            self.client.table("stories")
            .select("*")
            .eq("kid_id", kid_id)
            .eq("status", "approved")  # Only show approved stories to children
            .order("created_at", desc=True)
            .limit(limit)
            .offset(offset)
            .execute()
        )
        # Convert filenames to URLs for each story
        stories = []
        for story_data in result.data:
            audio_filename = story_data.get("audio_filename")
            if audio_filename:
                story_data["audio_url"] = self.build_audio_url(audio_filename)
            background_music_filename = story_data.get("background_music_filename")
            if background_music_filename:
                story_data["background_music_url"] = self.build_background_music_url(background_music_filename)
            stories.append(Story(**story_data))
        return stories
    
    async def get_all_stories_for_kid(self, kid_id: str, limit: int = 20, offset: int = 0) -> List[Story]:
        """Get ALL stories for a kid (for parent dashboard - includes pending/rejected)."""
        result = (
            self.client.table("stories")
            .select("*")
            .eq("kid_id", kid_id)
            .order("created_at", desc=True)
            .limit(limit)
            .offset(offset)
            .execute()
        )
        # Convert filenames to URLs for each story
        stories = []
        for story_data in result.data:
            audio_filename = story_data.get("audio_filename")
            if audio_filename:
                story_data["audio_url"] = self.build_audio_url(audio_filename)
            background_music_filename = story_data.get("background_music_filename")
            if background_music_filename:
                story_data["background_music_url"] = self.build_background_music_url(background_music_filename)
            stories.append(Story(**story_data))
        return stories
    
    async def update_story(self, story_id: str, update_data: Dict[str, Any]) -> Optional[Story]:
        """Update a story."""
        update_data["updated_at"] = datetime.utcnow().isoformat()
        
        result = self.client.table("stories").update(update_data).eq("id", story_id).execute()
        if result.data:
            story_data = result.data[0]
            # Convert audio_filename to audio_url
            audio_filename = story_data.get("audio_filename")
            if audio_filename:
                story_data["audio_url"] = self.build_audio_url(audio_filename)
            # Convert background_music_filename to background_music_url
            background_music_filename = story_data.get("background_music_filename")
            if background_music_filename:
                story_data["background_music_url"] = self.build_background_music_url(background_music_filename)
            return Story(**story_data)
        return None
    
    async def update_story_status(self, story_id: str, status: StoryStatus) -> Optional[Story]:
        """Update story status."""
        return await self.update_story(story_id, {"status": status.value})
    
    # Story Input Operations
    async def create_story_input(self, input_data: Dict[str, Any]) -> Dict[str, Any]:
        """Create a new story input record."""
        input_id = str(uuid.uuid4())
        data = {
            "id": input_id,
            **input_data,
            "created_at": datetime.utcnow().isoformat(),
        }
        
        result = self.client.table("story_inputs").insert(data).execute()
        return result.data[0] if result.data else {}
    
    async def get_story_input(self, story_id: str) -> Optional[Dict[str, Any]]:
        """Get story input data for a story."""
        result = self.client.table("story_inputs").select("*").eq("story_id", story_id).execute()
        return result.data[0] if result.data else None
    
    async def get_story_input_by_type(self, story_id: str, input_type: str) -> Optional[Dict[str, Any]]:
        """Get story input data for a story by input type."""
        result = self.client.table("story_inputs").select("*").eq("story_id", story_id).eq("input_type", input_type).execute()
        return result.data[0] if result.data else None
    
    async def get_pending_stories(self) -> List[Story]:
        """Get all pending stories for parent review."""
        try:
            # Get stories with kids info and story inputs
            result = self.client.table("stories").select("*, kids!inner(name), story_inputs!left(input_value)").eq("status", "pending").order("created_at.desc").execute()
            
            stories = []
            for item in result.data:
                # Handle optional fields properly
                audio_filename = item.get("audio_filename")
                audio_url = self.build_audio_url(audio_filename) if audio_filename else None
                
                # Get caption from story_inputs
                caption = ""
                if item.get("story_inputs") and len(item["story_inputs"]) > 0:
                    caption = item["story_inputs"][0].get("input_value", "")
                
                story = Story(
                    id=item["id"],
                    kid_id=item["kid_id"],
                    child_name=item["kids"]["name"] if item.get("kids") else None,
                    title=item.get("title", ""),
                    content=item.get("content", ""),
                    audio_url=audio_url,
                    status=StoryStatus(item.get("status", "pending")),
                    language=Language(item.get("language", "english")),
                    is_favourite=item.get("is_favourite", False),
                    created_at=datetime.fromisoformat(item["created_at"].replace('Z', '+00:00')),
                    updated_at=datetime.fromisoformat(item["updated_at"].replace('Z', '+00:00')) if item.get("updated_at") else None,
                    image_description=caption,  # Use input_value from story_inputs
                    audio_filename=audio_filename
                )
                stories.append(story)
            
            return stories
        except Exception as e:
            logger.error(f"Error getting pending stories: {e}")
            return []
    
    # Storage Operations
    async def upload_audio(self, file_data: bytes, filename: str) -> str:
        """Upload audio file to Supabase storage."""
        bucket = self.storage_bucket
        
        # Ensure bucket exists
        try:
            self.client.storage.create_bucket(bucket)
        except Exception:
            # Bucket might already exist
            pass
        
        # Upload file
        result = self.client.storage.from_(bucket).upload(
            path=filename,
            file=file_data,
            file_options={"content-type": "audio/mpeg"}
        )
        
        # Return just the filename - API response builder will create full URL
        return filename
    
    def build_audio_url(self, audio_filename: str) -> str:
        """Convert audio filename to full public URL."""
        if not audio_filename:
            return None
        return self.client.storage.from_(self.storage_bucket).get_public_url(audio_filename)
    
    def build_background_music_url(self, music_filename: str) -> str:
        """Convert background music filename to full public URL."""
        if not music_filename:
            return None
        from .background_music_service import background_music_service
        bucket_name = background_music_service.get_bucket_name()
        return self.client.storage.from_(bucket_name).get_public_url(music_filename)
    
    async def delete_audio(self, filename: str) -> bool:
        """Delete audio file from storage."""
        bucket = self.storage_bucket
        result = self.client.storage.from_(bucket).remove([filename])
        return len(result) > 0
    
    # User Settings Operations
    async def get_user_approval_mode(self, user_id: str) -> str:
        """Get user's approval mode from auth metadata."""
        try:
            # Get user from auth
            user = self.client.auth.admin.get_user_by_id(user_id)
            if user and user.user and user.user.user_metadata:
                return user.user.user_metadata.get('approval_mode', 'auto')
            return 'auto'
        except Exception as e:
            logger.error(f"Error getting user approval mode: {e}")
            return 'auto'  # Default fallback
    
    async def get_user_email(self, user_id: str) -> Optional[str]:
        """Get user's email address from auth."""
        try:
            # Get user from auth
            user = self.client.auth.admin.get_user_by_id(user_id)
            if user and user.user:
                return user.user.email
            return None
        except Exception as e:
            logger.error(f"Error getting user email: {e}")
            return None
    
    async def get_user_notification_preferences(self, user_id: str) -> Dict[str, bool]:
        """Get user's notification preferences from auth metadata."""
        try:
            # Get user from auth
            user = self.client.auth.admin.get_user_by_id(user_id)
            if user and user.user and user.user.user_metadata:
                prefs = user.user.user_metadata.get('notification_preferences', {})
                return {
                    'new_story': prefs.get('new_story', True),
                    'email_notifications': prefs.get('email_notifications', True),
                }
            return {'new_story': True, 'email_notifications': True}
        except Exception as e:
            logger.error(f"Error getting user notification preferences: {e}")
            return {'new_story': True, 'email_notifications': True}  # Default fallback

    # Health Check
    async def health_check(self) -> Dict[str, Any]:
        """Check Supabase connection health."""
        try:
            # Try a simple query
            result = self.client.table("kids").select("id").limit(1).execute()
            return {
                "status": "healthy",
                "connected": True,
                "url": self.url
            }
        except Exception as e:
            logger.error(f"Supabase health check failed: {e}")
            return {
                "status": "unhealthy",
                "connected": False,
                "error": str(e)
            }


# Global instance
supabase_service: Optional[SupabaseService] = None


def get_supabase_service() -> SupabaseService:
    """Get or create Supabase service instance."""
    global supabase_service
    if not supabase_service:
        supabase_service = SupabaseService()
    return supabase_service