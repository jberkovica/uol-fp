"""
Text-to-Speech Service for Mira Storyteller

This module converts generated stories into audio narrations using
ElevenLabs API with Callum voice (N2lVS1w4EtoT3dr4eOWO).
"""

import logging
import os
import requests
from typing import Dict, Any, Optional

# Configure logging
logger = logging.getLogger(__name__)

class TextToSpeechService:
    """Service for converting text to speech using ElevenLabs API"""
    
    def __init__(self, api_key: str = None):
        """
        Initialize the text-to-speech service
        
        Args:
            api_key: ElevenLabs API key (from env var if None)
        """
        self.api_key = api_key or os.getenv("ELEVENLABS_API_KEY")
        self.callum_voice_id = "N2lVS1w4EtoT3dr4eOWO"  # Callum voice as specified
        
        if not self.api_key:
            logger.warning("No API key provided for ElevenLabs TTS. Text-to-speech will not work.")
    
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
            voice_id = voice_id or self.callum_voice_id
            
            # Prepare ElevenLabs API request
            url = f"https://api.elevenlabs.io/v1/text-to-speech/{voice_id}"
            
            request_body = {
                'text': text,
                'model_id': 'eleven_flash_v2_5',
                'voice_settings': {
                    'stability': 0.75,
                    'similarity_boost': 0.75,
                    'style': 0.5,
                    'use_speaker_boost': True
                }
            }
            
            headers = {
                'Content-Type': 'application/json',
                'xi-api-key': self.api_key,
            }
            
            response = requests.post(
                url,
                headers=headers,
                json=request_body,
                timeout=120
            )
            
            if response.status_code == 200:
                # Save audio to file
                with open(output_path, 'wb') as audio_file:
                    audio_file.write(response.content)
                
                logger.info(f"Audio content written to: {output_path}")
                return output_path
            else:
                error_message = response.text
                raise Exception(f"ElevenLabs API error: {response.status_code} - {error_message}")
                
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
            
            # Generate audio with Callum voice
            result = self.generate_audio(story_content, output_path, self.callum_voice_id)
            
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
