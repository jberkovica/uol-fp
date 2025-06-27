"""
Unit tests for model configuration system
"""

import pytest
from unittest.mock import patch
from config.models import (
    ModelType,
    ModelProvider,
    get_model_config,
    get_api_key,
    is_model_available,
    get_available_models,
    get_voice_config,
    list_available_voices
)


class TestModelConfiguration:
    """Test model configuration retrieval"""
    
    def test_get_primary_model_config(self):
        """Test getting primary model configurations"""
        # Test image analysis config
        config = get_model_config(ModelType.IMAGE_ANALYSIS)
        assert config["provider"] == ModelProvider.GOOGLE
        assert config["model_name"] == "gemini-2.0-flash"
        assert "api_endpoint" in config
        assert "parameters" in config
        
        # Test story generation config
        config = get_model_config(ModelType.STORY_GENERATION)
        assert config["provider"] == ModelProvider.MISTRAL
        assert config["model_name"] == "mistral-medium-latest"
        
        # Test TTS config
        config = get_model_config(ModelType.TEXT_TO_SPEECH)
        assert config["provider"] == ModelProvider.ELEVENLABS
        assert config["model_name"] == "eleven_flash_v2_5"
    
    def test_get_alternative_model_config(self):
        """Test getting alternative model configurations"""
        # Test story generation alternatives
        config = get_model_config(ModelType.STORY_GENERATION, use_alternative=True, alternative_index=0)
        assert config["provider"] == ModelProvider.OPENAI
        assert config["model_name"] == "gpt-4o-mini"
        
        # Test second alternative
        config = get_model_config(ModelType.STORY_GENERATION, use_alternative=True, alternative_index=1)
        assert config["provider"] == ModelProvider.ANTHROPIC
        assert config["model_name"] == "claude-3-5-haiku-20241022"
    
    def test_invalid_model_type_raises_error(self):
        """Test that invalid model type raises ValueError"""
        with pytest.raises(ValueError, match="Model type .* not configured"):
            get_model_config("invalid_model_type")
    
    def test_invalid_alternative_index_raises_error(self):
        """Test that invalid alternative index raises ValueError"""
        with pytest.raises(ValueError, match="Alternative index .* out of range"):
            get_model_config(ModelType.STORY_GENERATION, use_alternative=True, alternative_index=999)
    
    def test_no_alternatives_available_raises_error(self):
        """Test that requesting alternatives when none exist raises error"""
        # Image analysis currently has no alternatives in the config
        with pytest.raises(ValueError, match="No alternative models configured"):
            get_model_config(ModelType.IMAGE_ANALYSIS, use_alternative=True)


class TestAPIKeyManagement:
    """Test API key retrieval and availability checking"""
    
    def test_get_api_key_with_env_var(self, mock_api_keys):
        """Test API key retrieval when environment variable is set"""
        config = get_model_config(ModelType.IMAGE_ANALYSIS)
        api_key = get_api_key(config)
        assert api_key == "mock_google_key"
    
    @patch.dict('os.environ', {}, clear=True)
    def test_get_api_key_without_env_var(self):
        """Test API key retrieval when environment variable is not set"""
        config = get_model_config(ModelType.IMAGE_ANALYSIS)
        api_key = get_api_key(config)
        assert api_key is None
    
    def test_is_model_available_with_api_key(self, mock_api_keys):
        """Test model availability when API key is present"""
        assert is_model_available(ModelType.IMAGE_ANALYSIS) is True
        assert is_model_available(ModelType.STORY_GENERATION) is True
        assert is_model_available(ModelType.TEXT_TO_SPEECH) is True
    
    @patch.dict('os.environ', {}, clear=True)
    def test_is_model_available_without_api_key(self):
        """Test model availability when API key is missing"""
        assert is_model_available(ModelType.IMAGE_ANALYSIS) is False
        assert is_model_available(ModelType.STORY_GENERATION) is False
        assert is_model_available(ModelType.TEXT_TO_SPEECH) is False
    
    def test_get_available_models(self, mock_api_keys):
        """Test getting list of available models"""
        available = get_available_models(ModelType.STORY_GENERATION)
        
        # Should include primary model
        primary_found = any(model["type"] == "primary" for model in available)
        assert primary_found
        
        # Should include alternatives
        alt_found = any(model["type"].startswith("alternative") for model in available)
        assert alt_found
        
        # Each model should have config
        for model in available:
            assert "config" in model
            assert "type" in model


class TestVoiceConfiguration:
    """Test voice configuration for TTS"""
    
    def test_get_valid_voice_config(self):
        """Test getting configuration for valid voice"""
        voice_config = get_voice_config("callum")
        assert voice_config["provider"] == ModelProvider.ELEVENLABS
        assert voice_config["voice_id"] == "N2lVS1w4EtoT3dr4eOWO"
        assert "description" in voice_config
    
    def test_get_invalid_voice_config_raises_error(self):
        """Test that invalid voice name raises ValueError"""
        with pytest.raises(ValueError, match="Voice .* not configured"):
            get_voice_config("nonexistent_voice")
    
    def test_list_available_voices_with_api_key(self, mock_api_keys):
        """Test listing available voices when API key is present"""
        voices = list_available_voices()
        assert isinstance(voices, list)
        assert "callum" in voices
    
    @patch.dict('os.environ', {}, clear=True)
    def test_list_available_voices_without_api_key(self):
        """Test listing available voices when API key is missing"""
        voices = list_available_voices()
        assert isinstance(voices, list)
        assert len(voices) == 0  # No voices available without API key


class TestModelProviders:
    """Test model provider enumeration"""
    
    def test_model_provider_values(self):
        """Test that model provider enum has expected values"""
        assert ModelProvider.GOOGLE.value == "google"
        assert ModelProvider.MISTRAL.value == "mistral"
        assert ModelProvider.OPENAI.value == "openai"
        assert ModelProvider.ANTHROPIC.value == "anthropic"
        assert ModelProvider.ELEVENLABS.value == "elevenlabs"
        assert ModelProvider.DEEPSEEK.value == "deepseek"
    
    def test_model_type_values(self):
        """Test that model type enum has expected values"""
        assert ModelType.IMAGE_ANALYSIS.value == "image_analysis"
        assert ModelType.STORY_GENERATION.value == "story_generation"
        assert ModelType.TEXT_TO_SPEECH.value == "text_to_speech"