"""
Image Analysis Service for Mira Storyteller

This module handles the analysis of images using Gemini 2.0 Flash to identify objects,
scenes, and elements that can be used in story generation.
"""

import logging
import os
import base64
import requests
from typing import Dict, List, Any
from PIL import Image
import io

# Configure logging
logger = logging.getLogger(__name__)

class ImageAnalysisService:
    """Service for analyzing images using Gemini 2.0 Flash API"""
    
    def __init__(self, api_key: str = None):
        """
        Initialize the image analysis service
        
        Args:
            api_key: Google API key for Gemini models (from env var if None)
        """
        self.api_key = api_key or os.getenv("GOOGLE_API_KEY")
        if not self.api_key:
            logger.warning("No API key provided for Gemini 2.0 Flash. Image analysis will not work.")
    
    def analyze_image_from_base64(self, base64_data: str, mime_type: str = "image/jpeg") -> Dict[str, Any]:
        """
        Analyze image from base64 data to generate a concise caption for story generation
        
        Args:
            base64_data: Base64 encoded image data
            mime_type: MIME type of the image (default: image/jpeg)
            
        Returns:
            Dictionary containing analysis results with caption
        """
        try:
            if not self.api_key:
                raise ValueError("No API key configured for Gemini 2.0 Flash")
            
            # Prepare Gemini 2.0 Flash API request
            url = f"https://generativelanguage.googleapis.com/v1/models/gemini-2.0-flash:generateContent?key={self.api_key}"
            
            request_body = {
                'contents': [{
                    'parts': [
                        {
                            'text': 'Describe this image concisely in 2-3 sentences. Focus on the main elements visible. Keep your response to approximately 50-75 words.'
                        },
                        {
                            'inline_data': {
                                'mime_type': mime_type,
                                'data': base64_data
                            }
                        }
                    ]
                }],
                'generationConfig': {
                    'maxOutputTokens': 100,
                    'temperature': 0.3,
                }
            }
            
            response = requests.post(
                url,
                headers={'Content-Type': 'application/json'},
                json=request_body,
                timeout=30
            )
            
            if response.status_code == 200:
                data = response.json()
                if data.get('candidates') and len(data['candidates']) > 0:
                    candidate = data['candidates'][0]
                    if candidate.get('content') and candidate['content'].get('parts'):
                        parts = candidate['content']['parts']
                        if len(parts) > 0 and parts[0].get('text'):
                            caption = parts[0]['text'].strip()
                            
                            analysis_result = {
                                "caption": caption,
                                "success": True,
                                "model": "gemini-2.0-flash"
                            }
                            
                            logger.info(f"Image analysis completed from base64 data")
                            return analysis_result
                
                raise Exception('No caption generated from Gemini response')
            else:
                error_data = response.json() if response.headers.get('content-type', '').startswith('application/json') else response.text
                raise Exception(f"Gemini API error: {response.status_code} - {error_data}")
                
        except Exception as e:
            logger.error(f"Error analyzing image: {str(e)}")
            return {
                "caption": "A colorful image with interesting elements",
                "success": False,
                "error": str(e),
                "model": "gemini-2.0-flash"
            }

    def analyze_image(self, image_path: str) -> Dict[str, Any]:
        """
        Analyze image to generate a concise caption for story generation
        
        Args:
            image_path: Path to the image file
            
        Returns:
            Dictionary containing analysis results with caption
        """
        try:
            if not self.api_key:
                raise ValueError("No API key configured for Gemini 2.0 Flash")
            
            # Open and encode the image
            with open(image_path, "rb") as image_file:
                image_data = image_file.read()
            
            base64_image = base64.b64encode(image_data).decode('utf-8')
            
            # Determine MIME type
            image = Image.open(image_path)
            format_map = {
                'JPEG': 'image/jpeg',
                'PNG': 'image/png',
                'WEBP': 'image/webp'
            }
            mime_type = format_map.get(image.format, 'image/jpeg')
            
            return self.analyze_image_from_base64(base64_image, mime_type)
                
        except Exception as e:
            logger.error(f"Error analyzing image: {str(e)}")
            return {
                "caption": "A colorful image with interesting elements",
                "success": False,
                "error": str(e),
                "model": "gemini-2.0-flash"
            }
    
    def get_image_caption(self, image_path: str) -> str:
        """
        Get a simple caption of the image for story generation
        
        Args:
            image_path: Path to the image file
            
        Returns:
            String describing the image content
        """
        try:
            analysis = self.analyze_image(image_path)
            return analysis.get("caption", "A colorful image with interesting elements")
        except Exception as e:
            logger.error(f"Error getting image caption: {str(e)}")
            return "A colorful image with interesting elements"
    
    def get_image_caption_from_base64(self, base64_data: str, mime_type: str = "image/jpeg") -> str:
        """
        Get a simple caption of the image for story generation from base64 data
        
        Args:
            base64_data: Base64 encoded image data
            mime_type: MIME type of the image
            
        Returns:
            String describing the image content
        """
        try:
            analysis = self.analyze_image_from_base64(base64_data, mime_type)
            return analysis.get("caption", "A colorful image with interesting elements")
        except Exception as e:
            logger.error(f"Error getting image caption: {str(e)}")
            return "A colorful image with interesting elements"
