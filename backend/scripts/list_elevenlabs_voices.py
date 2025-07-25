#!/usr/bin/env python3
"""List all ElevenLabs voices to find Russian voices."""
import os
import httpx
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

ELEVENLABS_API_KEY = os.getenv("ELEVENLABS_API_KEY")

if not ELEVENLABS_API_KEY:
    print("Error: ELEVENLABS_API_KEY not found in environment variables")
    exit(1)

async def list_voices():
    """List all available ElevenLabs voices."""
    headers = {
        "Accept": "application/json",
        "xi-api-key": ELEVENLABS_API_KEY
    }
    
    async with httpx.AsyncClient() as client:
        # Try to get more voices with different parameters
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
        
        # Also try the voice library endpoint
        print("=== Checking Voice Library ===\n")
        try:
            lib_response = await client.get(
                "https://api.elevenlabs.io/v1/shared-voices",
                headers=headers,
                params={
                    "page_size": 100,
                    "category": "professional",
                    "language": "ru"
                }
            )
            if lib_response.status_code == 200:
                lib_data = lib_response.json()
                print(f"Found {len(lib_data.get('voices', []))} voices in library\n")
        except:
            print("Could not access voice library\n")
        
    print("=== All Available ElevenLabs Voices ===\n")
    
    # Look for Russian voices
    russian_voices = []
    all_voices = []
    
    for voice in data.get("voices", []):
        voice_info = {
            "name": voice.get("name"),
            "voice_id": voice.get("voice_id"),
            "category": voice.get("category"),
            "description": voice.get("description", ""),
            "labels": voice.get("labels", {})
        }
        all_voices.append(voice_info)
        
        # Check if it's a Russian voice
        name_lower = voice_info["name"].lower()
        desc_lower = (voice_info["description"] or "").lower()
        
        if any(term in desc_lower for term in ["russian", "russia", "rus "]) or \
           any(name in name_lower for name in ["viktoriia", "anna", "kate", "igor", "ivan", "alexandr", "veronica", "max"]):
            russian_voices.append(voice_info)
    
    # Print Russian voices first
    print("=== Russian/Russian-speaking Voices ===\n")
    for voice in russian_voices:
        print(f"Name: {voice['name']}")
        print(f"Voice ID: {voice['voice_id']}")
        print(f"Category: {voice['category']}")
        if voice['description']:
            print(f"Description: {voice['description']}")
        print("-" * 50)
    
    print(f"\nTotal Russian voices found: {len(russian_voices)}")
    print(f"Total voices available: {len(all_voices)}")
    
    # Print all available voices with categories
    print("\n=== All Available Voices by Category ===\n")
    categories = {}
    for voice in all_voices:
        cat = voice['category'] or 'uncategorized'
        if cat not in categories:
            categories[cat] = []
        categories[cat].append(voice)
    
    for category, voices in categories.items():
        print(f"\n--- {category.upper()} ({len(voices)} voices) ---")
        for voice in voices:
            print(f"Name: {voice['name']}, ID: {voice['voice_id']}")
            if voice['description']:
                print(f"  Description: {voice['description'][:100]}...")
            # Check for language info in labels
            if voice['labels']:
                print(f"  Labels: {voice['labels']}")
    
    # Also print female voices that might work well for Russian
    print("\n=== Female Voices (might work for Russian stories) ===\n")
    for voice in all_voices:
        if voice['category'] == 'premade':
            desc_lower = (voice['description'] or '').lower()
            name_lower = voice['name'].lower()
            if any(term in desc_lower for term in ['female', 'woman', 'girl', 'she', 'her']) or \
               any(name in name_lower for name in ['rachel', 'charlotte', 'bella', 'domi', 'matilda', 'dorothy', 'emily']):
                print(f"Name: {voice['name']}")
                print(f"Voice ID: {voice['voice_id']}")
                print(f"Description: {voice['description']}")
                print("-" * 30)

if __name__ == "__main__":
    import asyncio
    asyncio.run(list_voices())