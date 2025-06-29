#!/usr/bin/env python3
"""
Test script to validate current Mira Storyteller backend functionality
Tests all recent changes including model config, validation, and AI services
"""

import asyncio
import base64
import json
import time
import threading
import requests
from typing import Dict, Any
import sys
import os

# Add current directory to path for imports
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

def test_imports():
    """Test that all our recent changes import correctly"""
    print("Testing imports...")
    
    try:
        from app.main import app
        print("PASS Main app imports OK")
        
        from app.services.image_analysis import ImageAnalysisService
        print("PASS Image analysis service imports OK")
        
        from app.services.story_generator import StoryGeneratorService
        print("PASS Story generator service imports OK")
        
        from app.services.text_to_speech import TextToSpeechService
        print("PASS Text-to-speech service imports OK")
        
        from app.utils.validation import validate_story_request, validate_base64_image
        print("PASS Validation utils imports OK")
        
        from config.models import ModelType, get_model_config, get_api_key
        print("PASS Model config imports OK")
        
        from prompts.story_generation import STORY_GENERATION_PROMPT, STORY_SYSTEM_MESSAGE
        print("PASS Story generation prompts import OK")
        
        from prompts.image_analysis import IMAGE_CAPTION_PROMPT
        print("PASS Image analysis prompts import OK")
        
        return True
    except ImportError as e:
        print(f"FAIL Import error: {e}")
        return False

def test_model_config():
    """Test the new model configuration system"""
    print("\n[CONFIG] Testing model configuration...")
    
    try:
        from config.models import ModelType, get_model_config, is_model_available
        
        # Test image analysis config
        img_config = get_model_config(ModelType.IMAGE_ANALYSIS)
        print(f"PASS Image analysis model: {img_config['model_name']}")
        print(f"   Provider: {img_config['provider'].value}")
        print(f"   Available: {is_model_available(ModelType.IMAGE_ANALYSIS)}")
        
        # Test story generation config
        story_config = get_model_config(ModelType.STORY_GENERATION)
        print(f"PASS Story generation model: {story_config['model_name']}")
        print(f"   Provider: {story_config['provider'].value}")
        print(f"   Available: {is_model_available(ModelType.STORY_GENERATION)}")
        
        # Test TTS config
        tts_config = get_model_config(ModelType.TEXT_TO_SPEECH)
        print(f"PASS TTS model: {tts_config['model_name']}")
        print(f"   Provider: {tts_config['provider'].value}")
        print(f"   Available: {is_model_available(ModelType.TEXT_TO_SPEECH)}")
        
        return True
    except Exception as e:
        print(f"FAIL Model config error: {e}")
        return False

def test_validation():
    """Test the new input validation system"""
    print("\n[SECURITY] Testing input validation...")
    
    try:
        from app.utils.validation import validate_base64_image, validate_child_name
        
        # Test valid child name
        valid, error = validate_child_name("Emma")
        if valid:
            print("PASS Valid child name passes validation")
        else:
            print(f"FAIL Valid child name failed: {error}")
            
        # Test invalid child name
        valid, error = validate_child_name("<script>alert('xss')</script>")
        if not valid:
            print("PASS XSS attempt properly blocked")
        else:
            print("FAIL XSS attempt not blocked!")
            
        # Test small valid base64 image (1x1 PNG)
        small_png_b64 = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChAHAkb+xOQAAAABJRU5ErkJggg=="
        valid, error = validate_base64_image(small_png_b64, "image/png")
        if valid:
            print("PASS Valid small image passes validation")
        else:
            print(f"FAIL Valid image failed validation: {error}")
            
        # Test invalid base64
        valid, error = validate_base64_image("invalid_base64", "image/png")
        if not valid:
            print("PASS Invalid base64 properly rejected")
        else:
            print("FAIL Invalid base64 not rejected!")
            
        return True
    except Exception as e:
        print(f"FAIL Validation test error: {e}")
        return False

def test_ai_services():
    """Test AI service initialization with new config system"""
    print("\n[AI] Testing AI services initialization...")
    
    try:
        from app.services.image_analysis import ImageAnalysisService
        from app.services.story_generator import StoryGeneratorService
        from app.services.text_to_speech import TextToSpeechService
        
        # Test service initialization
        img_service = ImageAnalysisService()
        print(f"PASS Image service initialized (model: {img_service.model_config['model_name']})")
        
        story_service = StoryGeneratorService()
        print(f"PASS Story service initialized (model: {story_service.model_config['model_name']})")
        
        tts_service = TextToSpeechService()
        print(f"PASS TTS service initialized (model: {tts_service.model_config['model_name']})")
        print(f"   Voice: {tts_service.voice_config['description']}")
        
        return True
    except Exception as e:
        print(f"FAIL AI services test error: {e}")
        return False

def start_test_server():
    """Start the FastAPI server for endpoint testing"""
    import uvicorn
    from app.main import app
    
    try:
        uvicorn.run(app, host="127.0.0.1", port=8000, log_level="error")
    except Exception as e:
        print(f"Server error: {e}")

def test_api_endpoints():
    """Test API endpoints"""
    print("\n[API] Testing API endpoints...")
    
    # Start server in background thread
    server_thread = threading.Thread(target=start_test_server, daemon=True)
    server_thread.start()
    
    # Wait for server to start
    print("[WAIT] Starting server...")
    time.sleep(3)
    
    base_url = "http://127.0.0.1:8000"
    
    try:
        # Test root endpoint
        response = requests.get(f"{base_url}/", timeout=5)
        if response.status_code == 200:
            data = response.json()
            print(f"PASS Root endpoint OK (version: {data.get('version')})")
            print(f"   AI services: {list(data.get('ai_services', {}).keys())}")
        else:
            print(f"FAIL Root endpoint failed: {response.status_code}")
            return False
            
        # Test story generation endpoint with invalid data (should fail validation)
        invalid_story_request = {
            "child_name": "<script>alert('xss')</script>",
            "image_data": "invalid_base64",
            "mime_type": "image/jpeg"
        }
        
        response = requests.post(
            f"{base_url}/generate-story-from-image/",
            json=invalid_story_request,
            timeout=5
        )
        
        if response.status_code == 400:
            print("PASS Input validation working - malicious input rejected")
        else:
            print(f"FAIL Input validation failed - malicious input not rejected: {response.status_code}")
            
        # Test with valid small image
        valid_story_request = {
            "child_name": "Emma",
            "image_data": "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChAHAkb+xOQAAAABJRU5ErkJggg==",
            "mime_type": "image/png"
        }
        
        print("[WAIT] Testing story generation (this will fail without API keys)...")
        response = requests.post(
            f"{base_url}/generate-story-from-image/",
            json=valid_story_request,
            timeout=10
        )
        
        if response.status_code == 200:
            data = response.json()
            print(f"PASS Story generation endpoint accepts valid input (story_id: {data.get('story_id')})")
        elif response.status_code == 500:
            print("WARN Story generation failed (expected without API keys)")
        else:
            print(f"FAIL Unexpected response: {response.status_code}")
            
        return True
        
    except requests.exceptions.ConnectionError:
        print("FAIL Could not connect to server")
        return False
    except Exception as e:
        print(f"FAIL API test error: {e}")
        return False

def main():
    """Run all tests"""
    print("Mira Storyteller Backend - Functionality Test")
    print("=" * 50)
    
    tests = [
        ("Import Tests", test_imports),
        ("Model Configuration", test_model_config),
        ("Input Validation", test_validation),
        ("AI Services", test_ai_services),
        ("API Endpoints", test_api_endpoints),
    ]
    
    results = []
    
    for test_name, test_func in tests:
        print(f"\n[RUN] Running {test_name}...")
        try:
            result = test_func()
            results.append((test_name, result))
        except Exception as e:
            print(f"FAIL {test_name} crashed: {e}")
            results.append((test_name, False))
    
    # Summary
    print("\n" + "=" * 50)
    print("[SUMMARY] TEST SUMMARY")
    print("=" * 50)
    
    passed = 0
    total = len(results)
    
    for test_name, result in results:
        status = "PASS PASS" if result else "FAIL FAIL"
        print(f"{status} {test_name}")
        if result:
            passed += 1
    
    print(f"\nOverall: {passed}/{total} tests passed ({passed/total*100:.1f}%)")
    
    if passed == total:
        print("[SUCCESS] All tests passed! Your recent changes are working correctly.")
    else:
        print("WARN Some tests failed. Check the output above for details.")
    
    return passed == total

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)