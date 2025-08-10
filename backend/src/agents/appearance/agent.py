"""Appearance extraction agent for processing child photos into natural language descriptions."""
import base64
from typing import Dict, Any, Optional
from datetime import datetime

from ..base import BaseAgent, AgentVendor
from ...utils.logger import get_logger
from ...utils.config import get_config

logger = get_logger(__name__)


class AppearanceAgent(BaseAgent):
    """Agent for extracting natural language appearance descriptions from child photos."""
    
    def __init__(self, vendor: AgentVendor, config: Dict[str, Any]):
        super().__init__(vendor, config)
        self.main_config = get_config()
        self.prompts = self.main_config["agents"]["appearance"]["prompts"]
        self.max_tokens = config.get("max_tokens", 200)
        self.temperature = config.get("temperature", 0.3)
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
    
    async def process(self, input_data: str, **kwargs) -> Dict[str, Any]:
        """
        Process image data to extract appearance description.
        
        Args:
            input_data: Base64 encoded image data
            **kwargs: Must include 'kid_name' and 'age'
            
        Returns:
            Dict with appearance description and metadata
        """
        kid_name = kwargs.get("kid_name", "the child")
        age = kwargs.get("age", 5)
        return await self.extract_appearance(input_data, kid_name, age)
    
    async def extract_appearance(self, image_data: str, kid_name: str, age: int) -> Dict[str, Any]:
        """
        Extract natural language appearance description from a child photo.
        
        Args:
            image_data: Base64 encoded image data (without data URL prefix)
            kid_name: Child's name for personalized description
            age: Child's age for age-appropriate description
            
        Returns:
            Dict with appearance description and metadata
        """
        self.validate_config()
        
        try:
            client = self.get_vendor_client()
            
            # Build prompt using config template
            prompt = self._build_appearance_prompt(kid_name, age)
            
            # Generate appearance description with vendor-specific method
            description = await self._extract_with_vendor(client, prompt, image_data)
            
            # Return structured result with metadata
            return {
                "description": description.strip(),
                "extracted_at": datetime.utcnow().isoformat(),
                "model_used": self.model,
                "vendor": self.vendor.value,
                "confidence": "high",  # Could be enhanced with actual confidence scores
                "word_count": len(description.split()),
                "extraction_method": "ai_vision"
            }
                
        except Exception as e:
            logger.error(f"Appearance extraction failed: {e}")
            raise
    
    def _build_appearance_prompt(self, kid_name: str, age: int) -> str:
        """Build prompt for appearance extraction using config template."""
        template = self.prompts["appearance_extraction"]
        return template.format(kid_name=kid_name, age=age)
    
    async def _extract_with_vendor(self, client, prompt: str, image_data: str) -> str:
        """Extract appearance using the appropriate vendor method."""
        if self.vendor == AgentVendor.GOOGLE:
            return await self._process_google(client, prompt, image_data)
        elif self.vendor == AgentVendor.OPENAI:
            return await self._process_openai(client, prompt, image_data)
        elif self.vendor == AgentVendor.ANTHROPIC:
            return await self._process_anthropic(client, prompt, image_data)
        else:
            raise ValueError(f"Unsupported vendor: {self.vendor}")
    
    async def _process_google(self, client, prompt: str, image_data: str) -> str:
        """Process with Google Gemini Vision."""
        import google.generativeai as genai
        from PIL import Image
        import io
        
        # Convert base64 to PIL Image
        image_bytes = base64.b64decode(image_data)
        image = Image.open(io.BytesIO(image_bytes))
        
        # Generate content with image and prompt
        response = client.generate_content([prompt, image])
        return response.text
    
    async def _process_openai(self, client, prompt: str, image_data: str) -> str:
        """Process with OpenAI GPT-4 Vision."""
        # Format image data for OpenAI
        data_url = f"data:image/jpeg;base64,{image_data}"
        
        response = client.chat.completions.create(
            model=self.model,
            messages=[
                {
                    "role": "user",
                    "content": [
                        {"type": "text", "text": prompt},
                        {"type": "image_url", "image_url": {"url": data_url}}
                    ]
                }
            ],
            max_tokens=self.max_tokens,
            temperature=self.temperature
        )
        return response.choices[0].message.content
    
    async def _process_anthropic(self, client, prompt: str, image_data: str) -> str:
        """Process with Anthropic Claude Vision."""
        response = client.messages.create(
            model=self.model,
            max_tokens=self.max_tokens,
            temperature=self.temperature,
            messages=[
                {
                    "role": "user",
                    "content": [
                        {
                            "type": "image",
                            "source": {
                                "type": "base64",
                                "media_type": "image/jpeg",
                                "data": image_data
                            }
                        },
                        {"type": "text", "text": prompt}
                    ]
                }
            ]
        )
        return response.content[0].text


def create_appearance_agent(config: Dict[str, Any]) -> AppearanceAgent:
    """Factory function to create an appearance extraction agent."""
    vendor = AgentVendor(config.get("vendor", "google"))
    return AppearanceAgent(vendor, config)