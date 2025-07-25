"""Supabase service for database and storage operations."""
import os
from typing import List, Optional, Dict, Any
from datetime import datetime
import uuid
from supabase import create_client, Client
from ..types.domain import Kid, Story, StoryStatus
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
            "avatar_type": request.avatar_type,
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
            return Story(**result.data[0])
        return None
    
    async def get_stories_for_kid(self, kid_id: str, limit: int = 20, offset: int = 0) -> List[Story]:
        """Get all stories for a kid."""
        result = (
            self.client.table("stories")
            .select("*")
            .eq("kid_id", kid_id)
            .order("created_at", desc=True)
            .limit(limit)
            .offset(offset)
            .execute()
        )
        return [Story(**story) for story in result.data]
    
    async def update_story(self, story_id: str, update_data: Dict[str, Any]) -> Optional[Story]:
        """Update a story."""
        update_data["updated_at"] = datetime.utcnow().isoformat()
        
        result = self.client.table("stories").update(update_data).eq("id", story_id).execute()
        if result.data:
            return Story(**result.data[0])
        return None
    
    async def update_story_status(self, story_id: str, status: StoryStatus) -> Optional[Story]:
        """Update story status."""
        return await self.update_story(story_id, {"status": status.value})
    
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
        
        # Get public URL
        public_url = self.client.storage.from_(bucket).get_public_url(filename)
        return public_url
    
    async def delete_audio(self, filename: str) -> bool:
        """Delete audio file from storage."""
        bucket = self.storage_bucket
        result = self.client.storage.from_(bucket).remove([filename])
        return len(result) > 0
    
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