#!/usr/bin/env python3
"""
API Keys Test Script for MIRA Models Analysis
Tests all configured API keys to ensure they're working properly
Run this before executing the main data collection scripts
"""

import os
import sys
from pathlib import Path
from dotenv import load_dotenv
import time

# Load environment variables
load_dotenv()

def print_header():
    """Print script header"""
    print("=" * 60)
    print("MIRA API Keys Test Script")
    print("=" * 60)
    print("Testing all configured API keys...\n")

def print_result(service_name: str, status: str, message: str, cost_info: str = ""):
    """Print formatted test result"""
    status_symbol = "[OK]" if status == "SUCCESS" else "[FAIL]" if status == "FAILED" else "[SKIP]"
    print(f"{status_symbol} {service_name:<20} | {status:<8} | {message}")
    if cost_info:
        print(f"   Cost: {cost_info}")
    print()

def test_openai():
    """Test OpenAI API"""
    try:
        from openai import OpenAI
        
        api_key = os.getenv('OPENAI_API_KEY')
        if not api_key:
            return "SKIPPED", "API key not found in environment"
        
        client = OpenAI(api_key=api_key)
        
        # Simple test request
        response = client.chat.completions.create(
            model="gpt-4o-mini",  # Use cheaper model for testing
            messages=[{"role": "user", "content": "Hello! This is a test."}],
            max_tokens=5
        )
        
        return "SUCCESS", f"Connected successfully. Model: gpt-4o-mini"
        
    except ImportError:
        return "FAILED", "OpenAI library not installed (pip install openai)"
    except Exception as e:
        return "FAILED", f"API error: {str(e)[:100]}..."

def test_anthropic():
    """Test Anthropic Claude API"""
    try:
        import anthropic
        
        api_key = os.getenv('CLAUDE_API_KEY')
        if not api_key:
            return "SKIPPED", "API key not found in environment"
        
        client = anthropic.Anthropic(api_key=api_key)
        
        # Simple test request
        response = client.messages.create(
            model="claude-3-5-haiku-20241022",  # Use cheaper model for testing
            max_tokens=5,
            messages=[{"role": "user", "content": "Hello! This is a test."}]
        )
        
        return "SUCCESS", f"Connected successfully. Model: claude-3-5-haiku"
        
    except ImportError:
        return "FAILED", "Anthropic library not installed (pip install anthropic)"
    except Exception as e:
        return "FAILED", f"API error: {str(e)[:100]}..."

def test_google():
    """Test Google Gemini API"""
    try:
        import google.generativeai as genai
        
        api_key = os.getenv('GOOGLE_API_KEY')
        if not api_key:
            return "SKIPPED", "API key not found in environment"
        
        genai.configure(api_key=api_key)
        model = genai.GenerativeModel('gemini-2.0-flash')
        
        # Simple test request
        response = model.generate_content(
            "Hello! This is a test.",
            generation_config=genai.types.GenerationConfig(max_output_tokens=5)
        )
        
        return "SUCCESS", f"Connected successfully. Model: gemini-2.0-flash"
        
    except ImportError:
        return "FAILED", "Google Generative AI library not installed (pip install google-generativeai)"
    except Exception as e:
        return "FAILED", f"API error: {str(e)[:100]}..."

def test_replicate():
    """Test Replicate API"""
    try:
        import replicate
        
        api_token = os.getenv('REPLICATE_API_TOKEN')
        if not api_token:
            return "SKIPPED", "API token not found in environment"
        
        # Test with a simple model list call
        client = replicate.Client(api_token=api_token)
        
        # This is a lightweight test that doesn't cost money
        models = list(client.models.list())
        
        return "SUCCESS", f"Connected successfully. Access to {len(models)} models"
        
    except ImportError:
        return "FAILED", "Replicate library not installed (pip install replicate)"
    except Exception as e:
        return "FAILED", f"API error: {str(e)[:100]}..."

def test_elevenlabs():
    """Test ElevenLabs API (optional)"""
    try:
        import requests
        
        api_key = os.getenv('ELEVENLABS_API_KEY')
        if not api_key:
            return "SKIPPED", "API key not found in environment (optional)"
        
        # Test voices endpoint
        headers = {"xi-api-key": api_key}
        response = requests.get("https://api.elevenlabs.io/v1/voices", headers=headers)
        
        if response.status_code == 200:
            voices = response.json()
            return "SUCCESS", f"Connected successfully. {len(voices.get('voices', []))} voices available"
        else:
            return "FAILED", f"API error: HTTP {response.status_code}"
            
    except ImportError:
        return "FAILED", "Requests library not installed"
    except Exception as e:
        return "FAILED", f"API error: {str(e)[:100]}..."

def test_google_cloud_tts():
    """Test Google Cloud Text-to-Speech API using Google AI API key"""
    try:
        import requests
        
        # Use the same Google AI API key for TTS
        api_key = os.getenv('GOOGLE_API_KEY')
        
        if not api_key:
            return "SKIPPED", "GOOGLE_API_KEY not found (will use same key as Gemini)"
        
        # Test with Google AI API key (unified approach)
        url = f"https://texttospeech.googleapis.com/v1/voices?key={api_key}"
        response = requests.get(url)
        
        if response.status_code == 200:
            voices = response.json()
            voice_count = len(voices.get('voices', []))
            return "SUCCESS", f"Connected with Google AI API key. {voice_count} voices available"
        elif response.status_code == 403:
            return "FAILED", "API key lacks TTS permissions. Enable Cloud TTS API in Google Cloud Console"
        else:
            return "FAILED", f"API error: HTTP {response.status_code}"
        
    except ImportError:
        return "FAILED", "Requests library not installed"
    except Exception as e:
        return "FAILED", f"API error: {str(e)[:100]}..."

def check_environment_file():
    """Check if .env file exists"""
    env_paths = [
        Path.cwd() / '.env',
        Path(__file__).parent / '.env',
        Path(__file__).parent.parent / '.env'
    ]
    
    for path in env_paths:
        if path.exists():
            return f"Found .env file at: {path}"
    
    return "No .env file found. Please create one from the template."

def main():
    """Main test function"""
    print_header()
    
    # Check environment file
    env_status = check_environment_file()
    print(f"Environment: {env_status}\n")
    
    if "No .env file found" in env_status:
        print("Please create a .env file with your API keys before running tests.")
        print("   Copy environment_template.txt to .env and add your keys.")
        sys.exit(1)
    
    # Test all APIs
    tests = [
        ("OpenAI GPT", test_openai, "Required for story generation"),
        ("Google Gemini", test_google, "Required for image captioning & stories"),
        ("Google Cloud TTS", test_google_cloud_tts, "Uses same Google AI API key as Gemini"),
        ("Replicate", test_replicate, "Optional for BLIP/LLaVA models"),
        ("Anthropic Claude", test_anthropic, "Optional for story generation"),
        ("ElevenLabs TTS", test_elevenlabs, "Optional for TTS evaluation"),
    ]
    
    results = {}
    total_cost_estimate = 0.0
    
    for service_name, test_func, description in tests:
        print(f"Testing {service_name}...")
        try:
            status, message = test_func()
            results[service_name] = status
            
            # Add cost info for successful tests
            cost_info = ""
            if status == "SUCCESS":
                if "OpenAI" in service_name:
                    cost_info = "Cost: ~$0.001 per test"
                elif "Google" in service_name:
                    cost_info = "Cost: ~$0.0001 per test"
                elif "Anthropic" in service_name:
                    cost_info = "Cost: ~$0.001 per test"
                elif "Replicate" in service_name:
                    cost_info = "Cost: Free for API check"
                elif "ElevenLabs" in service_name:
                    cost_info = "Cost: Free for voice list"
            
            print_result(service_name, status, message, cost_info)
            
        except Exception as e:
            results[service_name] = "ERROR"
            print_result(service_name, "ERROR", f"Unexpected error: {str(e)[:50]}...")
        
        time.sleep(1)  # Rate limiting
    
    # Summary
    print("=" * 60)
    print("SUMMARY")
    print("=" * 60)
    
    successful = sum(1 for status in results.values() if status == "SUCCESS")
    failed = sum(1 for status in results.values() if status == "FAILED")
    skipped = sum(1 for status in results.values() if status == "SKIPPED")
    
    print(f"Successful: {successful}")
    print(f"Failed: {failed}")
    print(f"Skipped: {skipped}")
    
    # Required APIs check
    required_apis = ["OpenAI GPT", "Google Gemini"]
    required_working = sum(1 for api in required_apis if results.get(api) == "SUCCESS")
    
    print(f"\nRequired APIs working: {required_working}/{len(required_apis)}")
    
    if required_working == len(required_apis):
        print("All required APIs are working! You can run the data collection scripts.")
    elif required_working > 0:
        print("Some required APIs are working. Check failed APIs before proceeding.")
    else:
        print("No required APIs are working. Please check your API keys.")
    
    print("\nNext steps:")
    print("   1. Fix any failed API keys")
    print("   2. Run: python 01_image_captioning_collect.py")
    print("   3. Run: python 02_story_generation_collect.py")
    
    print("\nCost estimate for full test suite: <$0.01")
    print("   (Actual data collection will cost $20-50 depending on usage)")

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\nTest interrupted by user")
    except Exception as e:
        print(f"\nFatal error: {str(e)}")
        sys.exit(1)
    else:
        print("\nAPI key testing completed!") 