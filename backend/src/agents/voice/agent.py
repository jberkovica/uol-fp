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
        self.default_voice = config.get("default_voice", "callum")
        self._client = None
    
    def validate_config(self) -> bool:
        """Validate agent configuration."""
        if not self.api_key:
            raise ValueError(f"API key not provided for {self.vendor}")
        return True
    
    def get_vendor_client(self):
        """Get vendor-specific client."""
        if self._client:
            return self._client
            
        if self.vendor == AgentVendor.ELEVENLABS:
            # ElevenLabs uses HTTP API calls, no client needed
            self._client = None
            
        elif self.vendor == AgentVendor.GOOGLE:
            from google.cloud import texttospeech
            self._client = texttospeech.TextToSpeechClient()
            
        elif self.vendor == AgentVendor.AZURE:
            import azure.cognitiveservices.speech as speechsdk
            speech_config = speechsdk.SpeechConfig(
                subscription=self.api_key,
                region=self.config.get("region", "eastus")
            )
            self._client = speech_config
            
        else:
            raise ValueError(f"Unsupported vendor: {self.vendor}")
            
        return self._client
    
    async def process(self, input_data: str, **kwargs) -> Tuple[bytes, str]:
        """
        Convert text to speech.
        
        Args:
            input_data: Text to convert to speech
            **kwargs: Additional parameters (voice, language, etc.)
            
        Returns:
            Tuple of (audio_bytes, content_type)
        """
        self.validate_config()
        
        voice = kwargs.get("voice", self.default_voice)
        language = kwargs.get("language", "en")
        
        try:
            client = self.get_vendor_client()
            
            if self.vendor == AgentVendor.ELEVENLABS:
                return await self._process_elevenlabs(client, input_data, voice)
            elif self.vendor == AgentVendor.GOOGLE:
                return await self._process_google(client, input_data, voice, language)
            elif self.vendor == AgentVendor.AZURE:
                return await self._process_azure(client, input_data, voice, language)
            else:
                raise ValueError(f"Unsupported vendor: {self.vendor}")
                
        except Exception as e:
            logger.error(f"TTS processing failed: {e}")
            raise
    
    async def _process_elevenlabs(self, client, text: str, voice: str) -> Tuple[bytes, str]:
        """Generate speech with ElevenLabs using HTTP API (like old backend)."""
        import httpx
        
        voice_id = self._get_voice_id(voice)
        settings = self.voice_config["settings"]["elevenlabs"]
        
        headers = {
            "Accept": "audio/mpeg",
            "Content-Type": "application/json",
            "xi-api-key": self.api_key
        }
        
        payload = {
            "text": text,
            "model_id": "eleven_multilingual_v2",
            "voice_settings": {
                "stability": settings["stability"],
                "similarity_boost": settings["similarity_boost"],
                "style": settings["style"],
                "use_speaker_boost": settings["use_speaker_boost"]
            }
        }
        
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
    
    async def _process_google(self, client, text: str, voice: str, language: str) -> Tuple[bytes, str]:
        """Generate speech with Google Cloud TTS."""
        from google.cloud import texttospeech
        
        voice_name = self._get_voice_id(voice)
        settings = self.voice_config["settings"]["google"]
        
        synthesis_input = texttospeech.SynthesisInput(text=text)
        voice_params = texttospeech.VoiceSelectionParams(
            language_code=language,
            name=voice_name
        )
        audio_config = texttospeech.AudioConfig(
            audio_encoding=texttospeech.AudioEncoding.MP3,
            speaking_rate=settings["speaking_rate"],
            pitch=settings["pitch"],
            volume_gain_db=settings["volume_gain_db"]
        )
        
        response = client.synthesize_speech(
            input=synthesis_input,
            voice=voice_params,
            audio_config=audio_config
        )
        
        return response.audio_content, "audio/mpeg"
    
    async def _process_azure(self, speech_config, text: str, voice: str, language: str) -> Tuple[bytes, str]:
        """Generate speech with Azure Cognitive Services."""
        import azure.cognitiveservices.speech as speechsdk
        
        voice_name = self._get_voice_id(voice)
        settings = self.voice_config["settings"]["azure"]
        
        # Configure speech synthesis
        speech_config.speech_synthesis_voice_name = voice_name
        
        # Create synthesizer with audio output to memory
        synthesizer = speechsdk.SpeechSynthesizer(
            speech_config=speech_config,
            audio_config=None  # Output to memory
        )
        
        # Build SSML
        ssml = f"""
        <speak version='1.0' xml:lang='{language}'>
            <voice name='{voice_name}'>
                <prosody rate='{settings["rate"]}' pitch='{settings["pitch"]}'>
                    {text}
                </prosody>
            </voice>
        </speak>
        """
        
        result = synthesizer.speak_ssml_async(ssml).get()
        
        if result.reason == speechsdk.ResultReason.SynthesizingAudioCompleted:
            return result.audio_data, "audio/mpeg"
        else:
            raise Exception(f"Speech synthesis failed: {result.reason}")
    
    def _get_voice_id(self, voice_name: str) -> str:
        """Get voice ID for the current vendor."""
        vendor_voices = self.voice_config["voices"].get(self.vendor.value, {})
        voice_info = vendor_voices.get(voice_name, {})
        
        if self.vendor == AgentVendor.ELEVENLABS:
            return voice_info.get("id", voice_name)
        else:
            # For Google and Azure, the voice name is the ID
            return voice_name
    
    def list_voices(self) -> Dict[str, Any]:
        """List available voices for the current vendor."""
        return self.voice_config["voices"].get(self.vendor.value, {})


def create_voice_agent(config: Dict[str, Any]) -> VoiceAgent:
    """Factory function to create a voice agent."""
    vendor = AgentVendor(config.get("vendor", "elevenlabs"))
    return VoiceAgent(vendor, config)