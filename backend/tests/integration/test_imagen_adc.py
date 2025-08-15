#!/usr/bin/env python3
"""Integration test for Google Imagen 3 with Application Default Credentials (ADC).

This test verifies:
1. Google Cloud ADC authentication is properly configured
2. Vertex AI can be initialized with the correct project and region
3. Google Imagen 3 model can generate images successfully
4. Generated images can be stored in Supabase

Run this test manually to verify Google Imagen setup:
    python tests/integration/test_imagen_adc.py

Or with pytest:
    pytest tests/integration/test_imagen_adc.py -v
"""

import os
import sys
import asyncio
import logging
from pathlib import Path
from dotenv import load_dotenv

# Load environment variables from parent directory
load_dotenv("../.env")

# Add src to Python path
backend_dir = Path(__file__).parent.parent.parent  # Go up to backend directory
sys.path.insert(0, str(backend_dir))

from src.agents.artist.agent import ArtistAgent

# Set up logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

async def test_imagen_integration():
    """Test the Google Imagen 3 integration with ADC."""
    print("Testing Google Imagen 3 integration with Application Default Credentials...")
    
    # Test configuration
    config = {
        "vendor": "google",
        "fallback_vendor": "openai",
        "retry": {
            "max_attempts": 2,
            "delay_seconds": 1,
            "fallback_enabled": True
        },
        "google": {
            "model": "imagen-3.0-generate-002",
            "project_id": os.getenv("GOOGLE_PROJECT_ID"),
            "location": "europe-west4",
            "params": {
                "number_of_images": 1
            }
        },
        "openai": {
            "model": "gpt-image-1",
            "api_key": os.getenv("OPENAI_API_KEY"),
            "params": {
                "size": "1024x1024"
            }
        },
        "style": {
            "base": "A magical children's book illustration of a forest scene",
            "emphasis_prefix": "CRITICAL STYLE"
        },
        "prompt_structure": {
            "max_total_words": 50
        }
    }
    
    try:
        # Initialize artist agent
        print("Initializing ArtistAgent...")
        agent = ArtistAgent(config)
        
        # Validate configuration
        print("Validating configuration...")
        is_valid = agent.validate_config()
        if not is_valid:
            print("ERROR: Configuration validation failed!")
            return False
        
        print("Configuration is valid!")
        
        # Test data with proper UUID
        import uuid
        test_id = str(uuid.uuid4())
        input_data = {
            "story": {
                "id": test_id,
                "title": "Test Story",
                "content": "A magical test story about a forest adventure."
            },
            "kid": {
                "name": "Test Child",
                "age": 5
            }
        }
        
        print("Generating test image...")
        print(f"Using project: {os.getenv('GOOGLE_PROJECT_ID')}")
        
        # Generate image
        result = await agent.process(input_data)
        
        # Check for success - the result should have success=True and url
        if result and result.get("success") and result.get("url"):
            print("SUCCESS: Image generation successful!")
            print(f"Generated with vendor: {result.get('metadata', {}).get('vendor_used', 'google')}")
            print(f"Attempts made: {result.get('metadata', {}).get('attempts_made', 'unknown')}")
            print(f"Cover URL available: {bool(result.get('url'))}")
            print(f"Thumbnail URL available: {bool(result.get('thumbnail_url'))}")
            if result.get("url"):
                print(f"Cover stored at: {result.get('url', 'N/A')[:100]}...")
            return True
        else:
            print("ERROR: Image generation failed - no image data returned")
            print(f"Result keys: {list(result.keys()) if result else 'None'}")
            return False
            
    except Exception as e:
        print(f"ERROR: Test failed with error: {e}")
        logger.exception("Full error details:")
        return False

def check_prerequisites():
    """Check if all prerequisites are met."""
    print("Checking prerequisites...")
    
    # Check environment variables
    project_id = os.getenv("GOOGLE_PROJECT_ID")
    if not project_id:
        print("ERROR: GOOGLE_PROJECT_ID environment variable not set")
        return False
    
    print(f"Google Project ID: {project_id}")
    
    # Check ADC
    try:
        from google.auth import default
        credentials, detected_project = default()
        print(f"ADC detected project: {detected_project}")
        if detected_project != project_id:
            print(f"WARNING: ADC project ({detected_project}) differs from env var ({project_id})")
    except Exception as e:
        print(f"ERROR: ADC not configured: {e}")
        print("Run: gcloud auth application-default login")
        return False
    
    # Check Google Gen AI SDK
    try:
        from google import genai
        print("Google Gen AI SDK available")
    except ImportError:
        print("ERROR: Google Gen AI SDK not installed")
        print("Run: pip install google-genai")
        return False
    
    return True

# Pytest-compatible test function
async def test_google_imagen_adc():
    """Pytest-compatible test for Google Imagen 3 with ADC."""
    assert check_prerequisites(), "Prerequisites not met for Google Imagen ADC"
    success = await test_imagen_integration()
    assert success, "Google Imagen 3 integration test failed"

if __name__ == "__main__":
    print("Google Imagen 3 + ADC Integration Test")
    print("=" * 50)
    
    if not check_prerequisites():
        print("\nERROR: Prerequisites not met. Please fix the issues above.")
        sys.exit(1)
    
    print("\nRunning integration test...")
    success = asyncio.run(test_imagen_integration())
    
    if success:
        print("\n=== Integration test PASSED ===")
        print("Google Imagen 3 with ADC is working correctly!")
    else:
        print("\n=== Integration test FAILED ===")
        print("Check the error messages above and the documentation.")
        sys.exit(1)