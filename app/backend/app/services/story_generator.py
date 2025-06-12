"""
Story Generator Service for Mira Storyteller

This module uses AI language models to generate child-friendly stories
based on the elements identified in uploaded images.
"""

import logging
import os
from typing import Dict, Any, Optional
import google.generativeai as genai
import json

# Configure logging
logger = logging.getLogger(__name__)

class StoryGeneratorService:
    """Service for generating stories using Gemini Pro API"""
    
    def __init__(self, api_key: str = None):
        """
        Initialize the story generator service
        
        Args:
            api_key: Google API key for Gemini models (from env var if None)
        """
        self.api_key = api_key or os.getenv("GOOGLE_API_KEY")
        if not self.api_key:
            logger.warning("No API key provided for Gemini Pro. Story generation will not work.")
        else:
            genai.configure(api_key=self.api_key)
    
    def generate_story(self, 
                      image_analysis: Dict[str, Any], 
                      child_name: str, 
                      preferences: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
        """
        Generate a children's story based on image analysis
        
        Args:
            image_analysis: Results from image analysis
            child_name: Name of the child (to personalize the story)
            preferences: Optional preferences for story generation
            
        Returns:
            Dictionary containing the generated story
        """
        try:
            if not self.api_key:
                raise ValueError("No API key configured for Gemini Pro")
            
            # Default preferences if none provided
            if not preferences:
                preferences = {
                    "length": "short",  # short, medium, long
                    "style": "bedtime",  # bedtime, adventure, educational
                    "age_group": "4-6"   # 2-3, 4-6, 7-9
                }
            
            # Customize length based on preferences
            word_count = {
                "short": "150-200",
                "medium": "250-350",
                "long": "400-500"
            }.get(preferences.get("length", "short"), "150-200")
            
            # Main character from image analysis
            main_character = image_analysis.get("main_character", "a friendly creature")
            
            # Supporting elements
            elements = image_analysis.get("supporting_elements", [])
            elements_text = ", ".join(elements) if elements else "magical elements"
            
            # Setting
            setting = image_analysis.get("setting", "a colorful world")
            
            # Suggested themes
            themes = image_analysis.get("suggested_themes", ["adventure"])
            themes_text = ", ".join(themes)
            
            # Configure the model
            model = genai.GenerativeModel('gemini-pro')
            
            # Create prompt for story generation
            prompt = f"""
            Create a child-friendly story for {child_name}, who is in the {preferences.get('age_group', '4-6')} age group.
            
            The story should be a {preferences.get('style', 'bedtime')} story, approximately {word_count} words.
            
            Story elements:
            - Main character: {main_character}
            - Other elements: {elements_text}
            - Setting: {setting}
            - Themes to incorporate: {themes_text}
            
            The story should:
            - Start with "Once upon a time" or similar child-friendly opening
            - Have a clear beginning, middle, and end
            - Include a gentle lesson or positive message
            - End on a happy, uplifting note
            - Be appropriate for young children (no scary content, violence, or complex themes)
            - Include the child's name ({child_name}) in the story, if possible
            
            Format the response as JSON with the following structure:
            {{
                "title": "The title of the story",
                "content": "The full story text",
                "summary": "A very brief 1-2 sentence summary",
                "age_appropriate": true,  // Boolean indicating if content is age-appropriate
                "keywords": ["keyword1", "keyword2"]  // 3-5 keywords representing the story
            }}
            """
            
            # Generate the story
            response = model.generate_content(prompt)
            
            # Parse the JSON response
            # In a real implementation, we'd properly parse the JSON from the response
            # For demo purposes, we'll create a mock structure
            try:
                # Attempt to parse JSON from the response
                result = json.loads(response.text)
            except json.JSONDecodeError:
                # If parsing fails, create a structured response manually
                logger.warning("Could not parse JSON from model response. Creating structured response manually.")
                result = {
                    "title": f"{main_character}'s Adventure",
                    "content": response.text,
                    "summary": f"A story about {main_character} in {setting}.",
                    "age_appropriate": True,
                    "keywords": themes
                }
            
            logger.info(f"Story generated for {child_name}")
            return result
            
        except Exception as e:
            logger.error(f"Error generating story: {str(e)}")
            # Return a simple fallback story
            return {
                "title": "The Magical Adventure",
                "content": f"Once upon a time, there was a wonderful adventure with {child_name}. " + 
                          "They discovered many amazing things and had a great time. The end.",
                "summary": "A short adventure story.",
                "age_appropriate": True,
                "keywords": ["adventure", "imagination"],
                "error": str(e)
            }
