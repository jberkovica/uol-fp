"""
Text-to-Speech Service for Mira Storyteller

This module converts generated stories into audio narrations using
Google's Text-to-Speech API or similar services.
"""

import logging
import os
from typing import Dict, Any, Optional
from google.cloud import texttospeech
import tempfile

# Configure logging
logger = logging.getLogger(__name__)

class TextToSpeechService:
    """Service for converting text to speech using Google Cloud TTS"""
    
    def __init__(self, credentials_path: str = None):
        """
        Initialize the text-to-speech service
        
        Args:
            credentials_path: Path to Google Cloud credentials JSON (from env var if None)
        """
        self.credentials_path = credentials_path or os.getenv("GOOGLE_APPLICATION_CREDENTIALS")
        if not self.credentials_path:
            logger.warning("No credentials provided for Google Cloud TTS. Text-to-speech will not work.")
    
    def generate_audio(self, 
                      text: str, 
                      output_path: str,
                      voice_params: Optional[Dict[str, Any]] = None) -> str:
        """
        Convert text to speech and save as audio file
        
        Args:
            text: Text content to convert to speech
            output_path: Path where audio file will be saved
            voice_params: Optional parameters for voice customization
            
        Returns:
            Path to the generated audio file
        """
        try:
            if not self.credentials_path:
                raise ValueError("No credentials configured for Google Cloud TTS")
            
            # Default voice parameters if none provided
            if not voice_params:
                voice_params = {
                    "language_code": "en-US",
                    "name": "en-US-Neural2-F",  # Child-friendly female voice
                    "ssml_gender": texttospeech.SsmlVoiceGender.FEMALE,
                    "speaking_rate": 0.9,  # Slightly slower for children
                    "pitch": 0
                }
            
            # Initialize Text-to-Speech client
            client = texttospeech.TextToSpeechClient()
            
            # Set the text input to be synthesized
            synthesis_input = texttospeech.SynthesisInput(text=text)
            
            # Build the voice request
            voice = texttospeech.VoiceSelectionParams(
                language_code=voice_params["language_code"],
                name=voice_params["name"],
                ssml_gender=voice_params["ssml_gender"]
            )
            
            # Select the audio file type
            audio_config = texttospeech.AudioConfig(
                audio_encoding=texttospeech.AudioEncoding.MP3,
                speaking_rate=voice_params["speaking_rate"],
                pitch=voice_params["pitch"],
                effects_profile_id=["small-bluetooth-speaker-class-device"]  # Optimize for small speakers
            )
            
            # Perform the text-to-speech request
            response = client.synthesize_speech(
                input=synthesis_input,
                voice=voice,
                audio_config=audio_config
            )
            
            # Write the response to the output file
            with open(output_path, "wb") as out:
                out.write(response.audio_content)
                
            logger.info(f"Audio content written to: {output_path}")
            return output_path
            
        except Exception as e:
            logger.error(f"Error generating audio: {str(e)}")
            # Return None to indicate failure
            return None
    
    def generate_story_audio(self, story_content: str, story_id: str, output_dir: str) -> Optional[str]:
        """
        Generate audio narration for a story
        
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
            
            # Generate audio with child-friendly voice settings
            voice_params = {
                "language_code": "en-US",
                "name": "en-US-Neural2-F",  # Child-friendly female voice
                "ssml_gender": texttospeech.SsmlVoiceGender.FEMALE,
                "speaking_rate": 0.9,  # Slightly slower for children
                "pitch": 0.2  # Slightly higher pitch for child-friendly tone
            }
            
            return self.generate_audio(story_content, output_path, voice_params)
            
        except Exception as e:
            logger.error(f"Error generating story audio: {str(e)}")
            return None
