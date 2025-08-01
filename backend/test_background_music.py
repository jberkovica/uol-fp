#!/usr/bin/env python3
"""Test script to verify background music functionality"""

import asyncio
import os
from src.services.supabase import get_supabase_service
from src.services.background_music_service import background_music_service

async def test_background_music():
    """Test background music assignment and retrieval"""
    
    print("=== Background Music Test ===")
    
    # Test 1: Background Music Service
    print("\n1. Testing Background Music Service:")
    track = background_music_service.get_random_track()
    print(f"   Selected track: {track}")
    print(f"   Bucket name: {background_music_service.get_bucket_name()}")
    print(f"   Total tracks: {len(background_music_service.get_all_tracks())}")
    
    # Test 2: Supabase Service
    print("\n2. Testing Supabase Service:")
    try:
        supabase = get_supabase_service()
        print("   ✓ Supabase service initialized")
        
        # Test URL building
        if track:
            url = supabase.build_background_music_url(track)
            print(f"   ✓ Background music URL: {url}")
        else:
            print("   ✗ No track to build URL for")
            
    except Exception as e:
        print(f"   ✗ Supabase error: {e}")
        return
    
    # Test 3: Story Creation with Background Music
    print("\n3. Testing Story Creation:")
    try:
        story_data = {
            "kid_id": "test-kid-id",
            "title": "Test Story",
            "content": "Test content",
            "language": "en",
            "status": "pending",
            "background_music_filename": track
        }
        
        # This will fail due to foreign key constraints, but we can see the SQL
        story = await supabase.create_story(story_data)
        print(f"   ✓ Story created: {story.id}")
        print(f"   ✓ Background music filename: {story.background_music_filename}")
        print(f"   ✓ Background music URL: {story.background_music_url}")
        
    except Exception as e:
        print(f"   ✗ Story creation failed (expected): {e}")
        
        # Let's try to get an existing story instead
        print("\n4. Testing Existing Story Retrieval:")
        try:
            # Try to get the recent story from logs
            story_id = "8157a3a1-3f98-439e-82bc-37f1726dd7cd"
            story = await supabase.get_story(story_id)
            
            if story:
                print(f"   ✓ Story found: {story.id}")
                print(f"   ✓ Title: {story.title}")
                print(f"   ✓ Background music filename: {getattr(story, 'background_music_filename', 'NOT FOUND')}")
                print(f"   ✓ Background music URL: {getattr(story, 'background_music_url', 'NOT FOUND')}")
                
                # Test manual URL building
                if hasattr(story, 'background_music_filename') and story.background_music_filename:
                    manual_url = supabase.build_background_music_url(story.background_music_filename)
                    print(f"   ✓ Manual URL build: {manual_url}")
                else:
                    print("   ✗ No background_music_filename to build URL from")
                    
            else:
                print(f"   ✗ Story not found: {story_id}")
                
        except Exception as e:
            print(f"   ✗ Story retrieval failed: {e}")

if __name__ == "__main__":
    asyncio.run(test_background_music())