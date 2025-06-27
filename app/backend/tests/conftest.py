"""
Pytest configuration and shared fixtures for Mira Storyteller tests
"""

import pytest
import os
import sys
from unittest.mock import Mock

# Add the backend directory to Python path for imports
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

@pytest.fixture
def mock_api_keys(monkeypatch):
    """Mock API keys for testing without real credentials"""
    monkeypatch.setenv("GOOGLE_API_KEY", "mock_google_key")
    monkeypatch.setenv("MISTRAL_API_KEY", "mock_mistral_key") 
    monkeypatch.setenv("ELEVENLABS_API_KEY", "mock_elevenlabs_key")

@pytest.fixture
def sample_base64_image():
    """Valid small PNG image as base64 for testing"""
    # 32x32 red square PNG
    return "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVQYGWNsYPhfDwABhgHBCwKB3gAAAABJRU5ErkJggg=="

@pytest.fixture
def valid_story_request(sample_base64_image):
    """Valid story request for testing"""
    return {
        "child_name": "Emma",
        "image_data": sample_base64_image,
        "mime_type": "image/png",
        "preferences": {"style": "bedtime", "age_group": "4-6"}
    }

@pytest.fixture
def invalid_story_request():
    """Invalid story request for testing validation"""
    return {
        "child_name": "<script>alert('xss')</script>",
        "image_data": "invalid_base64",
        "mime_type": "image/jpeg"
    }

@pytest.fixture
def mock_ai_responses():
    """Mock responses from AI services"""
    return {
        "image_analysis": {
            "caption": "A colorful drawing with a house and tree",
            "success": True,
            "model": "gemini-2.0-flash"
        },
        "story_generation": {
            "title": "The Magic House",
            "content": "Once upon a time, there was a magical house...",
            "success": True,
            "model": "mistral-medium-latest"
        },
        "tts_audio": "mock_audio_path.mp3"
    }

@pytest.fixture
def mock_requests(monkeypatch):
    """Mock HTTP requests to external APIs"""
    import requests
    
    mock_response = Mock()
    mock_response.status_code = 200
    mock_response.json.return_value = {"mock": "response"}
    
    monkeypatch.setattr(requests, "post", Mock(return_value=mock_response))
    monkeypatch.setattr(requests, "get", Mock(return_value=mock_response))
    
    return mock_response