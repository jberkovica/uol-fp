import json
import random
import os
from pathlib import Path
from typing import List, Optional
from ..utils.logger import get_logger

logger = get_logger(__name__)

class BackgroundMusicService:
    """Service for managing background music track selection"""
    
    def __init__(self):
        self._tracks: Optional[List[str]] = None
        self._bucket_name: Optional[str] = None
        self._config_loaded = False
    
    def _load_config(self) -> None:
        """Load background music configuration from JSON file"""
        if self._config_loaded:
            return
            
        try:
            # Get the config file path relative to this service file
            config_path = Path(__file__).parent.parent / "config" / "background_music.json"
            
            with open(config_path, 'r', encoding='utf-8') as f:
                config = json.load(f)
            
            self._tracks = config.get("background_music_tracks", [])
            self._bucket_name = config.get("bucket_name", "background-music")
            self._config_loaded = True
            
            logger.info(f"Loaded {len(self._tracks)} background music tracks from config")
            
        except FileNotFoundError:
            logger.error(f"Background music config file not found at {config_path}")
            self._tracks = []
            self._bucket_name = "background-music"
            self._config_loaded = True
            
        except json.JSONDecodeError as e:
            logger.error(f"Error parsing background music config JSON: {e}")
            self._tracks = []
            self._bucket_name = "background-music"
            self._config_loaded = True
            
        except Exception as e:
            logger.error(f"Unexpected error loading background music config: {e}")
            self._tracks = []
            self._bucket_name = "background-music"
            self._config_loaded = True
    
    def get_random_track(self) -> Optional[str]:
        """
        Select a random background music track
        
        Returns:
            Optional[str]: Random track filename, or None if no tracks available
        """
        self._load_config()
        
        if not self._tracks:
            logger.warning("No background music tracks available")
            return None
        
        selected_track = random.choice(self._tracks)
        logger.debug(f"Selected random background music track: {selected_track}")
        return selected_track
    
    def get_all_tracks(self) -> List[str]:
        """
        Get all available background music tracks
        
        Returns:
            List[str]: List of all track filenames
        """
        self._load_config()
        return self._tracks.copy() if self._tracks else []
    
    def get_bucket_name(self) -> str:
        """
        Get the Supabase bucket name for background music
        
        Returns:
            str: The bucket name
        """
        self._load_config()
        return self._bucket_name or "background-music"
    
    def track_exists(self, track_filename: str) -> bool:
        """
        Check if a track exists in the configuration
        
        Args:
            track_filename (str): The track filename to check
            
        Returns:
            bool: True if track exists, False otherwise
        """
        self._load_config()
        return track_filename in (self._tracks or [])

# Global instance
background_music_service = BackgroundMusicService()