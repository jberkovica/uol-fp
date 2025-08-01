#!/usr/bin/env python3
"""
Script to extract album covers from local audio files and save to Flutter assets.
Extracts from ~/Documents/LuniMuni/music/ and saves to app/assets/audio-covers/
"""

import os
import io
from pathlib import Path
from mutagen.mp3 import MP3
from mutagen.id3 import APIC

def extract_local_album_covers():
    """Extract album covers from local music files and save to Flutter assets."""
    
    # Paths
    music_dir = Path.home() / "Documents" / "LuniMuni" / "music"
    output_dir = Path("/Users/jekaterinaberkovich/Documents/Code/uol-fp-mira/app/assets/audio-covers")
    
    print(f"🎵 Extracting album covers from: {music_dir}")
    print(f"💾 Saving to: {output_dir}")
    
    # Create output directory
    output_dir.mkdir(parents=True, exist_ok=True)
    
    # Check if music directory exists
    if not music_dir.exists():
        print(f"❌ Music directory not found: {music_dir}")
        return
    
    # Get all MP3 files
    mp3_files = list(music_dir.glob("*.mp3"))
    print(f"📁 Found {len(mp3_files)} MP3 files")
    
    extracted_count = 0
    failed_count = 0
    
    for mp3_file in mp3_files:
        try:
            print(f"🔍 Processing: {mp3_file.name}")
            
            # Load MP3 file
            audio_file = MP3(mp3_file)
            
            album_art_data = None
            file_extension = "jpg"  # Default
            
            # Look for album art in ID3 tags
            if audio_file.tags:
                for tag in audio_file.tags.values():
                    if isinstance(tag, APIC):
                        album_art_data = tag.data
                        # Determine file extension from MIME type
                        if tag.mime:
                            if "png" in tag.mime.lower():
                                file_extension = "png"
                            elif "jpeg" in tag.mime.lower() or "jpg" in tag.mime.lower():
                                file_extension = "jpg"
                        break
            
            if not album_art_data:
                print(f"⚠️  No album art found in: {mp3_file.name}")
                failed_count += 1
                continue
            
            # Generate output filename (same as audio file but with image extension)
            cover_filename = mp3_file.stem + f".{file_extension}"
            cover_path = output_dir / cover_filename
            
            # Save album art
            with open(cover_path, 'wb') as f:
                f.write(album_art_data)
            
            print(f"✅ Extracted: {cover_filename} ({len(album_art_data)} bytes)")
            extracted_count += 1
            
        except Exception as e:
            print(f"❌ Failed to process {mp3_file.name}: {e}")
            failed_count += 1
    
    print(f"\n🎯 Album cover extraction complete:")
    print(f"  ✅ Successfully extracted: {extracted_count}")
    print(f"  ❌ Failed: {failed_count}")
    
    if extracted_count > 0:
        print(f"\n📝 Next steps:")
        print(f"1. Add the following to app/pubspec.yaml under assets:")
        print(f"   assets:")
        print(f"     - assets/audio-covers/")
        print(f"2. Update Flutter code to use: 'assets/audio-covers/{{filename}}.jpg'")

if __name__ == "__main__":
    extract_local_album_covers()