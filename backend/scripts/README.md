# Backend Utility Scripts

This directory contains utility scripts for managing and debugging the Mira Storyteller backend.

## Available Scripts

### list_elevenlabs_voices.py
Lists all available ElevenLabs voices with their IDs and metadata.

**Usage:**
```bash
cd backend
python scripts/list_elevenlabs_voices.py
```

**Features:**
- Shows all available voices grouped by category (premade, professional, etc.)
- Identifies Russian-speaking voices
- Displays voice IDs, descriptions, and language support
- Helps find the right voice for different languages

**Requirements:**
- ELEVENLABS_API_KEY must be set in .env file
- Python packages: httpx, python-dotenv

**Output:**
- Russian/Russian-speaking voices (if any)
- All voices grouped by category with metadata
- Popular female voices suitable for stories

This script is particularly useful when:
- Setting up new language configurations
- Finding native speakers for specific languages
- Debugging voice-related issues
- Exploring available voice options for different use cases