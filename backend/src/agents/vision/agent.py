"""Vision agent for image analysis."""
import base64
import os
from typing import Dict, Any, Optional

from ..base import BaseAgent, AgentVendor
from ...utils.logger import get_logger
from ...utils.config import get_config

logger = get_logger(__name__)


class VisionAgent(BaseAgent):
    """Agent for analyzing images and generating descriptions."""
    
    def __init__(self, vendor: AgentVendor, config: Dict[str, Any]):
        super().__init__(vendor, config)
        self.main_config = get_config()
        self.prompts = self.main_config["agents"]["vision"]["prompts"]
        self._client = None
    
    def validate_config(self) -> bool:
        """Validate agent configuration."""
        if not self.api_key:
            raise ValueError(f"API key not provided for {self.vendor}")
        if not self.model:
            raise ValueError(f"Model not specified for {self.vendor}")
        return True
    
    def get_vendor_client(self):
        """Get vendor-specific client."""
        if self._client:
            return self._client
            
        if self.vendor == AgentVendor.GOOGLE:
            import google.generativeai as genai
            genai.configure(api_key=self.api_key)
            self._client = genai.GenerativeModel(self.model)
            
        elif self.vendor == AgentVendor.OPENAI:
            from openai import OpenAI
            self._client = OpenAI(api_key=self.api_key)
            
        elif self.vendor == AgentVendor.ANTHROPIC:
            from anthropic import Anthropic
            self._client = Anthropic(api_key=self.api_key)
            
        else:
            raise ValueError(f"Unsupported vendor: {self.vendor}")
            
        return self._client
    
    async def process(self, input_data: str, **kwargs) -> str:
        """
        Analyze an image and return a description.
        
        Args:
            input_data: Base64 encoded image data
            **kwargs: Additional parameters (e.g., custom_prompt)
            
        Returns:
            Image description suitable for story generation
        """
        self.validate_config()
        
        # Get the appropriate prompt
        prompt_key = kwargs.get("prompt_key", "image_caption")
        prompt = self.prompts[prompt_key].get(
            self.vendor.value,
            self.prompts[prompt_key]["default"]
        )
        
        # Override with custom prompt if provided
        if "custom_prompt" in kwargs:
            prompt = kwargs["custom_prompt"]
        
        try:
            client = self.get_vendor_client()
            
            if self.vendor == AgentVendor.GOOGLE:
                return await self._process_google(client, input_data, prompt)
            elif self.vendor == AgentVendor.OPENAI:
                return await self._process_openai(client, input_data, prompt)
            elif self.vendor == AgentVendor.ANTHROPIC:
                return await self._process_anthropic(client, input_data, prompt)
            else:
                raise ValueError(f"Unsupported vendor: {self.vendor}")
                
        except Exception as e:
            logger.error(f"Vision processing failed: {e}")
            raise
    
    async def _process_google(self, client, image_data: str, prompt: str) -> str:
        """Process image with Google Gemini."""
        import PIL.Image
        import io
        
        # Decode base64 to image
        image_bytes = base64.b64decode(image_data)
        image = PIL.Image.open(io.BytesIO(image_bytes))
        
        # Generate content
        response = client.generate_content([prompt, image])
        return response.text
    
    async def _process_openai(self, client, image_data: str, prompt: str) -> str:
        """Process image with OpenAI Vision."""
        response = client.chat.completions.create(
            model=self.model,
            messages=[
                {
                    "role": "user",
                    "content": [
                        {"type": "text", "text": prompt},
                        {
                            "type": "image_url",
                            "image_url": {
                                "url": f"data:image/jpeg;base64,{image_data}"
                            }
                        }
                    ]
                }
            ],
            max_tokens=300
        )
        return response.choices[0].message.content
    
    async def _process_anthropic(self, client, image_data: str, prompt: str) -> str:
        """Process image with Anthropic Claude."""
        response = client.messages.create(
            model=self.model,
            max_tokens=300,
            messages=[
                {
                    "role": "user",
                    "content": [
                        {
                            "type": "text",
                            "text": prompt
                        },
                        {
                            "type": "image",
                            "source": {
                                "type": "base64",
                                "media_type": "image/jpeg",
                                "data": image_data
                            }
                        }
                    ]
                }
            ]
        )
        return response.content[0].text


def create_vision_agent(config: Dict[str, Any]) -> VisionAgent:
    """Factory function to create a vision agent."""
    vendor = AgentVendor(config.get("vendor", "google"))
    return VisionAgent(vendor, config)