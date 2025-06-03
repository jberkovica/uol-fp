#!/usr/bin/env python3
"""
API Key Validation Script

This script tests all API integrations to ensure they are properly configured
and working before running the full evaluation pipeline. It provides detailed
feedback on any issues found.
"""

import os
import sys
import logging
import argparse
from pathlib import Path

# Add the project root to the path so we can use absolute imports
project_root = Path(__file__).parent.parent.parent
sys.path.append(str(project_root))

# Set up logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
    handlers=[logging.StreamHandler()]
)
logger = logging.getLogger("api_validation")

# Import the API client functions
from models_analysis.utils.api_clients import (
    get_replicate_blip_caption,
    get_replicate_blip2_caption,
    get_replicate_cogvlm_caption,
    # ViT model removed as it's not reliable for image captioning
    get_google_vision_caption,
    get_gemini_caption,
    get_openai_vision_caption,
    get_claude_response
)

from models_analysis.config.models_config import (
    REPLICATE_API_TOKEN,
    GOOGLE_API_KEY,
    OPENAI_API_KEY,
    CLAUDE_API_KEY
)

def validate_api_keys():
    """Validate all API keys and report their status."""
    api_keys_status = {
        "Replicate API Token": bool(REPLICATE_API_TOKEN),
        "Google API Key": bool(GOOGLE_API_KEY),
        "OpenAI API Key": bool(OPENAI_API_KEY),
        "Claude API Key": bool(CLAUDE_API_KEY)
    }
    
    logger.info("API Key Validation Results:")
    all_valid = True
    
    for api_name, is_valid in api_keys_status.items():
        status = "Valid" if is_valid else "Missing or Invalid"
        logger.info(f"{api_name}: {status}")
        if not is_valid:
            all_valid = False
    
    return all_valid

def test_image_loading(image_path):
    """Test if the image can be loaded correctly."""
    try:
        if not os.path.exists(image_path):
            logger.error(f"Image file not found: {image_path}")
            return False
        
        with open(image_path, "rb") as img_file:
            image_bytes = img_file.read()
            logger.info(f"Successfully loaded image: {image_path} ({len(image_bytes)} bytes)")
            return image_bytes
    except Exception as e:
        logger.error(f"Error loading image: {e}")
        return False

def test_api_function(api_func, image_path, model_name):
    try:
        caption, exec_time, cost = api_func(image_path)
        
        if "ERROR" in caption:
            logger.warning(f"{model_name} error: {caption}")
        else:
            logger.info(f"{model_name} success: \"{caption}\" (Time: {exec_time:.2f}s, Cost: ${cost:.6f})")
    except Exception as e:
        logger.error(f"Error with {model_name}: {e}")

def test_replicate_api(image_path):
    """Test the Replicate API with different models."""
    if not REPLICATE_API_TOKEN:
        logger.warning("Skipping Replicate API tests - API token not provided")
        return
    
    logger.info("Testing Replicate API models...")
    
    # Test BLIP
    logger.info("Testing BLIP model...")
    test_api_function(get_replicate_blip_caption, image_path, "BLIP")
    
    # Test BLIP-2
    logger.info("Testing BLIP-2 model...")
    test_api_function(get_replicate_blip2_caption, image_path, "BLIP-2")
    
    # Test CogVLM
    logger.info("Testing CogVLM model...")
    test_api_function(get_replicate_cogvlm_caption, image_path, "CogVLM")
    
    # Note: ViT model removed from testing as it's not reliable for image captioning

def test_google_apis(image_bytes):
    """Test the Google Vision and Gemini APIs."""
    if not GOOGLE_API_KEY:
        logger.warning("Skipping Google API tests - API key not provided")
        return
    
    # Test Google Vision API
    try:
        logger.info("Testing Google Vision API...")
        caption, exec_time, cost = get_google_vision_caption(image_bytes)
        
        if "ERROR" in caption:
            logger.warning(f"Google Vision API error: {caption}")
        else:
            logger.info(f"Google Vision API success: \"{caption}\" (Time: {exec_time:.2f}s, Cost: ${cost:.6f})")
    except Exception as e:
        logger.error(f"Error with Google Vision API: {e}")
    
    # Test Gemini API
    try:
        logger.info("Testing Gemini API...")
        caption, exec_time, cost = get_gemini_caption(image_bytes)
        
        if "ERROR" in caption:
            logger.warning(f"Gemini API error: {caption}")
        else:
            logger.info(f"Gemini API success: \"{caption}\" (Time: {exec_time:.2f}s, Cost: ${cost:.6f})")
    except Exception as e:
        logger.error(f"Error with Gemini API: {e}")

def test_openai_api(image_path):
    """Test the OpenAI Vision API."""
    if not OPENAI_API_KEY:
        logger.warning("Skipping OpenAI API tests - API key not provided")
        return
    
    try:
        logger.info("Testing OpenAI Vision API...")
        caption, exec_time, cost = get_openai_vision_caption(image_path)
        
        if "ERROR" in caption:
            logger.warning(f"OpenAI Vision API error: {caption}")
        else:
            logger.info(f"OpenAI Vision API success: \"{caption}\" (Time: {exec_time:.2f}s, Cost: ${cost:.6f})")
    except Exception as e:
        logger.error(f"Error with OpenAI Vision API: {e}")

def test_claude_api():
    """Test the Claude text-to-text API."""
    if not CLAUDE_API_KEY:
        logger.warning("Skipping Claude API tests - API key not provided")
        return
    
    try:
        logger.info("Testing Claude text-to-text API...")
        test_prompt = "Write a brief caption for an image showing a cute animal."
        response, exec_time, cost = get_claude_response(test_prompt)
        
        if "ERROR" in response:
            logger.warning(f"Claude API error: {response}")
        else:
            # Limit the displayed response to first 100 characters to keep logs clean
            display_response = response[:100] + "..." if len(response) > 100 else response
            logger.info(f"Claude API success: \"{display_response}\" (Time: {exec_time:.2f}s, Cost: ${cost:.6f})")
    except Exception as e:
        logger.error(f"Error with Claude API: {e}")

def main():
    parser = argparse.ArgumentParser(description="Validate API keys and test image captioning APIs")
    parser.add_argument("--image", "-i", required=True, help="Path to an image file for testing")
    args = parser.parse_args()
    
    logger.info("Starting API validation tests...")
    
    # Validate API keys
    keys_valid = validate_api_keys()
    if not keys_valid:
        logger.warning("Some API keys are missing or invalid - limited testing will be performed")
    
    # Test image loading
    image_bytes = test_image_loading(args.image)
    if not image_bytes:
        logger.error("Image loading failed - cannot proceed with API tests")
        return
    
    # Test all APIs
    test_replicate_api(args.image)
    test_google_apis(image_bytes)
    test_openai_api(args.image)
    test_claude_api()  # Claude test is text-to-text, doesn't need image
    
    logger.info("API validation tests completed.")

if __name__ == "__main__":
    main()
