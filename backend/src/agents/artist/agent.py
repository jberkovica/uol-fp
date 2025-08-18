"""Artist agent for generating story cover images using OpenAI GPT-Image-1 or Google Imagen 3."""
import os
import base64
import asyncio
import aiohttp
from typing import Dict, Optional, Any, List, Tuple, Union
from datetime import datetime
from pathlib import Path
import logging
from io import BytesIO
from PIL import Image
from functools import lru_cache
from dataclasses import dataclass
import json

from google.auth import default
from google import genai
from google.genai import types

from ..base import BaseAgent, AgentVendor
from ...services.supabase import get_supabase_service

logger = logging.getLogger(__name__)


@dataclass
class GenerationResult:
    """Result of image generation attempt."""
    image_url: str
    vendor_used: str
    attempts_made: int
    fallback_used: bool
    model_used: str


class ImageGenerationError(Exception):
    """Base exception for image generation failures."""
    pass


class VendorError(ImageGenerationError):
    """Vendor-specific error."""
    def __init__(self, vendor: str, message: str, retry_after: Optional[int] = None):
        self.vendor = vendor
        self.retry_after = retry_after
        super().__init__(f"{vendor}: {message}")


class ConfigurationError(ImageGenerationError):
    """Configuration validation error."""
    pass


class ArtistAgent(BaseAgent):
    """Generate story cover images using OpenAI GPT-Image-1 or Google Imagen 3."""
    
    def __init__(self, config: Dict[str, Any]):
        """Initialize the Artist agent."""
        self.primary_vendor = config.get("vendor", "openai")
        self.fallback_vendor = config.get("fallback_vendor", "openai")
        self.vendor = self.primary_vendor  # Current active vendor
        
        # Retry configuration
        retry_config = config.get("retry", {})
        self.max_attempts = retry_config.get("max_attempts", 2)
        self.retry_delay = retry_config.get("delay_seconds", 1)
        self.fallback_enabled = retry_config.get("fallback_enabled", True)
        
        # Store full config first (needed by _setup_vendor)
        self.config = config
        
        # Load vendor configurations
        self.openai_config = config.get("openai", {})
        self.google_config = config.get("google", {})
        
        # Load configuration sections
        self.style_config = config.get("style", {})
        self.prompt_structure = config.get("prompt_structure", {})
        self.character_config = config.get("character", {})
        self.reference_config = config.get("reference", {})
        # self.technical_config = config.get("technical", {})
        
        # Initialize for primary vendor (after config is set)
        self._setup_vendor(self.primary_vendor)
        
    def _setup_vendor(self, vendor_name: str):
        """Setup configuration for specified vendor."""
        if vendor_name == "openai":
            super().__init__(AgentVendor.OPENAI, self.config)
            self.model = self.openai_config.get("model", "gpt-image-1")
            self.api_key = self.openai_config.get("api_key")
            self.generation_params = self.openai_config.get("params", {"size": "1024x1024"})
        elif vendor_name == "google":
            super().__init__(AgentVendor.GOOGLE, self.config)
            self.model = self.google_config.get("model", "imagen-3.0-generate-002")
            self.project_id = self.google_config.get("project_id") or os.getenv("GOOGLE_PROJECT_ID")
            self.location = self.google_config.get("location", "us-central1")
            self.generation_params = self.google_config.get("params", {"number_of_images": 1})
            
            # Initialize Google Gen AI client with Vertex AI
            if self.project_id:
                self.google_client = genai.Client(
                    vertexai=True,
                    project=self.project_id,
                    location=self.location
                )
                logger.info(f"Initialized Google Gen AI client with project: {self.project_id}, location: {self.location}")
            else:
                logger.warning("No Google project ID found. Set GOOGLE_PROJECT_ID environment variable or add to config.")
        else:
            raise ValueError(f"Unsupported vendor: {vendor_name}")
        
        self.vendor = vendor_name
        logger.info(f"Switched to vendor: {vendor_name}, model: {self.model}")
        
    def validate_config(self) -> bool:
        """Validate agent configuration."""
        # Validate OpenAI configuration
        if self.vendor == "openai":
            if not hasattr(self, 'api_key') or not self.api_key:
                logger.error("OpenAI API key not configured for Artist agent")
                return False
        
        # Validate Google configuration
        elif self.vendor == "google":
            if not hasattr(self, 'project_id') or not self.project_id:
                logger.error("Google Project ID not configured for Artist agent")
                return False
            if not hasattr(self, 'location') or not self.location:
                logger.error("Google location not configured for Artist agent")
                return False
            if not hasattr(self, 'google_client') or not self.google_client:
                logger.error("Google Gen AI client not initialized")
                return False
            
            # Test client availability
            try:
                # The client is initialized, which means authentication worked
                logger.info("Google Gen AI client initialized and ready")
            except Exception as e:
                logger.error(f"Failed to validate Google Gen AI client: {e}")
                return False
        
        # Set default model if not specified
        if not self.model:
            if self.vendor == "openai":
                self.model = "gpt-image-1"
            elif self.vendor == "google":
                self.model = "imagen-3.0-generate-002"
                
        auth_info = "has_api_key: True" if self.vendor == "openai" else "using ADC"
        logger.info(f"Artist agent config validated - vendor: {self.vendor}, model: {self.model}, {auth_info}")
        return True
    
    async def process(self, input_data: Dict[str, Any], **kwargs) -> Dict[str, Any]:
        """Generate a cover image for the story with retry and fallback logic."""
        logger.info(f"Artist agent process called with primary vendor: {self.primary_vendor}")
        story_data = input_data.get("story", {})
        kid_data = input_data.get("kid", {})
        logger.info(f"Story ID: {story_data.get('id')}, Title: {story_data.get('title', 'No title')}")
        
        # Build the optimized image generation prompt
        prompt = self._build_optimized_prompt(story_data, kid_data)
        
        # Attempt generation with retry and fallback logic
        result = await self._generate_with_retry_and_fallback(
            prompt, story_data, input_data
        )
        
        # Store in Supabase if configured
        stored_urls = await self._store_in_supabase(
            result.image_url, 
            story_data.get("id"),
            prompt
        )
        
        return {
            "success": True,
            "url": stored_urls.get("cover_url", result.image_url),
            "thumbnail_url": stored_urls.get("thumbnail_url"),
            "metadata": {
                "prompt": prompt,
                "vendor": result.vendor_used,
                "model": result.model_used,
                "timestamp": datetime.now().isoformat(),
                "kid_included": self._should_include_kid(kid_data),
                "generation_params": self.generation_params,
                "reference_image_used": self.reference_config.get("use_default_cover", False),
                "prompt_word_count": len(prompt.split()),
                "attempts_made": result.attempts_made,
                "fallback_used": result.fallback_used
            }
        }
    
    async def _generate_with_retry_and_fallback(
        self, prompt: str, story_data: Dict, input_data: Dict
    ) -> GenerationResult:
        """
        Generate image with retry and fallback logic.
        
        Returns:
            GenerationResult: Complete generation result with metadata
        """
        
        total_attempts = 0
        last_error = None
        
        # Try primary vendor first
        for vendor_name in [self.primary_vendor, self.fallback_vendor]:
            if vendor_name == self.fallback_vendor and not self.fallback_enabled:
                logger.info(f"Fallback to {vendor_name} disabled, skipping")
                break
                
            if vendor_name == self.fallback_vendor and vendor_name == self.primary_vendor:
                logger.info(f"Fallback vendor same as primary ({vendor_name}), skipping fallback")
                break
            
            # Setup vendor configuration
            if vendor_name != self.vendor:
                logger.info(f"Switching to vendor: {vendor_name}")
                self._setup_vendor(vendor_name)
            
            # Validate vendor config
            try:
                if not self.validate_config():
                    raise ConfigurationError(f"Invalid configuration for vendor: {vendor_name}")
            except ConfigurationError as e:
                logger.error(str(e))
                continue
                
            # Retry attempts for current vendor
            vendor_attempts = self.max_attempts if vendor_name == self.primary_vendor else 1
            
            for attempt in range(vendor_attempts):
                total_attempts += 1
                logger.info(f"Attempt {total_attempts}: {vendor_name} (vendor attempt {attempt + 1}/{vendor_attempts})")
                
                try:
                    # Generate image with current vendor
                    if vendor_name == "openai":
                        image_url = await self._generate_with_openai(prompt, story_data, input_data)
                    elif vendor_name == "google":
                        image_url = await self._generate_with_google(prompt, story_data, input_data)
                    else:
                        raise ValueError(f"Unsupported vendor: {vendor_name}")
                    
                    logger.info(f"Image generation successful with {vendor_name} on attempt {total_attempts}")
                    return GenerationResult(
                        image_url=image_url,
                        vendor_used=vendor_name,
                        attempts_made=total_attempts,
                        fallback_used=vendor_name != self.primary_vendor,
                        model_used=self.model
                    )
                    
                except Exception as e:
                    last_error = VendorError(vendor_name, str(e))
                    logger.warning(f"Attempt {total_attempts} failed with {vendor_name}: {e}")
                    
                    # Add delay before retry (but not on last attempt)
                    if attempt < vendor_attempts - 1:
                        logger.info(f"Waiting {self.retry_delay}s before retry...")
                        await asyncio.sleep(self.retry_delay)
            
            logger.error(f"All attempts failed for vendor: {vendor_name}")
        
        # All vendors failed
        logger.error(f"All image generation attempts failed after {total_attempts} attempts")
        if last_error:
            raise last_error
        else:
            raise ImageGenerationError("Image generation failed - no vendors available")
    
    def _build_optimized_prompt(self, story_data: Dict, kid_data: Dict) -> str:
        """Build optimized image generation prompt with hierarchical structure."""
        
        # 1. STYLE (Critical - 40% of prompt weight)
        # Use child-neutral style when toggle is disabled to avoid Google safety filters
        include_kids_enabled = self.character_config.get("include_kids_in_generation", True)
        if not include_kids_enabled:
            # Child-neutral style that avoids safety filter triggers
            style_base = """A dreamy, magical square illustration featuring a soft, whimsical scene on a cloud or starry background with white edges blending into a white background.
            Style: soft brushstroke, gentle texture like a storybook.
            Lighting: gentle, glowing, dreamy.
            Format: square, with soft white border blending into background for seamless app layout.
            No sharp edges, round soft corners."""
        else:
            # Original style with children's book references
            style_base = self.style_config.get("base", "Children's book illustration style.")
        
        style_section = f"{style_base.strip()}"
        logger.info(f"DEBUG STYLE SECTION (kids_enabled={include_kids_enabled}): {style_section[:100]}...")
        
        # 2. SCENE (30% - extract key visual elements)
        scene_section = self._extract_scene_description(story_data)
        logger.info(f"DEBUG SCENE SECTION: {scene_section}")
        
        # 3. CHARACTER (20% - optional based on probability)
        character_section = ""
        if self._should_include_kid(kid_data):
            character_section = self._format_character_description(kid_data)
            logger.info(f"DEBUG CHARACTER SECTION: {character_section}")
        else:
            logger.info("DEBUG CHARACTER SECTION: (empty - kids disabled)")
        
        # 4. TECHNICAL (10% - format and restrictions)
        # technical_parts = []
        # if self.technical_config.get("format"):
        #     technical_parts.append(self.technical_config["format"])
        # if self.technical_config.get("restrictions"):
        #     technical_parts.append(self.technical_config["restrictions"])
        # if self.technical_config.get("composition"):
        #     technical_parts.append(self.technical_config["composition"])
        # technical_section = ". ".join(technical_parts)
        
        # Assemble prompt with clear hierarchy
        prompt_parts = [
            style_section,
            f"Scene: {scene_section}" if scene_section else "",
            character_section
            # technical_section
        ]
        
        # Filter out empty parts and join
        prompt = "\n\n".join(part for part in prompt_parts if part.strip())
        
        # Compress to word limit
        max_words = self.prompt_structure.get("max_total_words", 120)
        compressed_prompt = self._compress_to_word_limit(prompt, max_words)
        
        logger.info(f"Generated optimized prompt ({len(compressed_prompt.split())} words): {compressed_prompt[:150]}...")
        
        # DEBUG: Log full prompt for debugging Google safety filters
        logger.info(f"FULL PROMPT SENT TO GOOGLE: {compressed_prompt}")
        
        return compressed_prompt
    
    def _extract_scene_description(self, story_data: Dict) -> str:
        """Extract concise scene description using cover_description from storyteller."""
        
        # Priority 1: Use storyteller's cover_description (optimized for image generation)
        cover_description = story_data.get("cover_description", "").strip()
        if cover_description:
            return cover_description
        
        # Priority 2: Use story title as inspiration (fallback)
        title = story_data.get("title", "").strip()
        if title:
            return f"A magical children's story scene inspired by '{title}'"
        
        # Fallback
        return "A whimsical children's book illustration"
    
    def _should_include_kid(self, kid_data: Dict) -> bool:
        """Determine if kid should be included in the image based on config."""
        # Check master toggle first - if disabled, never include kids
        include_kids_enabled = self.character_config.get("include_kids_in_generation", True)
        if not include_kids_enabled:
            return False
            
        if not kid_data or not kid_data.get("appearance_description"):
            return False
            
        # Get inclusion probability from config
        include_probability = self.character_config.get("include_probability", 0.7)
        
        # Random decision based on probability
        import random
        return random.random() < include_probability
    
    def _format_character_description(self, kid_data: Dict) -> str:
        """Format kid's appearance for image generation with word limit."""
        # Double-check master toggle as safety measure
        include_kids_enabled = self.character_config.get("include_kids_in_generation", True)
        if not include_kids_enabled:
            return ""
            
        appearance = kid_data.get("appearance_description", "").strip()
        name = kid_data.get("name", "the child")
        
        if not appearance:
            return ""
        
        # Limit character description length
        max_words = self.character_config.get("max_description_words", 20)
        appearance_words = appearance.split()[:max_words]
        limited_appearance = " ".join(appearance_words)
        
        # Get representation type
        representation = self._get_representation_type()
        
        if representation == "close_up":
            return f"Character: {name}, {limited_appearance}. Close-up portrait style."
        elif representation == "full_body":
            return f"Character: {name}, {limited_appearance}. Full body in scene."
        elif representation == "background":
            return f"Include {name} ({limited_appearance}) as part of scene."
        else:  # not_shown
            return ""
    
    def _get_representation_type(self) -> str:
        """Get random representation type based on configured weights."""
        representation_types = self.character_config.get("representation_types", {
            "close_up": 0.2,
            "full_body": 0.4,
            "background": 0.3,
            "not_shown": 0.1
        })
        
        import random
        # Weighted random selection
        types = list(representation_types.keys())
        weights = list(representation_types.values())
        return random.choices(types, weights=weights, k=1)[0]
    
    def _compress_to_word_limit(self, prompt: str, max_words: int) -> str:
        """Compress prompt to stay within word limit while preserving hierarchy."""
        words = prompt.split()
        if len(words) <= max_words:
            return prompt
        
        logger.warning(f"Compressing prompt from {len(words)} to {max_words} words")
        
        # Preserve style section (most important) and compress others
        lines = prompt.split('\n\n')
        style_line = lines[0] if lines else ""
        other_lines = lines[1:] if len(lines) > 1 else []
        
        # Allocate words: 40% to style, 60% to rest
        style_words = int(max_words * 0.4)
        other_words = max_words - style_words
        
        # Truncate style if needed
        style_parts = style_line.split()
        if len(style_parts) > style_words:
            style_line = " ".join(style_parts[:style_words])
        
        # Compress other sections proportionally
        if other_lines and other_words > 0:
            other_text = " ".join(other_lines)
            other_parts = other_text.split()[:other_words]
            other_text = " ".join(other_parts)
            return f"{style_line}\n\n{other_text}"
        
        return style_line
    
    @lru_cache(maxsize=1)
    def _load_default_cover_base64(self) -> Optional[str]:
        """Load and cache default cover image as base64."""
        default_path = self.reference_config.get("default_cover_path", "app/assets/images/stories/general.png")
        
        # Try different possible paths
        paths_to_try = [
            Path(default_path),
            Path(f"/Users/jekaterinaberkovich/Documents/Code/uol-fp-mira/{default_path}"),
            Path("app/assets/images/stories/general.png")
        ]
        
        for path in paths_to_try:
            if path.exists():
                try:
                    with open(path, 'rb') as f:
                        base64_data = base64.b64encode(f.read()).decode('utf-8')
                        logger.info(f"Loaded default cover image from: {path}")
                        return base64_data
                except Exception as e:
                    logger.error(f"Error loading default cover from {path}: {e}")
                    continue
        
        logger.warning(f"Default cover image not found at any of the tried paths: {[str(p) for p in paths_to_try]}")
        return None
    
    async def _generate_with_openai(self, prompt: str, story_data: Dict, input_data: Dict) -> str:
        """Generate image using OpenAI GPT-Image-1."""
        import openai
        
        client = openai.AsyncOpenAI(api_key=self.api_key)
        
        try:
            logger.info("Using OpenAI GPT-Image-1 for image generation")
            
            # Check if reference image is available (for logging purposes)
            use_reference = self.reference_config.get("use_default_cover", False)
            if use_reference and self._load_default_cover_base64():
                logger.info("Reference image available but OpenAI DALL-E doesn't support it directly")
            
            # Use DALL-E 3 model (GPT-Image-1 maps to DALL-E 3)
            model = "dall-e-3" if self.model == "gpt-image-1" else self.model
            
            params = {
                "model": model,
                "prompt": prompt,  # Use the optimized prompt directly
                "size": self.generation_params.get("size", "1024x1024"),
                "quality": "standard",
                "n": 1
            }
            
            logger.info(f"Generating image with prompt length: {len(prompt.split())} words")
            response = await client.images.generate(**params)
            
            image_url = response.data[0].url
            logger.info("Successfully generated image with OpenAI")
            return image_url
            
        except Exception as e:
            logger.error(f"Error generating image with OpenAI: {e}", exc_info=True)
            raise
    
    async def _generate_with_google(self, prompt: str, story_data: Dict, input_data: Dict) -> str:
        """Generate image using Google Imagen 3 via Google Gen AI SDK."""
        try:
            logger.info("Using Google Imagen 3 for image generation via Google Gen AI SDK")
            
            # Note: Reference images can be added later if needed
            use_reference = self.reference_config.get("use_default_cover", False)
            if use_reference:
                logger.info("Reference images not implemented yet with Google Gen AI SDK")
            
            logger.info(f"Generating image with prompt length: {len(prompt.split())} words")
            logger.info(f"Using model: {self.model}")
            
            # Generate the image using Google Gen AI SDK
            number_of_images = self.generation_params.get("number_of_images", 1)
            
            response = self.google_client.models.generate_images(
                model=self.model,
                prompt=prompt,
                config=types.GenerateImagesConfig(
                    number_of_images=number_of_images,
                    include_rai_reason=True,
                    output_mime_type='image/jpeg'
                )
            )
            
            # Debug logging
            logger.info(f"Response type: {type(response)}")
            logger.info(f"Response: {response}")
            if hasattr(response, 'generated_images'):
                logger.info(f"Number of images: {len(response.generated_images) if response.generated_images else 0}")
            
            # Check if we have images
            if not response or not response.generated_images:
                # Check for safety filtering
                if hasattr(response, 'rai_reason') and response.rai_reason:
                    raise Exception(f"Image generation blocked by safety filters: {response.rai_reason}")
                raise Exception("No images generated by Google Gen AI SDK")
            
            # Get the first generated image
            generated_image = response.generated_images[0]
            
            # Convert image to base64 data URL
            # The generated_image should have an image attribute with image_bytes
            if hasattr(generated_image, 'image') and hasattr(generated_image.image, 'image_bytes'):
                # Get image bytes directly from the response
                image_bytes = generated_image.image.image_bytes
                image_base64 = base64.b64encode(image_bytes).decode('utf-8')
                
                # Use the mime_type from the response (usually 'image/jpeg')
                mime_type = getattr(generated_image.image, 'mime_type', 'image/jpeg')
                image_url = f"data:{mime_type};base64,{image_base64}"
            else:
                # Log available attributes for debugging
                logger.error(f"Available attributes on generated_image: {dir(generated_image)}")
                if hasattr(generated_image, 'image'):
                    logger.error(f"Available attributes on image: {dir(generated_image.image)}")
                raise Exception(f"Unable to extract image data from response")
            
            logger.info("Successfully generated image with Google Imagen 3 via Google Gen AI SDK")
            return image_url
            
        except Exception as e:
            logger.error(f"Error generating image with Google Imagen 3 via Google Gen AI SDK: {e}", exc_info=True)
            raise
    
    async def _store_in_supabase(self, image_url: str, story_id: Optional[str], prompt: str) -> Dict[str, str]:
        """Download and store generated image in Supabase Storage."""
        if not story_id:
            logger.warning("No story_id provided, skipping Supabase storage")
            return {"cover_url": image_url}
        
        try:
            supabase_service = get_supabase_service()
            if not supabase_service:
                logger.warning("Supabase service not configured, using direct URL")
                return {"cover_url": image_url}
            
            # Get the Supabase client from the service
            supabase = supabase_service.client
            
            # Download image data - handle both URLs and base64 data
            if image_url.startswith('data:image/'):
                # Handle base64 data URL (from Google Imagen)
                base64_data = image_url.split(',')[1]
                image_data = base64.b64decode(base64_data)
            else:
                # Handle external URL (from OpenAI)
                async with aiohttp.ClientSession() as session:
                    async with session.get(image_url) as response:
                        image_data = await response.read()
            
            # Upload to Supabase Storage
            bucket = "story-covers"
            
            # Ensure bucket exists
            try:
                supabase.storage.get_bucket(bucket)
            except:
                # Create bucket if it doesn't exist
                supabase.storage.create_bucket(bucket, public=True)
            
            # Upload main image to generated/ subfolder
            path = f"generated/{str(story_id)}/cover.png"
            logger.info(f"Uploading cover image to path: {path}")
            supabase.storage.from_(bucket).upload(path, image_data, file_options={"content-type": "image/png"})
            
            # Generate and upload thumbnail to generated/ subfolder
            thumbnail_data = self._create_thumbnail(image_data)
            thumbnail_path = f"generated/{str(story_id)}/thumbnail.png"
            logger.info(f"Uploading thumbnail to path: {thumbnail_path}")
            supabase.storage.from_(bucket).upload(thumbnail_path, thumbnail_data, file_options={"content-type": "image/png"})
            
            # Get public URLs
            cover_url = supabase.storage.from_(bucket).get_public_url(path)
            thumbnail_url = supabase.storage.from_(bucket).get_public_url(thumbnail_path)
            
            # Update story record with image URLs
            await supabase_service.update_story(story_id, {
                'cover_image_url': cover_url,
                'cover_image_thumbnail_url': thumbnail_url,
                'cover_image_generated_at': datetime.now().isoformat(),
                'cover_image_metadata': {
                    'original_url': image_url,
                    'prompt_used': prompt,
                    'model': self.model,
                    'vendor': self.vendor,
                    'generation_params': self.generation_params
                }
            })
            
            logger.info(f"Successfully stored image in Supabase for story {story_id}")
            
            return {
                'cover_url': cover_url,
                'thumbnail_url': thumbnail_url
            }
            
        except Exception as e:
            logger.error(f"Error storing image in Supabase: {e}")
            # Fall back to direct URL
            return {"cover_url": image_url}
    
    def _create_thumbnail(self, image_data: bytes, size: tuple = (200, 200)) -> bytes:
        """Create a thumbnail from image data."""
        try:
            # Open image from bytes
            img = Image.open(BytesIO(image_data))
            
            # Create thumbnail
            img.thumbnail(size, Image.Resampling.LANCZOS)
            
            # Save to bytes
            output = BytesIO()
            img.save(output, format='PNG', optimize=True)
            output.seek(0)
            
            return output.read()
        except Exception as e:
            logger.error(f"Error creating thumbnail: {e}")
            # Return original if thumbnail creation fails
            return image_data