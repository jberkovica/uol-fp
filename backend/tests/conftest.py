"""Pytest configuration and fixtures for all tests."""
import pytest
import asyncio
import os
import sys
from pathlib import Path
from unittest.mock import Mock, AsyncMock
from typing import Dict, Any

# Add src to path for imports
sys.path.insert(0, str(Path(__file__).parent.parent / "src"))

from src.api.app import create_app, load_config
from src.services.supabase import SupabaseService
from src.agents.vision.agent import VisionAgent
from src.agents.storyteller.agent import StorytellerAgent
from src.agents.voice.agent import VoiceAgent


@pytest.fixture(scope="session")
def event_loop():
    """Create an instance of the default event loop for the test session."""
    loop = asyncio.get_event_loop_policy().new_event_loop()
    yield loop
    loop.close()


@pytest.fixture
def mock_config():
    """Mock configuration for testing."""
    return {
        "app": {
            "name": "Mira Storyteller Test",
            "version": "2.0.0",
            "environment": "test"
        },
        "api": {
            "host": "127.0.0.1",
            "port": 8000,
            "cors": {
                "allowed_origins": ["*"],
                "allowed_methods": ["*"],
                "allowed_headers": ["*"]
            }
        },
        "agents": {
            "vision": {
                "vendor": "google",
                "model": "gemini-2.0-flash-exp",
                "api_key": "test-key"
            },
            "storyteller": {
                "vendor": "mistral",
                "model": "mistral-medium-latest",
                "api_key": "test-key",
                "max_tokens": 300,
                "temperature": 0.7
            },
            "voice": {
                "vendor": "elevenlabs",
                "api_key": "test-key",
                "default_voice": "callum"
            }
        },
        "supabase": {
            "url": "https://test.supabase.co",
            "key": "test-key",
            "storage": {
                "bucket": "test-audio"
            }
        },
        "logging": {
            "level": "DEBUG",
            "format": "text"
        }
    }


@pytest.fixture
def mock_supabase_service():
    """Mock Supabase service for testing."""
    service = Mock(spec=SupabaseService)
    service.create_kid = AsyncMock()
    service.get_kid = AsyncMock()
    service.get_kids_for_user = AsyncMock()
    service.update_kid = AsyncMock()
    service.delete_kid = AsyncMock()
    service.create_story = AsyncMock()
    service.get_story = AsyncMock()
    service.get_stories_for_kid = AsyncMock()
    service.update_story = AsyncMock()
    service.update_story_status = AsyncMock()
    service.upload_audio = AsyncMock()
    service.delete_audio = AsyncMock()
    service.health_check = AsyncMock()
    return service


@pytest.fixture
def mock_vision_agent():
    """Mock vision agent for testing."""
    agent = Mock(spec=VisionAgent)
    agent.process = AsyncMock(return_value="A colorful drawing of a happy cat playing in a garden")
    agent.validate_config = Mock(return_value=True)
    return agent


@pytest.fixture
def mock_storyteller_agent():
    """Mock storyteller agent for testing."""
    agent = Mock(spec=StorytellerAgent)
    agent.process = AsyncMock(return_value={
        "title": "The Happy Cat's Adventure",
        "content": "Once upon a time, there was a happy cat who loved to play in the garden. The cat would chase butterflies and smell the flowers all day long. It was the happiest cat in the whole world, and everyone who saw it couldn't help but smile."
    })
    agent.validate_config = Mock(return_value=True)
    return agent


@pytest.fixture
def mock_voice_agent():
    """Mock voice agent for testing."""
    agent = Mock(spec=VoiceAgent)
    agent.process = AsyncMock(return_value=(b"fake_audio_data", "audio/mpeg"))
    agent.validate_config = Mock(return_value=True)
    return agent


@pytest.fixture
def sample_kid_data():
    """Sample kid profile data for testing."""
    return {
        "id": "kid-123",
        "user_id": "user-456",
        "name": "Alice",
        "age": 6,
        "avatar_type": "profile1",
        "created_at": "2024-01-01T00:00:00Z"
    }


@pytest.fixture
def sample_story_data():
    """Sample story data for testing."""
    return {
        "id": "story-789",
        "kid_id": "kid-123",
        "title": "The Magic Garden",
        "content": "Once upon a time in a magical garden...",
        "image_description": "A beautiful garden with colorful flowers",
        "audio_url": "https://example.com/audio.mp3",
        "status": "approved",
        "language": "en",
        "created_at": "2024-01-01T00:00:00Z"
    }


@pytest.fixture
def sample_base64_image():
    """Sample base64 image data for testing."""
    # This is a minimal 1x1 pixel PNG in base64
    return "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg=="


@pytest.fixture
def fastapi_app(mock_config, monkeypatch):
    """Create FastAPI app with mocked config."""
    def mock_load_config():
        return mock_config
    
    monkeypatch.setattr("src.api.app.load_config", mock_load_config)
    return create_app()


@pytest.fixture
async def test_client(fastapi_app):
    """Create test client for API testing."""
    from httpx import AsyncClient
    async with AsyncClient(app=fastapi_app, base_url="http://test") as client:
        yield client