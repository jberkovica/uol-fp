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
        self.main_config = get_config()
        self.voice_config = self.main_config["agents"]["voice"]
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
        """Get configuration for specific language."""
        lang_configs = self.voice_config.get("languages", {})
        
        if language in lang_configs:
            return lang_configs[language]
        
        # Fallback to English if language not configured
        if "en" in lang_configs:
            logger.warning(f"Language {language} not configured, falling back to English")
            return lang_configs["en"]
        
        raise ValueError(f"No TTS configuration found for language {language} or fallback English")
    
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
            "speed": settings.get("speed", 1.0),
            "response_format": settings.get("response_format", "mp3")
        }
        
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
    """Factory function to create a voice agent."""
    vendor = AgentVendor(config.get("vendor", "elevenlabs"))
    return VoiceAgent(vendor, config)