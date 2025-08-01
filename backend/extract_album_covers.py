#!/usr/bin/env python3
"""
Script to pre-extract all album covers from background music files and upload to Supabase.
Run this once to cache all album art for fast loading.
"""

import io
import os
import asyncio
import requests
from pathlib import Path
from dotenv import load_dotenv
from mutagen.mp3 import MP3
from mutagen.id3 import APIC
from supabase import create_client, Client

from src.services.supabase import SupabaseService
from src.services.background_music_service import BackgroundMusicService
from src.utils.logger import get_logger

# Load environment variables
load_dotenv()

logger = get_logger(__name__)

async def extract_and_upload_album_covers():
    """Extract album covers from all background music files and upload to Supabase."""
    
    # Initialize services
    supabase_service = SupabaseService()
    background_music_service = BackgroundMusicService()
    
    # Get all tracks
    tracks = background_music_service.get_all_tracks()
    bucket_name = background_music_service.get_bucket_name()
    covers_bucket = "album-covers"  # New bucket for covers
    
    logger.info(f"Extracting album covers for {len(tracks)} tracks")
    
    # Create covers bucket if it doesn't exist
    try:
        supabase_service.client.storage.create_bucket(covers_bucket, {"public": True})
        logger.info(f"Created bucket: {covers_bucket}")
    except Exception as e:
        logger.info(f"Bucket {covers_bucket} already exists or creation failed: {e}")
    
    extracted_count = 0
    failed_count = 0
    
    for filename in tracks:
        try:
            logger.info(f"Processing: {filename}")
            
            # Get the audio file URL from Supabase
            audio_url = supabase_service.client.storage.from_(bucket_name).get_public_url(filename)
            
            # Download the audio file
            response = requests.get(audio_url)
            if response.status_code != 200:
                logger.error(f"Failed to download {filename}: HTTP {response.status_code}")
                failed_count += 1
                continue
            
            # Extract album art
            audio_data = io.BytesIO(response.content)
            audio_file = MP3(audio_data)
            
            album_art_data = None
            mime_type = "image/jpeg"
            
            # Look for album art in ID3 tags
            if audio_file.tags:
                for tag in audio_file.tags.values():
                    if isinstance(tag, APIC):
                        album_art_data = tag.data
                        if tag.mime:
                            mime_type = tag.mime
                        break
            
            if not album_art_data:
                logger.warning(f"No album art found in {filename}")
                failed_count += 1
                continue
            
            # Generate cover filename
            cover_filename = f"{filename.replace('.mp3', '.jpg')}"
            
            # Upload to Supabase storage
            supabase_service.client.storage.from_(covers_bucket).upload(
                cover_filename,
                album_art_data,
                {
                    "content-type": mime_type,
                    "cache-control": "3600"  # Cache for 1 hour
                }
            )
            
            logger.info(f"✅ Extracted and uploaded: {cover_filename}")
            extracted_count += 1
            
        except Exception as e:
            logger.error(f"Failed to process {filename}: {e}")
            failed_count += 1
    
    logger.info(f"Album cover extraction complete:")
    logger.info(f"  ✅ Successfully extracted: {extracted_count}")
    logger.info(f"  ❌ Failed: {failed_count}")

if __name__ == "__main__":
    asyncio.run(extract_and_upload_album_covers())