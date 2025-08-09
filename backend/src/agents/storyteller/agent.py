"""Storyteller agent for generating children's stories with JSON response validation."""
from typing import Dict, Any, Optional
import json
from pydantic import ValidationError

from ..base import BaseAgent, AgentVendor
from ...types.domain import Language
from ...types.story_models import LLMStoryResponse, StoryGenerationContext
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
        self.word_count = self.main_config["agents"]["storyteller"].get("word_count", "500")
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
            
        elif self.vendor == AgentVendor.GOOGLE:
            import google.generativeai as genai
            genai.configure(api_key=self.api_key)
            self._client = None  # Google uses global configuration
            
        else:
            raise ValueError(f"Unsupported vendor: {self.vendor}")
            
        return self._client
    
    async def process(self, input_data: str, **kwargs) -> Dict[str, str]:
        """
        Generate a story from an image description.
        
        Args:
            input_data: Image description text
            **kwargs: Additional parameters (language, context, etc.)
            
        Returns:
            Dict with 'title' and 'content' keys
        """
        self.validate_config()
        
        # Build context from kwargs
        context = self._build_generation_context(input_data, **kwargs)
        
        # Get unified prompt (no more vendor-specific logic)
        prompt = self._build_unified_prompt(context)
        
        # Get system prompt from config
        system_prompt = self.prompts["story_generation"]["system"]
        
        try:
            client = self.get_vendor_client()
            
            # Generate story with vendor-specific method
            raw_response = await self._generate_with_vendor(client, system_prompt, prompt)
            
            # Debug: Log the raw response to understand what AI returns
            logger.info(f"Raw AI response: {raw_response[:200]}...")
            
            # Parse and validate JSON response
            story_response = self._parse_json_response(raw_response)
            
            # Ensure proper paragraph formatting if not already present
            content = story_response.content
            if '\n\n' not in content:
                # If no paragraph breaks, try to add them intelligently
                content = self._add_paragraph_breaks(content)
            
            return {
                "title": story_response.title,
                "content": content
            }
                
        except Exception as e:
            logger.error(f"Story generation failed: {e}")
            raise
    
    def _build_generation_context(self, image_description: str, **kwargs) -> StoryGenerationContext:
        """Build context object from input parameters."""
        # Get basic parameters
        kid_name = kwargs.get("kid_name", "the child")
        age = kwargs.get("age", 6)
        language = kwargs.get("language", "en")
        
        # Convert Language enum to string if needed
        if isinstance(language, Language):
            language = language.value
        
        # Create context object
        return StoryGenerationContext(
            image_description=image_description,
            kid_name=kid_name,
            age=age,
            language=language,
            appearance_description=kwargs.get("appearance"),
            genres=kwargs.get("genres", []),
            parent_notes=kwargs.get("parent_notes"),
            include_appearance=kwargs.get("include_appearance", 0.3),
            word_count=kwargs.get("word_count", self.word_count)
        )
    
    def _build_unified_prompt(self, context: StoryGenerationContext) -> str:
        """Build unified prompt using template from config file."""
        # Get prompt template from config
        prompt_template = self.prompts["story_generation"]["user"]
        
        # Build parameters for template
        language_name = self._get_language_name_from_code(context.language)
        age_group = context.get_age_group()
        additional_context = context.build_context_string()
        
        # Format the template with actual values
        return prompt_template.format(
            image_description=context.image_description,
            kid_name=context.kid_name,
            age_group=age_group,
            language=language_name,
            word_count=context.word_count,
            additional_context=additional_context
        )
    
    async def _generate_with_vendor(self, client, system_prompt: str, user_prompt: str) -> str:
        """Generate story using the appropriate vendor method."""
        if self.vendor == AgentVendor.MISTRAL:
            return await self._process_mistral(client, system_prompt, user_prompt)
        elif self.vendor == AgentVendor.OPENAI:
            return await self._process_openai(client, system_prompt, user_prompt)
        elif self.vendor == AgentVendor.ANTHROPIC:
            return await self._process_anthropic(client, system_prompt, user_prompt)
        elif self.vendor == AgentVendor.GOOGLE:
            return await self._process_google(client, system_prompt, user_prompt)
        else:
            raise ValueError(f"Unsupported vendor: {self.vendor}")
    
    def _parse_json_response(self, raw_response: str) -> LLMStoryResponse:
        """Parse and validate JSON response from LLM."""
        try:
            # First, try to parse as JSON directly
            json_data = json.loads(raw_response.strip())
            logger.info(f"Successfully parsed JSON directly")
            return LLMStoryResponse(**json_data)
        except (json.JSONDecodeError, ValidationError) as e:
            logger.warning(f"Direct JSON parsing failed: {e}")
            
            # Try to extract JSON from markdown code blocks or other wrappers
            try:
                import re
                # Look for JSON in markdown code blocks: ```json {...} ```
                json_match = re.search(r'```(?:json)?\s*(\{[\s\S]*?\})\s*```', raw_response)
                if json_match:
                    json_str = json_match.group(1)
                    json_data = json.loads(json_str)
                    logger.info(f"Successfully parsed JSON from markdown block")
                    return LLMStoryResponse(**json_data)
                
                # Look for standalone JSON objects: { ... }
                json_match = re.search(r'\{[\s\S]*\}', raw_response)
                if json_match:
                    json_str = json_match.group(0)
                    json_data = json.loads(json_str)
                    logger.info(f"Successfully parsed JSON from raw text")
                    return LLMStoryResponse(**json_data)
                    
            except (json.JSONDecodeError, ValidationError) as fallback_error:
                logger.warning(f"Fallback JSON extraction failed: {fallback_error}")
            
            # Last resort: use old title extraction method
            logger.warning("Using legacy title extraction as last resort")
            return self._fallback_parse_response(raw_response)
    
    def _fallback_parse_response(self, raw_response: str) -> LLMStoryResponse:
        """Fallback parsing when JSON parsing completely fails - extract title and content manually."""
        logger.warning(f"Fallback parsing raw response: {raw_response[:100]}...")
        
        # If response looks like JSON, reject it to avoid displaying JSON as content
        if raw_response.strip().startswith('{"') and raw_response.strip().endswith('}'):
            logger.error(f"Response appears to be malformed JSON, cannot parse: {raw_response[:200]}...")
            # Return a safe fallback rather than the JSON string
            return LLMStoryResponse(
                title="Story Generation Error",
                content="Unable to parse the story response. Please try again."
            )
        
        # Extract title using old method for plain text responses
        title = self._extract_title(raw_response)
        
        # Clean up content by removing title and JSON artifacts
        content = raw_response
        if title and title in raw_response:
            content = raw_response.replace(title, "").strip()
        
        # Remove common JSON artifacts if they appear
        content = content.replace('"title":', '').replace('"content":', '')
        content = content.replace('{', '').replace('}', '').strip()
        content = content.strip('"').strip()
        
        # Ensure we have meaningful content
        if not content or len(content.strip()) < 20:
            content = "Unable to generate story content. Please try again."
        
        return LLMStoryResponse(
            title=title or "Generated Story",
            content=content
        )
    
    def _add_paragraph_breaks(self, content: str) -> str:
        """Add intelligent paragraph breaks to story content if none exist."""
        # Split on sentence boundaries (. ! ?) followed by uppercase letter
        import re
        sentences = re.split(r'([.!?])\s+(?=[A-Z])', content)
        
        if len(sentences) < 6:  # Not enough sentences for paragraphs
            return content
        
        # Rebuild with paragraph breaks every 2-3 sentences
        result = []
        current_paragraph = []
        sentence_count = 0
        
        for i in range(0, len(sentences), 2):  # Step by 2 to get sentence + punctuation
            if i + 1 < len(sentences):
                sentence = sentences[i] + sentences[i + 1]
            else:
                sentence = sentences[i]
            
            current_paragraph.append(sentence.strip())
            sentence_count += 1
            
            # Add paragraph break every 2-3 sentences
            if sentence_count >= 2 and (sentence_count % 3 == 0 or len(current_paragraph) >= 3):
                result.append(' '.join(current_paragraph))
                current_paragraph = []
                sentence_count = 0
        
        # Add remaining sentences
        if current_paragraph:
            result.append(' '.join(current_paragraph))
        
        return '\n\n'.join(result)
    
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
            "temperature": self.temperature,
            "response_format": {"type": "json_object"}  # Enable JSON mode for Mistral
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
            temperature=self.temperature,
            response_format={"type": "json_object"}  # Enable JSON mode for OpenAI
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
    
    async def _process_google(self, client, system_prompt: str, user_prompt: str) -> str:
        """Generate story with Google Gemini - simplified approach."""
        import google.generativeai as genai
        
        # Use basic generation config for now
        generation_config = genai.GenerationConfig(
            temperature=self.temperature,
            max_output_tokens=self.max_tokens
        )
        
        # Combine system and user prompts for Gemini
        combined_prompt = f"{system_prompt}\n\n{user_prompt}"
        
        model = genai.GenerativeModel(self.model)
        response = model.generate_content(
            combined_prompt,
            generation_config=generation_config
        )
        
        return response.text
    
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
    
    def _get_language_name_from_code(self, language_code: str) -> str:
        """Convert language code string to full name."""
        language_map = {
            "en": "English",
            "ru": "Russian", 
            "lv": "Latvian",
            "es": "Spanish"
        }
        return language_map.get(language_code, "English")


def create_storyteller_agent(config: Dict[str, Any]) -> StorytellerAgent:
    """Factory function to create a storyteller agent."""
    vendor = AgentVendor(config.get("vendor", "mistral"))
    return StorytellerAgent(vendor, config)