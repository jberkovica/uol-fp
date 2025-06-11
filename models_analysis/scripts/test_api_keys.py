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

def test_gemini_models():
    """Test multiple Gemini models to verify which ones are working"""
    try:
        import google.generativeai as genai
        
        api_key = os.getenv('GOOGLE_API_KEY')
        if not api_key:
            return "SKIPPED", "API key not found in environment"
        
        genai.configure(api_key=api_key)
        
        # Models to test - production-ready only (8 models total)
        test_models = [
            # OpenAI models (will test separately)
            # Anthropic models (will test separately)
            
            # Google stable models only - confirmed working
            "gemini-2.0-flash",
            "gemini-2.0-flash-lite", 
            "gemini-1.5-pro",
            "gemini-1.5-flash",
            
            # Preview models excluded due to safety filter issues
            # See SAFETY_FILTER_INVESTIGATION.md for details
            # "gemini-2.5-pro-preview-06-05",
            # "gemini-2.5-flash-preview-05-20",
        ]
        
        # Use the same prompt format as the main collection script
        simple_prompt = """Create a delightful family-friendly story inspired by this image description: "A friendly cat sitting peacefully in a beautiful garden with colorful flowers"

Story Guidelines:
- Write exactly 150-200 words (this is important!)
- Audience: young readers and families
- Theme: suitable for reading aloud at bedtime or story time
- Tone: warm, gentle, and comforting
- Include a positive message or gentle life lesson
- Use simple, accessible language
- End on a peaceful, happy note
- Add an engaging title

Format:
Title: [Imaginative Title]

[Your complete 150-200 word story]"""
        
        working_models = []
        failed_models = []
        
        print(f"\n   Testing {len(test_models)} Gemini models...")
        
        for model_name in test_models:
            try:
                # Configure safety settings - as permissive as possible
                safety_settings = [
                    {"category": "HARM_CATEGORY_HARASSMENT", "threshold": "BLOCK_NONE"},
                    {"category": "HARM_CATEGORY_HATE_SPEECH", "threshold": "BLOCK_NONE"},
                    {"category": "HARM_CATEGORY_SEXUALLY_EXPLICIT", "threshold": "BLOCK_NONE"},
                    {"category": "HARM_CATEGORY_DANGEROUS_CONTENT", "threshold": "BLOCK_NONE"}
                ]
                
                generation_config = {
                    "max_output_tokens": 400,  # Enough for full 150-200 word stories
                    "temperature": 0.7,
                    "candidate_count": 1,
                }
                
                # Create model instance
                model_instance = genai.GenerativeModel(
                    model_name=model_name,
                    generation_config=generation_config,
                    safety_settings=safety_settings
                )
                
                response = model_instance.generate_content(simple_prompt)
                
                # Extract response text
                if hasattr(response, 'candidates') and response.candidates:
                    candidate = response.candidates[0]
                    if hasattr(candidate, 'content') and candidate.content:
                        if hasattr(candidate.content, 'parts') and candidate.content.parts:
                            text = candidate.content.parts[0].text.strip()
                            working_models.append(model_name)
                            # Validate story quality
                            word_count = len(text.split())
                            has_title = 'Title:' in text or 'title:' in text.lower()
                            meets_length = 140 <= word_count <= 220
                            print(f"      SUCCESS {model_name} - Words: {word_count}, Title: {'Yes' if has_title else 'No'}, Length: {'Yes' if meets_length else 'No'}")
                            continue
                
                # Fallback for text attribute
                if hasattr(response, 'text'):
                    text = response.text.strip()
                    working_models.append(model_name)
                    # Validate story quality
                    word_count = len(text.split())
                    has_title = 'Title:' in text or 'title:' in text.lower()
                    meets_length = 140 <= word_count <= 220
                    print(f"      SUCCESS {model_name} - Words: {word_count}, Title: {'Yes' if has_title else 'No'}, Length: {'Yes' if meets_length else 'No'}")
                    continue
                
                failed_models.append((model_name, "No content in response"))
                print(f"      FAILED {model_name}: No content in response")
                
            except Exception as e:
                error_msg = str(e)[:50] + "..." if len(str(e)) > 50 else str(e)
                failed_models.append((model_name, error_msg))
                print(f"      FAILED {model_name}: {error_msg}")
        
        # Return summary
        if working_models:
            working_list = ", ".join(working_models)
            return "SUCCESS", f"Working models ({len(working_models)}/{len(test_models)}): {working_list}"
        else:
            failed_list = "; ".join([f"{name}: {error}" for name, error in failed_models])
            return "FAILED", f"No models working. Errors: {failed_list[:200]}..."
        
    except ImportError:
        return "FAILED", "Google Generative AI library not installed (pip install google-generativeai)"
    except Exception as e:
        return "FAILED", f"API error: {str(e)[:100]}..."

def list_available_gemini_models():
    """List all available Gemini models through the API"""
    try:
        import google.generativeai as genai
        
        api_key = os.getenv('GOOGLE_API_KEY')
        if not api_key:
            return "SKIPPED", "API key not found in environment"
        
        genai.configure(api_key=api_key)
        
        print("\n   Fetching available models from Gemini API...")
        models = list(genai.list_models())
        
        if models:
            print(f"   Found {len(models)} available models:")
            for model in models[:10]:  # Show first 10 to avoid clutter
                print(f"      - {model.name}")
                if hasattr(model, 'display_name'):
                    print(f"        Display: {model.display_name}")
            
            if len(models) > 10:
                print(f"      ... and {len(models) - 10} more models")
        
        return "SUCCESS", f"Listed {len(models)} available models"
        
    except Exception as e:
        return "FAILED", f"Error listing models: {str(e)[:100]}..."

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

def diagnose_gemini_api_issues():
    """Detailed diagnostic of Gemini API issues"""
    try:
        import google.generativeai as genai
        
        api_key = os.getenv('GOOGLE_API_KEY')
        if not api_key:
            return "SKIPPED", "API key not found in environment"
        
        genai.configure(api_key=api_key)
        
        print("\n   DETAILED GEMINI API DIAGNOSTIC")
        print("   " + "="*50)
        
        # Test models with detailed error reporting
        test_cases = [
            ("gemini-2.0-flash", "Should work (verified)"),
            ("gemini-2.5-pro-preview-06-05", "Failing - let's see why"),
            ("gemini-2.5-flash-preview-05-20", "Failing - let's see why"),
            ("models/gemini-2.5-pro-preview-06-05", "Try with models/ prefix"),
            ("models/gemini-2.5-flash-preview-05-20", "Try with models/ prefix"),
        ]
        
        simple_prompt = "Hello, write one sentence."
        
        for model_name, description in test_cases:
            print(f"\n   Testing: {model_name}")
            print(f"   Purpose: {description}")
            
            try:
                # Minimal configuration to isolate issues
                model_instance = genai.GenerativeModel(model_name)
                
                print(f"   Model instance created successfully")
                
                # Try to generate content
                response = model_instance.generate_content(simple_prompt)
                
                print(f"   Response received")
                print(f"   Response type: {type(response)}")
                print(f"   Response attributes: {dir(response)}")
                
                # Check response structure in detail
                if hasattr(response, 'candidates'):
                    print(f"   Has candidates: {len(response.candidates) if response.candidates else 0}")
                    if response.candidates:
                        candidate = response.candidates[0]
                        print(f"   Candidate type: {type(candidate)}")
                        print(f"   Candidate attributes: {dir(candidate)}")
                        
                        if hasattr(candidate, 'content'):
                            print(f"   Has content: {candidate.content is not None}")
                            if candidate.content:
                                print(f"   Content type: {type(candidate.content)}")
                                print(f"   Content attributes: {dir(candidate.content)}")
                                
                                if hasattr(candidate.content, 'parts'):
                                    print(f"   Has parts: {len(candidate.content.parts) if candidate.content.parts else 0}")
                                    if candidate.content.parts:
                                        part = candidate.content.parts[0]
                                        print(f"   Part type: {type(part)}")
                                        print(f"   Part attributes: {dir(part)}")
                                        
                                        if hasattr(part, 'text'):
                                            print(f"   Part has text: '{part.text[:50]}...'")
                                        else:
                                            print(f"   Part has no text attribute")
                        
                        if hasattr(candidate, 'finish_reason'):
                            print(f"   Finish reason: {candidate.finish_reason}")
                
                # Try different ways to access text
                try:
                    text_via_text = response.text
                    print(f"   response.text works: '{text_via_text[:50]}...'")
                except Exception as text_error:
                    print(f"   response.text fails: {str(text_error)}")
                
                # Try parts access
                try:
                    if response.candidates and response.candidates[0].content and response.candidates[0].content.parts:
                        text_via_parts = response.candidates[0].content.parts[0].text
                        print(f"   Parts access works: '{text_via_parts[:50]}...'")
                    else:
                        print(f"   No parts to access")
                except Exception as parts_error:
                    print(f"   Parts access fails: {str(parts_error)}")
                
                print(f"   {model_name} - SUCCESS")
                
            except Exception as e:
                print(f"   {model_name} - FAILED")
                print(f"   Error type: {type(e).__name__}")
                print(f"   Full error: {str(e)}")
                print(f"   Error details: {repr(e)}")
                
                # Check if it's a model availability issue
                if "not found" in str(e).lower() or "invalid" in str(e).lower():
                    print(f"   Likely cause: Model not available or wrong name")
                elif "permission" in str(e).lower() or "access" in str(e).lower():
                    print(f"   Likely cause: API access permissions")
                elif "quota" in str(e).lower() or "limit" in str(e).lower():
                    print(f"   Likely cause: API quota/rate limits")
                else:
                    print(f"   Likely cause: Unknown API issue")
        
        # Also check what models are actually available
        print(f"\n   AVAILABLE MODELS CONTAINING '2.5':")
        try:
            models = list(genai.list_models())
            gemini_25_models = [m for m in models if '2.5' in m.name or '2.5' in getattr(m, 'display_name', '')]
            
            if gemini_25_models:
                for model in gemini_25_models:
                    print(f"   - {model.name}")
                    if hasattr(model, 'display_name'):
                        print(f"     Display: {model.display_name}")
            else:
                print(f"   No models containing '2.5' found")
                
                # Show a few recent models
                recent_models = [m for m in models if 'gemini' in m.name.lower()][-10:]
                print(f"   RECENT GEMINI MODELS:")
                for model in recent_models:
                    print(f"   - {model.name}")
                    
        except Exception as list_error:
            print(f"   Could not list models: {str(list_error)}")
        
        return "SUCCESS", "Detailed diagnostic completed - check output above"
        
    except ImportError:
        return "FAILED", "Google Generative AI library not installed"
    except Exception as e:
        return "FAILED", f"Diagnostic error: {str(e)}"

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
        ("List Gemini Models", list_available_gemini_models, "Shows available Gemini models"),
        ("Test Gemini Models", test_gemini_models, "Tests multiple Gemini models for story generation"),
        ("Google Cloud TTS", test_google_cloud_tts, "Uses same Google AI API key as Gemini"),
        ("Replicate", test_replicate, "Optional for BLIP/LLaVA models"),
        ("Anthropic Claude", test_anthropic, "Optional for story generation"),
        ("ElevenLabs TTS", test_elevenlabs, "Optional for TTS evaluation"),
        ("Diagnose Gemini Issues", diagnose_gemini_api_issues, "Deep dive into Gemini API problems"),
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
    required_apis = ["OpenAI GPT", "Google Gemini", "Test Gemini Models"]
    required_working = sum(1 for api in required_apis if results.get(api) == "SUCCESS")
    
    print(f"\nRequired APIs working: {required_working}/{len(required_apis)}")
    
    if required_working == len(required_apis):
        print("All required APIs are working! You can run the data collection scripts.")
        print("   Gemini models have been verified and are ready for story generation.")
    elif required_working >= 2:
        print("Most required APIs are working. Check any failed APIs before proceeding.")
        if results.get("Test Gemini Models") == "SUCCESS":
            print("   Gemini models are working - story generation should work properly.")
    else:
        print("Critical APIs are not working. Please check your API keys.")
        if results.get("Test Gemini Models") != "SUCCESS":
            print("   Gemini models failed - check model names in story generation script.")
    
    print("\nNext steps:")
    if results.get("Test Gemini Models") == "SUCCESS":
        print("   1. Gemini models tested - update story generation script with working models")
        print("   2. Run: python 01_image_captioning_collect.py")
        print("   3. Run: python 02_story_generation_collect.py")
    else:
        print("   1. Fix Gemini model issues first")
        print("   2. Check model names in 02_story_generation_collect.py")
        print("   3. Re-run this test script")
        print("   4. Then run data collection scripts")
    
    print("\nCost estimate for full test suite: <$0.01")
    print("   (Actual data collection will cost $20-50 depending on usage)")
    
    # Show working Gemini models if any
    if results.get("Test Gemini Models") == "SUCCESS":
            print("\nTIP: Copy working model names from test output above")
    print("   and update the story_models list in 02_story_generation_collect.py")

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