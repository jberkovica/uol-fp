"""
Supabase Storage service for handling file uploads
Replaces local file storage with cloud storage
"""

import os
import logging
from pathlib import Path
from typing import Optional
from supabase import create_client, Client

logger = logging.getLogger(__name__)


class SupabaseStorageService:
    """Service for uploading and managing files in Supabase Storage"""
    
    def __init__(self):
        # Initialize Supabase client with service role key for server-side operations
        supabase_url = os.getenv('SUPABASE_URL')
        supabase_service_key = os.getenv('SUPABASE_SERVICE_KEY')
        
        if not supabase_url or not supabase_service_key:
            raise ValueError("Missing Supabase credentials in environment variables")
        
        self.client: Client = create_client(supabase_url, supabase_service_key)
        self.bucket_name = "audio-files"  # Bucket for audio files
        
        # Ensure bucket exists (only for development)
        self._ensure_bucket_exists()
    
    def _ensure_bucket_exists(self):
        """Create bucket if it doesn't exist (development only)"""
        try:
            # Check if bucket exists by trying to list files
            self.client.storage.from_(self.bucket_name).list()
            logger.info(f"Bucket '{self.bucket_name}' already exists")
        except Exception as e:
            if "Bucket not found" in str(e):
                try:
                    # Create bucket
                    self.client.storage.create_bucket(
                        self.bucket_name,
                        options={"public": False}  # Private bucket for security
                    )
                    logger.info(f"Created bucket '{self.bucket_name}'")
                except Exception as create_error:
                    logger.warning(f"Could not create bucket: {create_error}")
            else:
                logger.warning(f"Error checking bucket: {e}")
    
    def upload_audio_file(self, story_id: str, audio_file_path: Path) -> Optional[str]:
        """
        Upload audio file to Supabase Storage
        
        Args:
            story_id: Unique story identifier
            audio_file_path: Path to the local audio file
            
        Returns:
            Public URL of uploaded file or None if failed
        """
        try:
            if not audio_file_path.exists():
                logger.error(f"Audio file not found: {audio_file_path}")
                return None
            
            # Read file content
            with open(audio_file_path, 'rb') as f:
                file_content = f.read()
            
            # Upload to Supabase Storage
            file_path = f"stories/{story_id}.mp3"
            
            result = self.client.storage.from_(self.bucket_name).upload(
                path=file_path,
                file=file_content,
                file_options={"upsert": "true"}  # Overwrite if exists
            )
            
            if result:
                # Get public URL for direct access
                public_url = self.client.storage.from_(self.bucket_name).get_public_url(file_path)
                logger.info(f"Successfully uploaded audio for story {story_id}")
                return public_url
            else:
                logger.error(f"Failed to upload audio for story {story_id}")
                return None
                
        except Exception as e:
            logger.error(f"Error uploading audio file for story {story_id}: {e}")
            return None
    
    def delete_audio_file(self, story_id: str) -> bool:
        """
        Delete audio file from Supabase Storage
        
        Args:
            story_id: Unique story identifier
            
        Returns:
            True if deleted successfully, False otherwise
        """
        try:
            file_path = f"stories/{story_id}.mp3"
            
            result = self.client.storage.from_(self.bucket_name).remove([file_path])
            
            if result:
                logger.info(f"Successfully deleted audio for story {story_id}")
                return True
            else:
                logger.error(f"Failed to delete audio for story {story_id}")
                return False
                
        except Exception as e:
            logger.error(f"Error deleting audio file for story {story_id}: {e}")
            return False
    
    def generate_signed_audio_url(self, file_path: str, expires_in: int = 3600) -> Optional[str]:
        """
        Generate a fresh signed URL for audio file access
        
        Args:
            file_path: Path to the file in storage
            expires_in: URL expiration time in seconds (default 1 hour)
            
        Returns:
            Signed URL or None if failed
        """
        try:
            signed_url = self.client.storage.from_(self.bucket_name).create_signed_url(
                file_path, 
                expires_in=expires_in
            )
            return signed_url.get('signedURL')
                
        except Exception as e:
            logger.error(f"Error generating signed URL for {file_path}: {e}")
            return None


# Global instance
storage_service = SupabaseStorageService()