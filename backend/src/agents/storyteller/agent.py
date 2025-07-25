"""Storyteller agent for generating children's stories."""
from typing import Dict, Any, Optional

from ..base import BaseAgent, AgentVendor
from ...types.domain import Language
from ...utils.logger import get_logger
from ...utils.config import get_config

logger = get_logger(__name__)


class StorytellerAgent(BaseAgent):
    """Agent for generating children's stories from descriptions."""
    
    def __init__(self, vendor: AgentVendor, config: Dict[str, Any]):
        super().__init__(vendor, config)
        self.main_config = get_config()
        self.prompts = self.main_config["agents"]["storyteller"]["prompts"]
        self.max_tokens = config.get("max_tokens", 300)
        self.temperature = config.get("temperature", 0.7)
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
            
        if self.vendor == AgentVendor.MISTRAL:
            # Mistral uses HTTP API calls, no client needed
            self._client = None
            
        elif self.vendor == AgentVendor.OPENAI:
            from openai import OpenAI
            self._client = OpenAI(api_key=self.api_key)
            
        elif self.vendor == AgentVendor.ANTHROPIC:
            from anthropic import Anthropic
            self._client = Anthropic(api_key=self.api_key)
            
        else:
            raise ValueError(f"Unsupported vendor: {self.vendor}")
            
        return self._client
    
    async def process(self, input_data: str, **kwargs) -> Dict[str, str]:
        """
        Generate a story from an image description.
        
        Args:
            input_data: Image description text
            **kwargs: Additional parameters (language, theme, etc.)
            
        Returns:
            Dict with 'title' and 'content' keys
        """
        self.validate_config()
        
        # Get system prompt
        system_prompt = self.prompts["story_generation"]["system"].get(
            self.vendor.value,
            self.prompts["story_generation"]["system"]["default"]
        )
        
        # Get user prompt template
        language = kwargs.get("language", Language.ENGLISH)
        if language != Language.ENGLISH:
            user_template = self.prompts["story_generation"]["user"]["with_language"]
            user_prompt = user_template.format(
                image_description=input_data,
                language=self._get_language_name(language)
            )
        else:
            user_template = self.prompts["story_generation"]["user"]["default"]
            user_prompt = user_template.format(image_description=input_data)
        
        try:
            client = self.get_vendor_client()
            
            if self.vendor == AgentVendor.MISTRAL:
                story_content = await self._process_mistral(client, system_prompt, user_prompt)
            elif self.vendor == AgentVendor.OPENAI:
                story_content = await self._process_openai(client, system_prompt, user_prompt)
            elif self.vendor == AgentVendor.ANTHROPIC:
                story_content = await self._process_anthropic(client, system_prompt, user_prompt)
            elif self.vendor == AgentVendor.GOOGLE:
                story_content = await self._process_google(client, system_prompt, user_prompt)
            else:
                raise ValueError(f"Unsupported vendor: {self.vendor}")
            
            # Extract title from the story (first line or generate)
            title = self._extract_title(story_content)
            
            return {
                "title": title,
                "content": story_content
            }
                
        except Exception as e:
            logger.error(f"Story generation failed: {e}")
            raise
    
    async def _process_mistral(self, client, system_prompt: str, user_prompt: str) -> str:
        """Generate story with Mistral using HTTP API (like old backend)."""
        import httpx
        
        headers = {
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json"
        }
        
        payload = {
            "model": self.model,
            "messages": [
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_prompt}
            ],
            "max_tokens": self.max_tokens,
            "temperature": self.temperature
        }
        
        async with httpx.AsyncClient() as http_client:
            response = await http_client.post(
                "https://api.mistral.ai/v1/chat/completions",
                headers=headers,
                json=payload,
                timeout=60.0
            )
            response.raise_for_status()
            result = response.json()
            return result["choices"][0]["message"]["content"]
    
    async def _process_openai(self, client, system_prompt: str, user_prompt: str) -> str:
        """Generate story with OpenAI."""
        response = client.chat.completions.create(
            model=self.model,
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_prompt}
            ],
            max_tokens=self.max_tokens,
            temperature=self.temperature
        )
        return response.choices[0].message.content
    
    async def _process_anthropic(self, client, system_prompt: str, user_prompt: str) -> str:
        """Generate story with Anthropic Claude."""
        response = client.messages.create(
            model=self.model,
            system=system_prompt,
            messages=[
                {"role": "user", "content": user_prompt}
            ],
            max_tokens=self.max_tokens,
            temperature=self.temperature
        )
        return response.content[0].text
    
    def _extract_title(self, story_content: str) -> str:
        """Extract or generate a title from the story."""
        lines = story_content.strip().split('\n')
        
        # Check if first line looks like a title
        if lines and len(lines[0]) < 100 and not lines[0].endswith('.'):
            return lines[0].strip('"').strip()
        
        # Generate a simple title from first sentence
        first_sentence = story_content.split('.')[0]
        words = first_sentence.split()[:5]
        return ' '.join(words) + "..."
    
    def _get_language_name(self, language: Language) -> str:
        """Convert language code to full name."""
        language_map = {
            Language.ENGLISH: "English",
            Language.RUSSIAN: "Russian",
            Language.LATVIAN: "Latvian",
            Language.SPANISH: "Spanish"
        }
        return language_map.get(language, "English")


def create_storyteller_agent(config: Dict[str, Any]) -> StorytellerAgent:
    """Factory function to create a storyteller agent."""
    vendor = AgentVendor(config.get("vendor", "mistral"))
    return StorytellerAgent(vendor, config)