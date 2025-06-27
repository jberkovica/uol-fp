"""
Text-to-Speech Service for Mira Storyteller

This module converts generated stories into audio narrations using
ElevenLabs API with Callum voice (N2lVS1w4EtoT3dr4eOWO).
"""

import logging
import os
import requests
from typing import Dict, Any, Optional
from config.models import ModelType, get_model_config, get_api_key, get_voice_config

# Configure logging
logger = logging.getLogger(__name__)

class TextToSpeechService:
    """Service for converting text to speech using ElevenLabs API"""
    
    def __init__(self, api_key: str = None, voice_name: str = "callum", use_alternative: bool = False, alternative_index: int = 0):
        """
        Initialize the text-to-speech service
        
        Args:
            api_key: API key (from config if None)
            voice_name: Name of voice to use (default: callum)
            use_alternative: Whether to use alternative TTS model
            alternative_index: Index of alternative model to use
        """
        self.model_config = get_model_config(ModelType.TEXT_TO_SPEECH, use_alternative, alternative_index)
        self.api_key = api_key or get_api_key(self.model_config)
        self.voice_config = get_voice_config(voice_name)
        self.voice_id = self.voice_config['voice_id']
        
        if not self.api_key:
            model_name = self.model_config.get('model_name', 'Unknown')
            logger.warning(f"No API key provided for {model_name}. Text-to-speech will not work.")
    
    def generate_audio(self, 
                      text: str, 
                      output_path: str,
                      voice_id: str = None) -> str:
        """
        Convert text to speech and save as audio file using ElevenLabs
        
        Args:
            text: Text content to convert to speech
            output_path: Path where audio file will be saved
            voice_id: Voice ID to use (defaults to Callum)
            
        Returns:
            Path to the generated audio file
        """
        try:
            if not self.api_key:
                raise ValueError("No API key configured for ElevenLabs TTS")
            
            # Use Callum voice by default
            voice_id = voice_id or self.voice_id
            
            # Prepare TTS API request using configured model
            base_url = self.model_config['api_endpoint']
            url = f"{base_url}/{voice_id}"
            
            request_body = {
                'text': text,
                'model_id': self.model_config['model_name'],
                **self.model_config['parameters']
            }
            
            headers = {
                'Content-Type': 'application/json',
                'xi-api-key': self.api_key,
            }
            
            response = requests.post(
                url,
                headers=headers,
                json=request_body,
                timeout=self.model_config.get('timeout', 120)
            )
            
            if response.status_code == 200:
                # Save audio to file
                with open(output_path, 'wb') as audio_file:
                    audio_file.write(response.content)
                
                logger.info(f"Audio content written to: {output_path}")
                return output_path
            else:
                error_message = response.text
                raise Exception(f"{self.model_config['model_name']} API error: {response.status_code} - {error_message}")
                
        except Exception as e:
            logger.error(f"Error generating audio: {str(e)}")
            return None
    
    def generate_story_audio(self, story_content: str, story_id: str, output_dir: str) -> Optional[str]:
        """
        Generate audio narration for a story using Callum voice
        
        Args:
            story_content: The text content of the story
            story_id: Unique identifier for the story
            output_dir: Directory where audio files should be saved
            
        Returns:
            Path to the generated audio file, or None if unsuccessful
        """
        try:
            # Ensure output directory exists
            os.makedirs(output_dir, exist_ok=True)
            
            # Define output path
            output_path = os.path.join(output_dir, f"{story_id}.mp3")
            
            # Generate audio with configured voice
            result = self.generate_audio(story_content, output_path, self.voice_id)
            
            if result:
                logger.info(f"Story audio generated successfully for story {story_id}")
                return result
            else:
                logger.error(f"Failed to generate audio for story {story_id}")
                return None
                
        except Exception as e:
            logger.error(f"Error generating story audio: {str(e)}")
            return None
    
    def get_available_voices(self) -> Dict[str, Any]:
        """
        Get list of available voices from ElevenLabs
        
        Returns:
            Dictionary containing voice information
        """
        try:
            if not self.api_key:
                return {"error": "No API key configured"}
            
            url = "https://api.elevenlabs.io/v1/voices"
            headers = {"xi-api-key": self.api_key}
            
            response = requests.get(url, headers=headers, timeout=10)
            
            if response.status_code == 200:
                data = response.json()
                return {
                    "success": True,
                    "voices": data.get("voices", []),
                    "callum_voice_id": self.callum_voice_id
                }
            else:
                return {
                    "success": False,
                    "error": f"API error: {response.status_code}"
                }
                
        except Exception as e:
            logger.error(f"Error getting available voices: {str(e)}")
            return {
                "success": False,
                "error": str(e)
            }
