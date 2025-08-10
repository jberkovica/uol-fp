#!/usr/bin/env python3
"""List ElevenLabs voices with optional language filtering."""
import os
import sys
import argparse
import asyncio
import httpx
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

ELEVENLABS_API_KEY = os.getenv("ELEVENLABS_API_KEY")

if not ELEVENLABS_API_KEY:
    print("Error: ELEVENLABS_API_KEY not found in environment variables")
    exit(1)

async def list_voices(languages=None, search_terms=None, children_only=False):
    """List available ElevenLabs voices with filtering options."""
    headers = {
        "Accept": "application/json",
        "xi-api-key": ELEVENLABS_API_KEY
    }
    
    async with httpx.AsyncClient() as client:
        # Get all available voices first
        response = await client.get(
            "https://api.elevenlabs.io/v1/voices",
            headers=headers,
            params={
                "show_legacy": "true",
                "include_search_metadata": "true"
            }
        )
        response.raise_for_status()
        data = response.json()
        
        print("=== ElevenLabs Voice Discovery Tool ===\n")
        
        # Search voice library for specified languages
        if languages:
            for lang_code in languages:
                print(f"=== {lang_code.upper()} VOICES FROM LIBRARY ===\n")
                try:
                    lib_response = await client.get(
                        "https://api.elevenlabs.io/v1/shared-voices",
                        headers=headers,
                        params={
                            "page_size": 100,
                            "language": lang_code
                        }
                    )
                    if lib_response.status_code == 200:
                        lib_data = lib_response.json()
                        voices = lib_data.get('voices', [])
                        
                        if children_only:
                            # Filter voices suitable for children's stories
                            story_voices = []
                            for voice in voices:
                                desc = voice.get('description', '').lower()
                                if any(term in desc for term in ['children', 'story', 'narrat', 'bedtime', 'fairy', 'tale', 'kid']):
                                    story_voices.append(voice)
                            
                            print(f"Found {len(story_voices)} children-suitable voices out of {len(voices)} total\n")
                            voices = story_voices
                        else:
                            print(f"Found {len(voices)} total voices\n")
                        
                        for voice in voices:
                            print(f"Name: {voice.get('name')}")
                            print(f"Voice ID: {voice.get('voice_id')}")
                            print(f"Category: {voice.get('category')}")
                            desc = voice.get('description', 'No description')
                            print(f"Description: {desc[:150]}{'...' if len(desc) > 150 else ''}")
                            print("-" * 60)
                        print()
                        
                except Exception as e:
                    print(f"Could not access voice library for {lang_code}: {e}\n")
        
        # Search by terms if provided
        if search_terms:
            for term in search_terms:
                print(f"=== SEARCH RESULTS FOR '{term}' ===\n")
                try:
                    search_response = await client.get(
                        "https://api.elevenlabs.io/v1/shared-voices",
                        headers=headers,
                        params={
                            "page_size": 50,
                            "search": term
                        }
                    )
                    if search_response.status_code == 200:
                        search_data = search_response.json()
                        search_voices = search_data.get('voices', [])
                        print(f"Found {len(search_voices)} voices matching '{term}'\n")
                        for voice in search_voices:
                            print(f"Name: {voice.get('name')}")
                            print(f"Voice ID: {voice.get('voice_id')}")
                            desc = voice.get('description', 'No description')
                            print(f"Description: {desc[:100]}{'...' if len(desc) > 100 else ''}")
                            print("-" * 40)
                        print()
                except Exception as e:
                    print(f"Could not search for '{term}': {e}\n")
        
        # Show premade voices if no specific language requested
        if not languages and not search_terms:
            print("=== PREMADE VOICES ===\n")
            premade_voices = []
            
            for voice in data.get("voices", []):
                if voice.get("category") == "premade":
                    premade_voices.append(voice)
            
            print(f"Found {len(premade_voices)} premade voices\n")
            for voice in premade_voices:
                print(f"Name: {voice.get('name')}")
                print(f"Voice ID: {voice.get('voice_id')}")
                labels = voice.get('labels', {})
                if labels:
                    print(f"Labels: {labels}")
                desc = voice.get('description', '')
                if desc:
                    print(f"Description: {desc[:100]}{'...' if len(desc) > 100 else ''}")
                print("-" * 40)

def main():
    parser = argparse.ArgumentParser(description='List ElevenLabs voices with filtering options')
    parser.add_argument('--languages', '-l', nargs='+', help='Language codes to search for (e.g., ru es fr)')
    parser.add_argument('--search', '-s', nargs='+', help='Search terms to look for')
    parser.add_argument('--children-only', '-c', action='store_true', help='Show only voices suitable for children')
    
    args = parser.parse_args()
    
    if not args.languages and not args.search:
        print("Usage examples:")
        print("  python list_elevenlabs_voices.py --languages ru es fr")
        print("  python list_elevenlabs_voices.py --search storyteller narrator")
        print("  python list_elevenlabs_voices.py --languages es --children-only")
        print("  python list_elevenlabs_voices.py  # Show all premade voices")
        print()
    
    asyncio.run(list_voices(
        languages=args.languages,
        search_terms=args.search,
        children_only=args.children_only
    ))

if __name__ == "__main__":
    main()