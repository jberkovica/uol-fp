"""Voice agent for text-to-speech conversion."""
import io
from typing import Dict, Any, Optional, Tuple

from ..base import BaseAgent, AgentVendor
from ...utils.logger import get_logger
from ...utils.config import get_config

logger = get_logger(__name__)


class VoiceAgent(BaseAgent):
    """Agent for converting text to speech."""
    
    def __init__(self, vendor: AgentVendor, config: Dict[str, Any]):
        super().__init__(vendor, config)
        # For voice agent, config IS the voice config (passed from new structure)
        self.voice_config = config
        self._clients = {}  # Cache clients per vendor
    
    def validate_config(self) -> bool:
        """Validate agent configuration."""
        # Validate that we have language configurations
        languages = self.voice_config.get("languages", {})
        if not languages:
            raise ValueError("No language configurations found in voice config")
        return True
    
    async def process(self, input_data: str, **kwargs) -> Tuple[bytes, str]:
        """
        Convert text to speech using language-specific configuration.
        
        Args:
            input_data: Text to convert to speech
            **kwargs: Additional parameters (language is required)
            
        Returns:
            Tuple of (audio_bytes, content_type)
        """
        language = kwargs.get("language", "en")
        logger.info(f"Processing TTS for language: {language}")
        
        # Get language-specific configuration
        lang_config = self._get_language_config(language)
        vendor = lang_config["vendor"]
        
        try:
            if vendor == "elevenlabs":
                return await self._process_elevenlabs(lang_config, input_data)
            elif vendor == "openai":
                return await self._process_openai(lang_config, input_data)
            elif vendor == "google":
                return await self._process_google(lang_config, input_data)
            elif vendor == "azure":
                return await self._process_azure(lang_config, input_data)
            else:
                raise ValueError(f"Unsupported vendor: {vendor}")
                
        except Exception as e:
            logger.error(f"TTS processing failed for language {language}: {e}")
            raise
    
    def _get_language_config(self, language: str) -> Dict[str, Any]:
        """Get configuration for specific language, merging with vendor config."""
        lang_configs = self.voice_config.get("languages", {})
        vendors_config = self.voice_config.get("vendors", {})
        
        if not lang_configs:
            raise ValueError("No language configurations found in voice config")
        if not vendors_config:
            raise ValueError("No vendor configurations found in voice config")
        
        # Get language configuration
        if language in lang_configs:
            lang_config = lang_configs[language].copy()
        elif "en" in lang_configs:
            logger.warning(f"Language {language} not configured, falling back to English")
            lang_config = lang_configs["en"].copy()
        else:
            available_langs = list(lang_configs.keys())
            raise ValueError(f"No TTS configuration found for language {language}. Available: {available_langs}")
        
        # Get vendor from language config
        vendor = lang_config.get("vendor")
        if not vendor:
            raise ValueError(f"No vendor specified for language {language}")
        
        if vendor not in vendors_config:
            available_vendors = list(vendors_config.keys())
            raise ValueError(f"Vendor '{vendor}' not found in vendor config. Available: {available_vendors}")
        
        vendor_config = vendors_config[vendor]
        
        # Merge vendor configuration into language config
        # API key (required)
        if "api_key" not in vendor_config:
            raise ValueError(f"No api_key found for vendor '{vendor}'")
        lang_config["api_key"] = vendor_config["api_key"]
        
        # Model (required)
        if "model" not in vendor_config:
            raise ValueError(f"No model found for vendor '{vendor}'")
        lang_config["model"] = vendor_config["model"]
        
        # Settings (required) - merge defaults with language-specific overrides
        vendor_settings = vendor_config.get("default_settings", {})
        if not vendor_settings:
            raise ValueError(f"No default_settings found for vendor '{vendor}'")
        
        # Apply language-specific overrides if they exist
        language_overrides = vendor_config.get("language_overrides", {}).get(language, {}).get("settings", {})
        
        # Merge settings: vendor defaults + language overrides
        merged_settings = {**vendor_settings, **language_overrides}
        lang_config["settings"] = merged_settings
        
        # For ElevenLabs, we also need voice_id from available_voices
        if vendor == "elevenlabs":
            voice_name = lang_config.get("voice")
            if not voice_name:
                raise ValueError(f"No voice specified for ElevenLabs language {language}")
            
            available_voices = self.voice_config.get("available_voices", {}).get("elevenlabs", {})
            if voice_name not in available_voices:
                available_voice_names = list(available_voices.keys())
                raise ValueError(f"Voice '{voice_name}' not found in available ElevenLabs voices. Available: {available_voice_names}")
            
            lang_config["voice_id"] = available_voices[voice_name]
        
        return lang_config
    
    async def _process_elevenlabs(self, lang_config: Dict[str, Any], text: str) -> Tuple[bytes, str]:
        """Generate speech with ElevenLabs using language-specific configuration."""
        import httpx
        
        voice_id = lang_config["voice_id"]
        settings = lang_config["settings"]
        api_key = lang_config["api_key"]
        
        headers = {
            "Accept": "audio/mpeg",
            "Content-Type": "application/json",
            "xi-api-key": api_key
        }
        
        # Apply speed setting to ElevenLabs (using stability as speed control)
        speed_factor = settings.get("speed", 1.0)
        adjusted_stability = max(0.0, min(1.0, settings["stability"] * speed_factor))
        
        payload = {
            "text": text,
            "model_id": lang_config.get("model", "eleven_multilingual_v2"),
            "voice_settings": {
                "stability": adjusted_stability,
                "similarity_boost": settings["similarity_boost"],
                "style": settings["style"],
                "use_speaker_boost": settings["use_speaker_boost"]
            }
        }
        
        logger.info(f"ElevenLabs TTS: voice_id={voice_id}, speed={speed_factor}")
        
        async with httpx.AsyncClient() as http_client:
            response = await http_client.post(
                f"https://api.elevenlabs.io/v1/text-to-speech/{voice_id}",
                headers=headers,
                json=payload,
                timeout=60.0
            )
            response.raise_for_status()
            audio_bytes = response.content
        
        return audio_bytes, "audio/mpeg"
    
    async def _process_openai(self, lang_config: Dict[str, Any], text: str) -> Tuple[bytes, str]:
        """Generate speech with OpenAI TTS using language-specific configuration."""
        import httpx
        
        voice = lang_config["voice"]
        model = lang_config.get("model", "tts-1")
        settings = lang_config["settings"]
        api_key = lang_config["api_key"]
        
        headers = {
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json"
        }
        
        payload = {
            "model": model,
            "input": text,
            "voice": voice,
            "response_format": settings.get("response_format", "mp3")
        }
        
        # Add speed parameter only for older TTS models (not gpt-4o-mini-tts)
        if model != "gpt-4o-mini-tts":
            payload["speed"] = settings.get("speed", 1.0)
        
        # Add instructions parameter for gpt-4o-mini-tts model
        if model == "gpt-4o-mini-tts" and "instructions" in settings:
            payload["instructions"] = settings["instructions"]
        
        format_type = settings.get("response_format", "mp3")
        logger.info(f"OpenAI TTS: voice={voice}, model={model}, speed={settings.get('speed', 1.0)}, format={format_type}")
        
        async with httpx.AsyncClient() as http_client:
            response = await http_client.post(
                "https://api.openai.com/v1/audio/speech",
                headers=headers,
                json=payload,
                timeout=60.0
            )
            response.raise_for_status()
            audio_bytes = response.content
        
        # Return appropriate content type based on format
        content_type_map = {
            "mp3": "audio/mpeg",
            "flac": "audio/flac", 
            "wav": "audio/wav",
            "opus": "audio/opus",
            "aac": "audio/aac",
            "pcm": "audio/pcm"
        }
        content_type = content_type_map.get(format_type, "audio/mpeg")
        
        return audio_bytes, content_type
    
    async def _process_google(self, lang_config: Dict[str, Any], text: str) -> Tuple[bytes, str]:
        """Generate speech with Google Cloud TTS using language-specific configuration."""
        from google.cloud import texttospeech
        
        voice = lang_config["voice"]
        settings = lang_config["settings"]
        api_key = lang_config["api_key"]
        
        # Initialize client with API key
        client = texttospeech.TextToSpeechClient()
        
        synthesis_input = texttospeech.SynthesisInput(text=text)
        voice_params = texttospeech.VoiceSelectionParams(
            language_code=settings.get("language_code", "en-US"),
            name=voice
        )
        audio_config = texttospeech.AudioConfig(
            audio_encoding=texttospeech.AudioEncoding.MP3,
            speaking_rate=settings.get("speaking_rate", 1.0),
            pitch=settings.get("pitch", 0.0),
            volume_gain_db=settings.get("volume_gain_db", 0.0)
        )
        
        logger.info(f"Google TTS: voice={voice}, speaking_rate={settings.get('speaking_rate', 1.0)}")
        
        response = client.synthesize_speech(
            input=synthesis_input,
            voice=voice_params,
            audio_config=audio_config
        )
        
        return response.audio_content, "audio/mpeg"
    
    async def _process_azure(self, lang_config: Dict[str, Any], text: str) -> Tuple[bytes, str]:
        """Generate speech with Azure Cognitive Services using language-specific configuration."""
        import azure.cognitiveservices.speech as speechsdk
        
        voice = lang_config["voice"]
        settings = lang_config["settings"]
        api_key = lang_config["api_key"]
        region = lang_config.get("region", "eastus")
        
        # Configure speech synthesis
        speech_config = speechsdk.SpeechConfig(
            subscription=api_key,
            region=region
        )
        speech_config.speech_synthesis_voice_name = voice
        
        # Create synthesizer with audio output to memory
        synthesizer = speechsdk.SpeechSynthesizer(
            speech_config=speech_config,
            audio_config=None  # Output to memory
        )
        
        # Build SSML with language-specific settings
        language_code = settings.get("language_code", "en-US")
        ssml = f"""
        <speak version='1.0' xml:lang='{language_code}'>
            <voice name='{voice}'>
                <prosody rate='{settings.get("rate", "1.0")}' pitch='{settings.get("pitch", "0%")}'>
                    {text}
                </prosody>
            </voice>
        </speak>
        """
        
        logger.info(f"Azure TTS: voice={voice}, rate={settings.get('rate', '1.0')}")
        
        result = synthesizer.speak_ssml_async(ssml).get()
        
        if result.reason == speechsdk.ResultReason.SynthesizingAudioCompleted:
            return result.audio_data, "audio/mpeg"
        else:
            raise Exception(f"Speech synthesis failed: {result.reason}")
    
    def list_available_voices(self) -> Dict[str, Any]:
        """List all available voices from configuration."""
        return self.voice_config.get("available_voices", {})


def create_voice_agent(config: Dict[str, Any]) -> VoiceAgent:
    """Factory function to create a voice agent with multi-vendor support."""
    # For multi-vendor voice agent, we use a generic vendor since each language can have different vendors
    # The actual vendor is determined per-language in _get_language_config()
    vendor = AgentVendor.ELEVENLABS  # Default, but not actually used for routing
    return VoiceAgent(vendor, config)