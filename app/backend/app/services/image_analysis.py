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
from prompts.image_analysis import IMAGE_CAPTION_PROMPT, IMAGE_MODEL_CONFIG
from config.models import ModelType, get_model_config, get_api_key

# Configure logging
logger = logging.getLogger(__name__)

class ImageAnalysisService:
    """Service for analyzing images using Gemini 2.0 Flash API"""
    
    def __init__(self, api_key: str = None, use_alternative: bool = False, alternative_index: int = 0):
        """
        Initialize the image analysis service
        
        Args:
            api_key: API key (from config if None)
            use_alternative: Whether to use alternative model
            alternative_index: Index of alternative model to use
        """
        self.model_config = get_model_config(ModelType.IMAGE_ANALYSIS, use_alternative, alternative_index)
        self.api_key = api_key or get_api_key(self.model_config)
        
        if not self.api_key:
            model_name = self.model_config.get('model_name', 'Unknown')
            logger.warning(f"No API key provided for {model_name}. Image analysis will not work.")
    
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
            
            # Prepare API request using configured model
            base_url = self.model_config['api_endpoint']
            url = f"{base_url}?key={self.api_key}"
            
            request_body = {
                'contents': [{
                    'parts': [
                        {
                            'text': IMAGE_CAPTION_PROMPT
                        },
                        {
                            'inline_data': {
                                'mime_type': mime_type,
                                'data': base64_data
                            }
                        }
                    ]
                }],
                'generationConfig': self.model_config['parameters']
            }
            
            response = requests.post(
                url,
                headers={'Content-Type': 'application/json'},
                json=request_body,
                timeout=self.model_config.get('timeout', 30)
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
                                "model": self.model_config['model_name'],
                                "provider": self.model_config['provider'].value
                            }
                            
                            logger.info(f"Image analysis completed from base64 data")
                            return analysis_result
                
                raise Exception(f'No caption generated from {self.model_config["model_name"]} response')
            else:
                error_data = response.json() if response.headers.get('content-type', '').startswith('application/json') else response.text
                raise Exception(f"{self.model_config['model_name']} API error: {response.status_code} - {error_data}")
                
        except Exception as e:
            logger.error(f"Error analyzing image: {str(e)}")
            return {
                "caption": "A colorful image with interesting elements",
                "success": False,
                "error": str(e),
                "model": self.model_config.get('model_name', 'unknown'),
                "provider": self.model_config.get('provider', 'unknown').value if hasattr(self.model_config.get('provider', 'unknown'), 'value') else 'unknown'
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
                "model": self.model_config.get('model_name', 'unknown'),
                "provider": self.model_config.get('provider', 'unknown').value if hasattr(self.model_config.get('provider', 'unknown'), 'value') else 'unknown'
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
