"""
AI Models Configuration for Mira Storyteller

This module contains centralized configuration for all AI models used in the application.
Easy to update when new models are released or parameters need adjustment.
"""

import os
from typing import Dict, Any, Optional
from enum import Enum

class ModelProvider(Enum):
    """Supported AI model providers"""
    GOOGLE = "google"
    MISTRAL = "mistral"
    OPENAI = "openai"
    ANTHROPIC = "anthropic"
    ELEVENLABS = "elevenlabs"
    DEEPSEEK = "deepseek"

class ModelType(Enum):
    """Types of AI models by functionality"""
    IMAGE_ANALYSIS = "image_analysis"
    STORY_GENERATION = "story_generation"
    TEXT_TO_SPEECH = "text_to_speech"

# Model configurations
MODELS_CONFIG = {
    # Image Analysis Models
    ModelType.IMAGE_ANALYSIS: {
        "primary": {
            "provider": ModelProvider.GOOGLE,
            "model_name": "gemini-2.0-flash",
            "api_endpoint": "https://generativelanguage.googleapis.com/v1/models/gemini-2.0-flash:generateContent",
            "api_key_env": "GOOGLE_API_KEY",
            "parameters": {
                "maxOutputTokens": 100,
                "temperature": 0.3,
            },
            "timeout": 30,
            "description": "Fast and accurate image analysis for caption generation"
        },
        "alternatives": [
            {
                "provider": ModelProvider.OPENAI,
                "model_name": "gpt-4o",
                "api_endpoint": "https://api.openai.com/v1/chat/completions",
                "api_key_env": "OPENAI_API_KEY",
                "parameters": {
                    "max_tokens": 100,
                    "temperature": 0.3,
                },
                "timeout": 30,
                "description": "OpenAI's vision model for image analysis"
            }
        ]
    },
    
    # Story Generation Models
    ModelType.STORY_GENERATION: {
        "primary": {
            "provider": ModelProvider.MISTRAL,
            "model_name": "mistral-medium-latest",
            "api_endpoint": "https://api.mistral.ai/v1/chat/completions",
            "api_key_env": "MISTRAL_API_KEY",
            "parameters": {
                "temperature": 0.7,
                "max_tokens": 350,
            },
            "timeout": 60,
            "description": "Creative story generation optimized for children's content"
        },
        "alternatives": [
            {
                "provider": ModelProvider.OPENAI,
                "model_name": "gpt-4o-mini",
                "api_endpoint": "https://api.openai.com/v1/chat/completions",
                "api_key_env": "OPENAI_API_KEY",
                "parameters": {
                    "temperature": 0.7,
                    "max_tokens": 350,
                },
                "timeout": 60,
                "description": "OpenAI's efficient model for story generation"
            },
            {
                "provider": ModelProvider.ANTHROPIC,
                "model_name": "claude-3-5-haiku-20241022",
                "api_endpoint": "https://api.anthropic.com/v1/messages",
                "api_key_env": "CLAUDE_API_KEY",
                "parameters": {
                    "max_tokens": 350,
                    "temperature": 0.7,
                },
                "timeout": 60,
                "description": "Anthropic's fast model for creative writing"
            },
            {
                "provider": ModelProvider.DEEPSEEK,
                "model_name": "deepseek-chat",
                "api_endpoint": "https://api.deepseek.com/chat/completions",
                "api_key_env": "DEEPSEEK_API_KEY",
                "parameters": {
                    "temperature": 0.7,
                    "max_tokens": 350,
                },
                "timeout": 60,
                "description": "DeepSeek's chat model for creative content"
            }
        ]
    },
    
    # Text-to-Speech Models
    ModelType.TEXT_TO_SPEECH: {
        "primary": {
            "provider": ModelProvider.ELEVENLABS,
            "model_name": "eleven_flash_v2_5",
            "voice_id": "N2lVS1w4EtoT3dr4eOWO",  # Callum voice
            "api_endpoint": "https://api.elevenlabs.io/v1/text-to-speech",
            "api_key_env": "ELEVENLABS_API_KEY",
            "parameters": {
                "voice_settings": {
                    "stability": 0.75,
                    "similarity_boost": 0.75,
                    "style": 0.5,
                    "use_speaker_boost": True
                }
            },
            "timeout": 120,
            "description": "High-quality voice synthesis optimized for storytelling"
        },
        "alternatives": [
            {
                "provider": ModelProvider.GOOGLE,
                "model_name": "google-cloud-tts",
                "api_endpoint": "https://texttospeech.googleapis.com/v1/text:synthesize",
                "api_key_env": "GOOGLE_API_KEY",
                "parameters": {
                    "voice": {
                        "languageCode": "en-US",
                        "name": "en-US-Journey-D",
                        "ssmlGender": "MALE"
                    },
                    "audioConfig": {
                        "audioEncoding": "MP3",
                        "pitch": 0.0,
                        "speakingRate": 1.0
                    }
                },
                "timeout": 60,
                "description": "Google Cloud Text-to-Speech alternative"
            }
        ]
    }
}

# Voice configurations for TTS
VOICE_CONFIGS = {
    "callum": {
        "provider": ModelProvider.ELEVENLABS,
        "voice_id": "N2lVS1w4EtoT3dr4eOWO",
        "description": "Warm, friendly male voice perfect for storytelling"
    },
    "rachel": {
        "provider": ModelProvider.ELEVENLABS,
        "voice_id": "21m00Tcm4TlvDq8ikWAM",
        "description": "Clear, engaging female voice"
    },
    "adam": {
        "provider": ModelProvider.ELEVENLABS,
        "voice_id": "pNInz6obpgDQGcFmaJgB",
        "description": "Deep, authoritative male voice"
    }
}

def get_model_config(model_type: ModelType, use_alternative: bool = False, alternative_index: int = 0) -> Dict[str, Any]:
    """
    Get model configuration for a specific model type
    
    Args:
        model_type: The type of model needed
        use_alternative: Whether to use an alternative model instead of primary
        alternative_index: Index of the alternative model to use
        
    Returns:
        Model configuration dictionary
    """
    if model_type not in MODELS_CONFIG:
        raise ValueError(f"Model type {model_type} not configured")
    
    config = MODELS_CONFIG[model_type]
    
    if use_alternative:
        if "alternatives" not in config or not config["alternatives"]:
            raise ValueError(f"No alternative models configured for {model_type}")
        
        if alternative_index >= len(config["alternatives"]):
            raise ValueError(f"Alternative index {alternative_index} out of range for {model_type}")
        
        return config["alternatives"][alternative_index]
    
    return config["primary"]

def get_api_key(model_config: Dict[str, Any]) -> Optional[str]:
    """
    Get API key for a model configuration
    
    Args:
        model_config: Model configuration dictionary
        
    Returns:
        API key string or None if not found
    """
    env_var = model_config.get("api_key_env")
    if env_var:
        return os.getenv(env_var)
    return None

def is_model_available(model_type: ModelType, use_alternative: bool = False, alternative_index: int = 0) -> bool:
    """
    Check if a model is available (has API key configured)
    
    Args:
        model_type: The type of model to check
        use_alternative: Whether to check alternative model
        alternative_index: Index of alternative model to check
        
    Returns:
        True if model is available, False otherwise
    """
    try:
        config = get_model_config(model_type, use_alternative, alternative_index)
        api_key = get_api_key(config)
        return api_key is not None and api_key.strip() != ""
    except (ValueError, KeyError):
        return False

def get_available_models(model_type: ModelType) -> list:
    """
    Get list of available models for a specific type
    
    Args:
        model_type: The type of models to check
        
    Returns:
        List of available model configurations
    """
    available = []
    
    # Check primary model
    if is_model_available(model_type):
        config = get_model_config(model_type)
        available.append({"type": "primary", "config": config})
    
    # Check alternatives
    if model_type in MODELS_CONFIG and "alternatives" in MODELS_CONFIG[model_type]:
        for i, _ in enumerate(MODELS_CONFIG[model_type]["alternatives"]):
            if is_model_available(model_type, use_alternative=True, alternative_index=i):
                config = get_model_config(model_type, use_alternative=True, alternative_index=i)
                available.append({"type": f"alternative_{i}", "config": config})
    
    return available

def get_voice_config(voice_name: str) -> Dict[str, Any]:
    """
    Get voice configuration for TTS
    
    Args:
        voice_name: Name of the voice to get config for
        
    Returns:
        Voice configuration dictionary
    """
    if voice_name not in VOICE_CONFIGS:
        raise ValueError(f"Voice {voice_name} not configured")
    
    return VOICE_CONFIGS[voice_name]

def list_available_voices() -> list:
    """
    Get list of available voices
    
    Returns:
        List of voice names that have API keys configured
    """
    available_voices = []
    
    for voice_name, voice_config in VOICE_CONFIGS.items():
        if voice_config["provider"] == ModelProvider.ELEVENLABS:
            if os.getenv("ELEVENLABS_API_KEY"):
                available_voices.append(voice_name)
        elif voice_config["provider"] == ModelProvider.GOOGLE:
            if os.getenv("GOOGLE_API_KEY"):
                available_voices.append(voice_name)
    
    return available_voices