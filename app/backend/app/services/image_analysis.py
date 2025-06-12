"""
Image Analysis Service for Mira Storyteller

This module handles the analysis of images using AI models to identify objects,
scenes, and elements that can be used in story generation.
"""

import logging
import os
from typing import Dict, List, Any
import google.generativeai as genai
from PIL import Image

# Configure logging
logger = logging.getLogger(__name__)

class ImageAnalysisService:
    """Service for analyzing images using Gemini Vision API"""
    
    def __init__(self, api_key: str = None):
        """
        Initialize the image analysis service
        
        Args:
            api_key: Google API key for Gemini models (from env var if None)
        """
        self.api_key = api_key or os.getenv("GOOGLE_API_KEY")
        if not self.api_key:
            logger.warning("No API key provided for Gemini Vision. Image analysis will not work.")
        else:
            genai.configure(api_key=self.api_key)
    
    def analyze_image(self, image_path: str) -> Dict[str, Any]:
        """
        Analyze image to identify elements for story generation
        
        Args:
            image_path: Path to the image file
            
        Returns:
            Dictionary containing analysis results
        """
        try:
            if not self.api_key:
                raise ValueError("No API key configured for Gemini Vision")
            
            # Open and prepare the image
            image = Image.open(image_path)
            
            # Configure the model
            model = genai.GenerativeModel('gemini-pro-vision')
            
            # Create prompt for child-friendly image analysis
            prompt = """
            Analyze this image drawn or photographed by a child. 
            Identify main objects, characters, colors, and scenes in a child-friendly way.
            Focus on elements that would be good for creating a children's story.
            Format output as JSON with these keys:
            - main_character: The central figure/character
            - supporting_elements: List of other objects/characters
            - setting: The environment/background
            - colors: Main colors used
            - mood: The overall feeling/mood
            - suggested_themes: 2-3 possible story themes
            """
            
            # Run inference on the image
            response = model.generate_content([prompt, image])
            
            # Process and structure the response
            # Note: In a real implementation, we would parse the JSON from the response
            # For now, we'll return a mock structured response
            analysis_result = {
                "main_character": response.text.strip(),  # This would actually be parsed from JSON
                "supporting_elements": [],
                "setting": "",
                "colors": [],
                "mood": "",
                "suggested_themes": []
            }
            
            logger.info(f"Image analysis completed: {image_path}")
            return analysis_result
            
        except Exception as e:
            logger.error(f"Error analyzing image: {str(e)}")
            # Return a limited analysis so the process can continue
            return {
                "main_character": "unknown",
                "supporting_elements": [],
                "setting": "unknown",
                "colors": [],
                "mood": "neutral",
                "suggested_themes": ["adventure"],
                "error": str(e)
            }
    
    def get_image_description(self, image_path: str) -> str:
        """
        Get a simple description of the image
        
        Args:
            image_path: Path to the image file
            
        Returns:
            String describing the image content
        """
        try:
            analysis = self.analyze_image(image_path)
            
            # Create a simple description from the analysis
            if analysis.get("main_character") == "unknown":
                return "A colorful drawing"
            
            description = f"A drawing of {analysis['main_character']}"
            if analysis.get("setting"):
                description += f" in {analysis['setting']}"
            
            return description
        except Exception as e:
            logger.error(f"Error getting image description: {str(e)}")
            return "A colorful drawing"
