#!/usr/bin/env python3
"""
Script to test API keys for all image captioning services.

This script validates the following API keys:
1. Replicate API token (for BLIP, BLIP-2, CogVLM, ViT models)
2. Google API key (for Google Vision and Gemini)
3. OpenAI API key (for GPT-4o Vision)

Run this script before executing the main evaluation to ensure
all API keys are correctly configured.
"""

import os
import sys
import requests
import logging
import time
from datetime import datetime

# Add parent directory to path so we can import our modules
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from config.models_config import (
    REPLICATE_API_TOKEN, GOOGLE_API_KEY, OPENAI_API_KEY,
    LOGS_FOLDER
)

# Set up logging
def setup_logging():
    """Configure logging to file and console."""
    os.makedirs(LOGS_FOLDER, exist_ok=True)
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    log_file = os.path.join(LOGS_FOLDER, f"api_key_test_{timestamp}.log")
    
    # Configure logging format
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
        handlers=[
            logging.FileHandler(log_file),
            logging.StreamHandler()
        ]
    )
    
    return log_file

def print_header(message):
    """Print a formatted header."""
    print("\n" + "="*50)
    print(f" {message}")
    print("="*50)

def test_replicate_api():
    """
    Test Replicate API token by listing models.
    
    Returns:
        bool: True if successful, False otherwise
    """
    print_header("Testing Replicate API")
    
    if not REPLICATE_API_TOKEN:
        print("ERROR: Replicate API token (REPLICATE_API_TOKEN) not found in .env file")
        logging.error("Replicate API token not found in environment variables")
        return False
    
    headers = {"Authorization": f"Token {REPLICATE_API_TOKEN}"}
    url = "https://api.replicate.com/v1/models"
    
    try:
        logging.info("Testing Replicate API connection")
        response = requests.get(url, headers=headers, timeout=10)
        
        if response.status_code == 200:
            print("SUCCESS: Replicate API token is valid")
            logging.info("Replicate API token validation successful")
            return True
        else:
            print(f"ERROR: Authentication failed with status code {response.status_code}")
            print(f"Response: {response.text}")
            logging.error(f"Replicate API authentication failed: {response.status_code} - {response.text}")
            return False
            
    except Exception as e:
        print(f"ERROR: Failed to connect to Replicate API: {str(e)}")
        logging.error(f"Failed to connect to Replicate API: {str(e)}")
        return False

def test_google_api():
    """
    Test Google API key by making a simple Vision API request.
    
    Returns:
        bool: True if successful, False otherwise
    """
    print_header("Testing Google API Key")
    
    if not GOOGLE_API_KEY:
        print("ERROR: Google API key (GOOGLE_API_KEY) not found in .env file")
        logging.error("Google API key not found in environment variables")
        return False
    
    # Test with a simple Vision API request
    url = f"https://vision.googleapis.com/v1/images:annotate?key={GOOGLE_API_KEY}"
    
    # Minimal payload to test authentication
    payload = {
        "requests": [
            {
                "image": {
                    "content": ""  # Empty content for testing auth only
                },
                "features": [
                    {
                        "type": "LABEL_DETECTION",
                        "maxResults": 1
                    }
                ]
            }
        ]
    }
    
    try:
        logging.info("Testing Google Vision API connection")
        response = requests.post(url, json=payload, timeout=10)
        
        # Even with invalid image, a valid API key should return a 400 error, not 403
        if response.status_code == 400:
            print("SUCCESS: Google API key is valid")
            logging.info("Google API key validation successful")
            return True
        elif response.status_code == 403:
            print(f"ERROR: Authentication failed with status code {response.status_code}")
            print(f"Response: {response.text}")
            logging.error(f"Google API authentication failed: {response.status_code} - {response.text}")
            return False
        else:
            print(f"WARNING: Unexpected status code {response.status_code}")
            print(f"Response: {response.text}")
            logging.warning(f"Unexpected Google API response: {response.status_code} - {response.text}")
            return True  # Assume key is valid but other issues exist
            
    except Exception as e:
        print(f"ERROR: Failed to connect to Google API: {str(e)}")
        logging.error(f"Failed to connect to Google API: {str(e)}")
        return False

def test_openai_api():
    """
    Test OpenAI API key by checking models endpoint.
    
    Returns:
        bool: True if successful, False otherwise
    """
    print_header("Testing OpenAI API")
    
    if not OPENAI_API_KEY:
        print("ERROR: OpenAI API key (OPENAI_API_KEY) not found in .env file")
        logging.error("OpenAI API key not found in environment variables")
        return False
    
    headers = {
        "Authorization": f"Bearer {OPENAI_API_KEY}",
        "Content-Type": "application/json"
    }
    url = "https://api.openai.com/v1/models"
    
    try:
        logging.info("Testing OpenAI API connection")
        response = requests.get(url, headers=headers, timeout=10)
        
        if response.status_code == 200:
            print("SUCCESS: OpenAI API key is valid")
            logging.info("OpenAI API key validation successful")
            return True
        else:
            print(f"ERROR: Authentication failed with status code {response.status_code}")
            print(f"Response: {response.text}")
            logging.error(f"OpenAI API authentication failed: {response.status_code} - {response.text}")
            return False
            
    except Exception as e:
        print(f"ERROR: Failed to connect to OpenAI API: {str(e)}")
        logging.error(f"Failed to connect to OpenAI API: {str(e)}")
        return False

def main():
    """Run all API key tests and summarize results."""
    log_file = setup_logging()
    logging.info("Starting API key validation tests")
    
    print("\nTesting API keys for image captioning services...")
    
    # Test all API keys
    replicate_valid = test_replicate_api()
    google_valid = test_google_api()
    openai_valid = test_openai_api()
    
    # Summarize results
    print_header("Summary")
    print(f"Replicate API: {'VALID' if replicate_valid else 'INVALID'}")
    print(f"Google API:    {'VALID' if google_valid else 'INVALID'}")
    print(f"OpenAI API:    {'VALID' if openai_valid else 'INVALID'}")
    
    # Log summary
    logging.info(f"API key validation complete - Replicate: {replicate_valid}, Google: {google_valid}, OpenAI: {openai_valid}")
    logging.info(f"Log file: {log_file}")
    
    # Determine if evaluation can proceed
    all_valid = replicate_valid and google_valid and openai_valid
    
    if all_valid:
        print("\nAll API keys are valid. You can proceed with the evaluation.")
        logging.info("All API keys are valid")
    else:
        print("\nWARNING: One or more API keys are missing or invalid.")
        print("Please check your .env file and ensure all required API keys are set.")
        logging.warning("One or more API keys are invalid")
    
    return all_valid

if __name__ == "__main__":
    main()
