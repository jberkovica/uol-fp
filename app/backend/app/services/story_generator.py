"""
Story Generator Service for Mira Storyteller

This module uses Mistral Medium Latest to generate child-friendly stories
based on the captions generated from uploaded images.
"""

import logging
import os
import requests
from typing import Dict, Any, Optional
import json

# Configure logging
logger = logging.getLogger(__name__)

class StoryGeneratorService:
    """Service for generating stories using Mistral Medium Latest API"""
    
    def __init__(self, api_key: str = None):
        """
        Initialize the story generator service
        
        Args:
            api_key: Mistral API key (from env var if None)
        """
        self.api_key = api_key or os.getenv("MISTRAL_API_KEY")
        if not self.api_key:
            logger.warning("No API key provided for Mistral Medium. Story generation will not work.")
    
    def generate_story(self, 
                      image_caption: str, 
                      child_name: str, 
                      preferences: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
        """
        Generate a children's story based on image caption
        
        Args:
            image_caption: Caption generated from image analysis
            child_name: Name of the child (to personalize the story)
            preferences: Optional preferences for story generation
            
        Returns:
            Dictionary containing the generated story
        """
        try:
            if not self.api_key:
                raise ValueError("No API key configured for Mistral Medium")
            
            # Default preferences if none provided
            if not preferences:
                preferences = {
                    "length": "short",  # short, medium, long
                    "style": "bedtime",  # bedtime, adventure, educational
                    "age_group": "4-6"   # 2-3, 4-6, 7-9
                }
            
            # Use the proven prompt from models_analysis that worked well for all 3 agents
            prompt = f'''Create a family-friendly story inspired by this image description: "{image_caption}"

Story Requirements:
- Write exactly 150-200 words
- Target audience: young readers and families
- Theme: suitable for reading aloud at bedtime or story time
- Tone: warm, gentle, and comforting
- Include a positive message or gentle life lesson
- Use simple, accessible language
- End on a peaceful, happy note
- Include an engaging title

Response Format:
Title: [Your Story Title]

[Your complete 150-200 word story]

Note: Adherence to the 150-200 word count is essential for evaluation purposes.'''
            
            # Prepare Mistral API request
            url = "https://api.mistral.ai/v1/chat/completions"
            
            request_body = {
                'model': 'mistral-medium-latest',
                'messages': [
                    {
                        'role': 'system',
                        'content': 'You are a professional story writer. Follow all formatting and word count requirements precisely.'
                    },
                    {
                        'role': 'user',
                        'content': prompt
                    }
                ],
                'temperature': 0.7,
                'max_tokens': 350,
            }
            
            response = requests.post(
                url,
                headers={
                    'Content-Type': 'application/json',
                    'Authorization': f'Bearer {self.api_key}',
                },
                json=request_body,
                timeout=60
            )
            
            if response.status_code == 200:
                data = response.json()
                if data.get('choices') and len(data['choices']) > 0:
                    choice = data['choices'][0]
                    if choice.get('message') and choice['message'].get('content'):
                        story_content = choice['message']['content'].strip()
                        
                        # Parse title and content with improved parsing
                        title = "A Magical Story"
                        content = story_content
                        
                        # Extract title if present - handle multiple formats
                        lines = story_content.split('\n')
                        for i, line in enumerate(lines):
                            line_lower = line.strip().lower()
                            if line_lower.startswith('title:') or line_lower.startswith('**title:'):
                                # Extract title after the colon
                                title_part = line.split(':', 1)[1].strip()
                                # Remove asterisks and other formatting
                                title = title_part.strip('*').strip()
                                # Remove title line from content
                                content_lines = lines[:i] + lines[i+1:]
                                content = '\n'.join(content_lines).strip()
                                break
                        
                        result = {
                            "title": title,
                            "content": content,
                            "summary": f"A story inspired by the image content.",
                            "age_appropriate": True,
                            "keywords": ["adventure", "imagination", "friendship"],
                            "model": "mistral-medium-latest",
                            "success": True
                        }
                        
                        logger.info(f"Story generated for {child_name} using Mistral Medium")
                        return result
                
                raise Exception('No story generated from Mistral response')
            else:
                error_data = response.json() if response.headers.get('content-type', '').startswith('application/json') else response.text
                raise Exception(f"Mistral API error: {response.status_code} - {error_data}")
                
        except Exception as e:
            logger.error(f"Error generating story: {str(e)}")
            # Return a simple fallback story based on image caption
            return {
                "title": "A Wonderful Discovery",
                "content": f"Once upon a time, in a place full of wonder, there was something special waiting to be discovered. " + 
                          f"Based on what we can see: {image_caption}. This led to a magical adventure where " +
                          "imagination and curiosity made everything possible. It was a day filled with joy, " +
                          "learning, and beautiful moments. The end.",
                "summary": "A short story inspired by the image.",
                "age_appropriate": True,
                "keywords": ["adventure", "imagination", "discovery"],
                "model": "mistral-medium-latest",
                "success": False,
                "error": str(e)
            }
    
    def generate_story_from_analysis(self, 
                                   image_analysis: Dict[str, Any], 
                                   child_name: str, 
                                   preferences: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
        """
        Legacy method for backward compatibility - extracts caption from analysis
        
        Args:
            image_analysis: Results from image analysis containing caption
            child_name: Name of the child
            preferences: Optional preferences
            
        Returns:
            Generated story
        """
        caption = image_analysis.get("caption", "a colorful scene")
        return self.generate_story(caption, child_name, preferences)
