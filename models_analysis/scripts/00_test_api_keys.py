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
    """Test ElevenLabs API with latest models (including v3)"""
    try:
        import requests
        
        api_key = os.getenv('ELEVENLABS_API_KEY')
        if not api_key:
            return "SKIPPED", "API key not found in environment (optional)"
        
        # Test voices endpoint first
        headers = {"xi-api-key": api_key}
        response = requests.get("https://api.elevenlabs.io/v1/voices", headers=headers, timeout=10)
        
        if response.status_code == 200:
            voices = response.json()
            voice_count = len(voices.get('voices', []))
            
            # Find child-friendly voices
            child_friendly_voices = []
            if voices.get('voices'):
                for voice in voices['voices']:
                    voice_name = voice.get('name', '').lower()
                    if any(name in voice_name for name in ['bella', 'elli', 'domi', 'rachel']):
                        child_friendly_voices.append(voice.get('name', 'Unknown'))
            
            # Test latest models (2025)
            test_models = [
                'eleven_multilingual_v2',  # Established model
                'eleven_flash_v2_5',       # Fast model
                'eleven_turbo_v2_5',       # Real-time model
                'eleven_v3',               # NEW: Most expressive model (June 2025)
            ]
            
            working_models = []
            for model in test_models:
                try:
                    # Use first available voice for testing
                    if voices.get('voices'):
                        voice_id = voices['voices'][0]['voice_id']
                        test_url = f"https://api.elevenlabs.io/v1/text-to-speech/{voice_id}"
                        test_data = {
                            "text": "Hello test",
                            "model_id": model,
                            "voice_settings": {
                                "stability": 0.5,
                                "similarity_boost": 0.8
                            }
                        }
                        
                        test_response = requests.post(test_url, json=test_data, headers=headers, timeout=10)
                        if test_response.status_code in [200, 400, 422]:  # 400/422 might be quota but model exists
                            working_models.append(model)
                except:
                    pass  # Model not available
            
            status_msg = f"Connected successfully. {voice_count} voices available"
            if child_friendly_voices:
                status_msg += f". Child-friendly voices: {', '.join(child_friendly_voices[:3])}"
            if working_models:
                status_msg += f". Models: {', '.join(working_models)}"
            else:
                status_msg += ". Models: v2 models only"
            
            return "SUCCESS", status_msg
        elif response.status_code == 401:
            return "FAILED", "Invalid API key"
        elif response.status_code == 429:
            return "FAILED", "Rate limit exceeded - try again later"
        else:
            return "FAILED", f"API error: HTTP {response.status_code}"
            
    except ImportError:
        return "FAILED", "Requests library not installed"
    except Exception as e:
        return "FAILED", f"API error: {str(e)[:100]}..."

def test_openai_tts():
    """Test OpenAI TTS API with latest models and child-friendly voices"""
    try:
        from openai import OpenAI
        
        api_key = os.getenv('OPENAI_API_KEY')
        if not api_key:
            return "SKIPPED", "API key not found in environment"
        
        client = OpenAI(api_key=api_key)
        
        # Test both TTS models with 2025 pricing
        test_models = [
            ('tts-1', '$15/M chars'),      # Standard quality
            ('tts-1-hd', '$30/M chars')    # HD quality - better for production
        ]
        
        # Child-friendly voices based on 2025 research
        child_friendly_voices = ['fable', 'nova', 'shimmer']  # Softer, warmer voices
        all_voices = ['alloy', 'echo', 'fable', 'onyx', 'nova', 'shimmer']
        
        working_models = []
        for model, pricing in test_models:
            try:
                # Quick test with child-friendly voice
                response = client.audio.speech.create(
                    model=model,
                    voice="fable",  # Best for children's stories
                    input="Test message for children's story narration"
                )
                
                # Check if response is valid audio
                audio_data = response.content
                if len(audio_data) > 1000:  # Valid audio should be at least 1KB
                    working_models.append(f"{model} ({pricing})")
                    break  # Don't waste quota testing both
                    
            except Exception as e:
                if "model" in str(e).lower() or "not found" in str(e).lower():
                    continue
                else:
                    break
        
        if working_models:
            return "SUCCESS", f"Connected successfully. Models: {', '.join(working_models)}. Child-friendly voices: {', '.join(child_friendly_voices)}"
        else:
            return "FAILED", "No TTS models accessible"
        
    except ImportError:
        return "FAILED", "OpenAI library not installed (pip install openai)"
    except Exception as e:
        return "FAILED", f"API error: {str(e)[:100]}..."

def test_deepseek():
    """Test DeepSeek API with latest models (2025)"""
    try:
        import requests
        
        api_key = os.getenv('DEEPSEEK_API_KEY')
        if not api_key:
            return "SKIPPED", "API key not found in environment (optional)"
        
        # Test DeepSeek API endpoint
        url = "https://api.deepseek.com/v1/chat/completions"
        
        headers = {
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json"
        }
        
        # Test both current DeepSeek models (2025)
        test_models = [
            ("deepseek-chat", "DeepSeek-V3-0324 - Chat model"),
            ("deepseek-reasoner", "DeepSeek-R1-0528 - Reasoning model")
        ]
        
        working_models = []
        
        for model_name, description in test_models:
            try:
                data = {
                    "model": model_name,
                    "messages": [{"role": "user", "content": "Write one sentence about a friendly robot."}],
                    "max_tokens": 20,
                    "temperature": 0.1
                }
                
                response = requests.post(url, json=data, headers=headers, timeout=30)
                
                if response.status_code == 200:
                    response_data = response.json()
                    if 'choices' in response_data and response_data['choices']:
                        content = response_data['choices'][0].get('message', {}).get('content', '')
                        if content.strip():
                            working_models.append(f"{model_name} ({description.split(' - ')[1]})")
                        
            except Exception as model_error:
                # Continue testing other models even if one fails
                continue
        
        if working_models:
            return "SUCCESS", f"Connected successfully. Working models: {', '.join(working_models)}"
        else:
            # Try simple connectivity test if model tests fail
            simple_data = {
                "model": "deepseek-chat",
                "messages": [{"role": "user", "content": "Hi"}],
                "max_tokens": 5
            }
            
            response = requests.post(url, json=simple_data, headers=headers, timeout=15)
            
            if response.status_code == 200:
                return "SUCCESS", "Connected (basic test) - deepseek-chat available"
            elif response.status_code == 401:
                return "FAILED", "Invalid API key"
            elif response.status_code == 429:
                return "FAILED", "Rate limit exceeded - try again later"
            elif response.status_code == 402:
                return "FAILED", "Insufficient credits - add funds to DeepSeek account"
            else:
                return "FAILED", f"API error: HTTP {response.status_code} - {response.text[:100]}"
            
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
        
        # Test with Google AI API key (unified approach for 2025)
        url = f"https://texttospeech.googleapis.com/v1/voices?key={api_key}"
        response = requests.get(url, timeout=10)
        
        if response.status_code == 200:
            voices = response.json()
            all_voices = voices.get('voices', [])
            
            # Filter for English Neural2 voices (best quality in 2025)
            english_voices = [v for v in all_voices if v.get('languageCodes', []) and any(lang.startswith('en-') for lang in v.get('languageCodes', []))]
            neural2_voices = [v for v in english_voices if 'Neural2' in v.get('name', '')]
            
            # Child-friendly voices from 2025 research
            child_friendly = []
            for voice in neural2_voices:
                voice_name = voice.get('name', '')
                if any(name in voice_name for name in ['Neural2-H', 'Neural2-F', 'Neural2-J']):
                    child_friendly.append(voice_name)
            
            status_msg = f"Connected with Google AI API key. {len(all_voices)} total voices, {len(neural2_voices)} Neural2 voices"
            if child_friendly:
                status_msg += f". Child-friendly: {', '.join(child_friendly[:3])}"
            
            return "SUCCESS", status_msg
            
        elif response.status_code == 403:
            return "FAILED", "API key lacks TTS permissions. Enable Cloud TTS API in Google Cloud Console"
        elif response.status_code == 401:
            return "FAILED", "Invalid API key"
        else:
            return "FAILED", f"API error: HTTP {response.status_code}"
        
    except ImportError:
        return "FAILED", "Requests library not installed"
    except Exception as e:
        return "FAILED", f"API error: {str(e)[:100]}..."

def test_azure_tts():
    """Test Azure Cognitive Services Speech API"""
    try:
        import requests
        
        api_key = os.getenv('AZURE_SPEECH_KEY')
        region = os.getenv('AZURE_SPEECH_REGION', 'eastus')
        
        if not api_key:
            return "SKIPPED", "AZURE_SPEECH_KEY not found in environment (optional)"
        
        # Test voices endpoint
        url = f"https://{region}.tts.speech.microsoft.com/cognitiveservices/voices/list"
        headers = {
            'Ocp-Apim-Subscription-Key': api_key
        }
        
        response = requests.get(url, headers=headers, timeout=10)
        
        if response.status_code == 200:
            voices = response.json()
            voice_count = len(voices)
            
            # Find child-friendly voices
            child_voices = []
            neural_voices = []
            
            for voice in voices:
                voice_name = voice.get('ShortName', '')
                locale = voice.get('Locale', '')
                
                # Focus on English voices
                if locale.startswith('en-'):
                    if 'Neural' in voice_name:
                        neural_voices.append(voice_name)
                    
                    # Child-friendly voices from 2025 research
                    if any(name in voice_name for name in ['Libby', 'Maisie', 'Aria', 'Jenny']):
                        child_voices.append(voice_name)
            
            status_msg = f"Connected successfully. {voice_count} total voices, {len(neural_voices)} neural voices"
            if child_voices:
                status_msg += f". Child-friendly: {', '.join(child_voices[:3])}"
            
            return "SUCCESS", status_msg
            
        elif response.status_code == 401:
            return "FAILED", "Invalid API key"
        elif response.status_code == 403:
            return "FAILED", "Access denied - check API key permissions"
        else:
            return "FAILED", f"API error: HTTP {response.status_code}"
        
    except ImportError:
        return "FAILED", "Requests library not installed"
    except Exception as e:
        return "FAILED", f"API error: {str(e)[:100]}..."

def test_amazon_polly():
    """Test Amazon Polly Text-to-Speech"""
    try:
        import boto3
        
        aws_access_key = os.getenv('AWS_ACCESS_KEY_ID')
        aws_secret_key = os.getenv('AWS_SECRET_ACCESS_KEY')
        
        if not aws_access_key or not aws_secret_key:
            return "SKIPPED", "AWS credentials not found in environment (optional)"
        
        # Initialize Polly client
        polly = boto3.client(
            'polly',
            aws_access_key_id=aws_access_key,
            aws_secret_access_key=aws_secret_key,
            region_name='us-east-1'
        )
        
        # Test by listing voices
        response = polly.describe_voices()
        
        if 'Voices' in response:
            all_voices = response['Voices']
            
            # Filter for English neural voices
            english_voices = [v for v in all_voices if v.get('LanguageCode', '').startswith('en-')]
            neural_voices = [v for v in english_voices if v.get('SupportedEngines', []) and 'neural' in v.get('SupportedEngines', [])]
            
            # Child-friendly voices based on 2025 research
            child_friendly = []
            for voice in neural_voices:
                voice_name = voice.get('Id', '')
                if voice_name in ['Salli', 'Justin', 'Amy', 'Joanna']:
                    child_friendly.append(voice_name)
            
            status_msg = f"Connected successfully. {len(all_voices)} total voices, {len(neural_voices)} neural voices"
            if child_friendly:
                status_msg += f". Child-friendly: {', '.join(child_friendly)}"
            
            return "SUCCESS", status_msg
        else:
            return "FAILED", "Invalid response format"
        
    except ImportError:
        return "FAILED", "Boto3 library not installed (pip install boto3)"
    except Exception as e:
        error_msg = str(e)
        if "NoCredentialsError" in error_msg:
            return "FAILED", "AWS credentials not configured properly"
        elif "UnauthorizedOperation" in error_msg or "InvalidUserID" in error_msg:
            return "FAILED", "Invalid AWS credentials"
        else:
            return "FAILED", f"AWS error: {error_msg[:100]}..."

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

def test_mistral():
    """Test Mistral API with latest models"""
    try:
        import requests
        
        api_key = os.getenv('MISTRAL_API_KEY')
        if not api_key:
            return "SKIPPED", "API key not found in environment (optional)"
        
        # Test Mistral API endpoint
        url = "https://api.mistral.ai/v1/chat/completions"
        
        headers = {
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json"
        }
        
        # Test both current Mistral models (2025)
        test_models = [
            ("mistral-large-latest", "Latest large model"),
            ("mistral-small-latest", "Latest small model"),
            ("pixtral-12b-2409", "Vision-language model")
        ]
        
        working_models = []
        
        for model_name, description in test_models:
            try:
                data = {
                    "model": model_name,
                    "messages": [{"role": "user", "content": "Write one sentence about a friendly dragon for children."}],
                    "max_tokens": 50,
                    "temperature": 0.1
                }
                
                response = requests.post(url, json=data, headers=headers, timeout=30)
                
                if response.status_code == 200:
                    response_data = response.json()
                    if 'choices' in response_data and response_data['choices']:
                        content = response_data['choices'][0].get('message', {}).get('content', '')
                        if content.strip():
                            working_models.append(f"{model_name} ({description})")
                        
            except Exception as model_error:
                # Continue testing other models even if one fails
                continue
        
        if working_models:
            return "SUCCESS", f"Connected successfully. Working models: {', '.join(working_models)}"
        else:
            # Try simple connectivity test if model tests fail
            simple_data = {
                "model": "mistral-small-latest",
                "messages": [{"role": "user", "content": "Hi"}],
                "max_tokens": 5
            }
            
            response = requests.post(url, json=simple_data, headers=headers, timeout=15)
            
            if response.status_code == 200:
                return "SUCCESS", "Connected (basic test) - mistral-small-latest available"
            elif response.status_code == 401:
                return "FAILED", "Invalid API key"
            elif response.status_code == 429:
                return "FAILED", "Rate limit exceeded - try again later"
            elif response.status_code == 402:
                return "FAILED", "Insufficient credits - add funds to Mistral account"
            else:
                return "FAILED", f"API error: HTTP {response.status_code} - {response.text[:100]}"
        
    except ImportError:
        return "FAILED", "Requests library not installed"
    except Exception as e:
        return "FAILED", f"API error: {str(e)[:100]}..."

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
    
    # Test all APIs - organized by purpose
    tests = [
        # Core Story Generation APIs
        ("OpenAI GPT", test_openai, "Required for story generation"),
        ("Google Gemini", test_google, "Required for image captioning & stories"),
        ("List Gemini Models", list_available_gemini_models, "Shows available Gemini models"),
        ("Test Gemini Models", test_gemini_models, "Tests multiple Gemini models for story generation"),
        
        # TTS Providers for Audio Comparison (2025 Update)
        ("OpenAI TTS", test_openai_tts, "Primary TTS provider - best quality/cost balance"),
        ("Google Cloud TTS", test_google_cloud_tts, "Uses same Google AI API key as Gemini"),
        ("ElevenLabs TTS", test_elevenlabs, "Premium TTS with v3 model (most expressive)"),
        
        # Enterprise TTS Providers (Skipped - Account Validation Issues)
        # ("Azure TTS", test_azure_tts, "Requires enterprise account validation"),
        # ("Amazon Polly", test_amazon_polly, "AWS credential setup challenges"),
        
        # Optional/Alternative Providers
        ("DeepSeek", test_deepseek, "Cost-effective story generation alternative"),
        ("Replicate", test_replicate, "Optional for BLIP/LLaVA models"),
        ("Anthropic Claude", test_anthropic, "Optional high-quality story generation"),
        
        # Diagnostics
        ("Diagnose Gemini Issues", diagnose_gemini_api_issues, "Deep dive into Gemini API problems"),
        ("Mistral", test_mistral, "Optional high-quality story generation"),
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
                    if "TTS" in service_name:
                        cost_info = "Cost: $15-30/M chars"
                    else:
                        cost_info = "Cost: ~$0.001 per test"
                elif "Google" in service_name:
                    if "TTS" in service_name:
                        cost_info = "Cost: $16/M chars"
                    else:
                        cost_info = "Cost: ~$0.0001 per test"
                elif "Anthropic" in service_name:
                    cost_info = "Cost: ~$0.001 per test"
                elif "DeepSeek" in service_name:
                    cost_info = "Cost: $0.27/M input, $1.10/M output"
                elif "Mistral" in service_name:
                    cost_info = "Cost: $2/M input, $6/M output"
                # Enterprise providers removed due to account validation issues
                # elif "Azure TTS" in service_name:
                #     cost_info = "Cost: $30/M chars"
                # elif "Amazon Polly" in service_name:
                #     cost_info = "Cost: $16/M chars"
                elif "ElevenLabs" in service_name:
                    cost_info = "Cost: $22-330/month subscription"
                elif "Replicate" in service_name:
                    cost_info = "Cost: Free for API check"
            
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
    
    # TTS APIs check (excluding enterprise providers with account validation issues)
    tts_apis = ["OpenAI TTS", "Google Cloud TTS", "ElevenLabs TTS"]
    tts_working = sum(1 for api in tts_apis if results.get(api) == "SUCCESS")
    
    # Note: Azure and AWS TTS excluded due to account validation challenges for individual researchers
    
    print(f"\nRequired APIs working: {required_working}/{len(required_apis)}")
    print(f"TTS APIs working: {tts_working}/{len(tts_apis)}")
    
    if required_working == len(required_apis):
        print("✅ All required APIs are working! You can run the data collection scripts.")
        print("   Gemini models have been verified and are ready for story generation.")
    elif required_working >= 2:
        print("⚠️  Most required APIs are working. Check any failed APIs before proceeding.")
        if results.get("Test Gemini Models") == "SUCCESS":
            print("   Gemini models are working - story generation should work properly.")
    else:
        print("❌ Critical APIs are not working. Please check your API keys.")
        if results.get("Test Gemini Models") != "SUCCESS":
            print("   Gemini models failed - check model names in story generation script.")
    
    # TTS readiness assessment (adjusted for individual researcher constraints)
    if tts_working >= 2:
        print(f"✅ TTS Collection Ready: {tts_working} providers available for comparative analysis")
        working_tts = [api for api in tts_apis if results.get(api) == "SUCCESS"]
        print(f"   Working providers: {', '.join(working_tts)}")
        print("   📋 Note: Azure & AWS excluded due to account validation challenges")
    elif tts_working == 1:
        print("⚠️  TTS Limited: Only 1 provider working. Still viable for research with clear methodology notes.")
        print("   📋 Note: Enterprise providers (Azure/AWS) excluded due to access constraints")
    else:
        print("❌ TTS Not Ready: No TTS providers configured. Set up available API keys for TTS analysis.")
        print("   📋 Note: Focus on OpenAI & Google (accessible to individual researchers)")
    
    print("\nNext steps:")
    if required_working == len(required_apis):
        print("   1. ✅ Story Generation Ready")
        print("   2. Run: python 01_image_captioning_collect.py")
        print("   3. Run: python 02_story_generation_collect.py")
        if tts_working >= 2:
            print("   4. ✅ TTS Ready - Run: python 03_tts_collect.py")
        else:
            print("   4. ⚠️  Set up more TTS providers for better comparison")
    else:
        print("   1. Fix core API issues first")
        print("   2. Check model names in story generation script")
        print("   3. Re-run this test script")
        print("   4. Then run data collection scripts")
    
    print(f"\nCost estimate for full test suite: <$0.01")
    print("   Story generation collection: $20-50 depending on usage")
    print("   TTS collection: $2-5 for comprehensive comparison")
    
    # Show working providers summary
    if results.get("Test Gemini Models") == "SUCCESS":
        print("\n💡 TIP: Copy working model names from test output above")
        print("   and update the story_models list in 02_story_generation_collect.py")
    
    if tts_working >= 2:
        print("\n💡 TTS READY: Multiple providers configured for comparative analysis")
        print("   Your 03_tts_collect.py script will work with all available providers")
    elif tts_working == 1:
        print("\n💡 TTS PARTIAL: Consider adding more providers for richer comparison")
        print("   Recommended: OpenAI TTS (best balance) + Google TTS (reliable)")
    
    print(f"\n📊 RESEARCH IMPACT:")
    print(f"   Story Models: {len([api for api in required_apis if results.get(api) == 'SUCCESS'])} working")
    print(f"   TTS Providers: {tts_working} working")
    print(f"   Total Cost: <$55 for complete comparative analysis")

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