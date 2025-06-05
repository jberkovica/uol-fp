#!/usr/bin/env python3
"""
Text-to-Speech Models Evaluation Script
Tests various TTS providers for generating child-friendly story narrations
"""

import os
import time
import csv
import json
from pathlib import Path
from datetime import datetime
from dotenv import load_dotenv
import signal
from contextlib import contextmanager
from cost_calculator import CostCalculator, format_cost
import requests
import base64
import tempfile

# Load environment variables
load_dotenv()

# Timeout handler
class TimeoutException(Exception):
    pass

@contextmanager
def timeout(seconds):
    def handler(signum, frame):
        raise TimeoutException(f"Function call timed out after {seconds} seconds")
    
    old_handler = signal.signal(signal.SIGALRM, handler)
    signal.alarm(seconds)
    try:
        yield
    finally:
        signal.signal(signal.SIGALRM, old_handler)
        signal.alarm(0)

# TTS Provider configurations
TTS_PROVIDERS = {
    'elevenlabs_multilingual': {
        'api_key_env': 'ELEVENLABS_API_KEY',
        'model': 'eleven_multilingual_v2',
        'voice_id': 'pNInz6obpgDQGcFmaJgB',  # Child-friendly voice
        'timeout': 30
    },
    'elevenlabs_flash': {
        'api_key_env': 'ELEVENLABS_API_KEY', 
        'model': 'eleven_flash_v2_5',
        'voice_id': 'pNInz6obpgDQGcFmaJgB',  # Same voice, different model
        'timeout': 20
    },
    'openai_tts': {
        'api_key_env': 'OPENAI_API_KEY',
        'model': 'tts-1',
        'voice': 'nova',  # Child-friendly voice
        'timeout': 25
    },
    'google_tts_2.5_flash': {
        'api_key_env': 'GOOGLE_API_KEY',
        'model': 'gemini-2.5-flash-preview-tts',
        'voice': 'male-1',  # Child-friendly voice
        'timeout': 30
    }
}

def test_elevenlabs_tts(story_text, provider_config, provider_name):
    """Test ElevenLabs TTS API"""
    api_key = os.getenv(provider_config['api_key_env'])
    if not api_key:
        return None, 0, 0, f"Missing API key for {provider_name}"
    
    start_time = time.time()
    
    url = f"https://api.elevenlabs.io/v1/text-to-speech/{provider_config['voice_id']}"
    
    headers = {
        "Accept": "audio/mpeg",
        "Content-Type": "application/json",
        "xi-api-key": api_key
    }
    
    data = {
        "text": story_text,
        "model_id": provider_config['model'],
        "voice_settings": {
            "stability": 0.5,
            "similarity_boost": 0.75,
            "style": 0.5,
            "use_speaker_boost": True
        }
    }
    
    try:
        with timeout(provider_config['timeout']):
            response = requests.post(url, json=data, headers=headers)
            
            if response.status_code == 200:
                # Save audio file temporarily to check duration
                with tempfile.NamedTemporaryFile(suffix='.mp3', delete=False) as tmp_file:
                    tmp_file.write(response.content)
                    audio_file_path = tmp_file.name
                
                execution_time = time.time() - start_time
                
                # Calculate cost based on character count
                char_count = len(story_text)
                if 'flash' in provider_name:
                    cost = CostCalculator.calculate_tts_cost(story_text, 'elevenlabs_flash')
                else:
                    cost = CostCalculator.calculate_tts_cost(story_text, 'elevenlabs_multilingual')
                
                # Clean up temp file
                os.unlink(audio_file_path)
                
                return "Audio generated successfully", execution_time, cost, None
            else:
                execution_time = time.time() - start_time
                return None, execution_time, 0, f"API error: {response.status_code} - {response.text[:200]}"
                
    except TimeoutException:
        return None, provider_config['timeout'], 0, f"Request timed out after {provider_config['timeout']} seconds"
    except Exception as e:
        execution_time = time.time() - start_time
        return None, execution_time, 0, f"Error: {str(e)}"

def test_openai_tts(story_text, provider_config, provider_name):
    """Test OpenAI TTS API"""
    api_key = os.getenv(provider_config['api_key_env'])
    if not api_key:
        return None, 0, 0, f"Missing API key for {provider_name}"
    
    start_time = time.time()
    
    url = "https://api.openai.com/v1/audio/speech"
    
    headers = {
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json"
    }
    
    data = {
        "model": provider_config['model'],
        "input": story_text,
        "voice": provider_config['voice'],
        "response_format": "mp3"
    }
    
    try:
        with timeout(provider_config['timeout']):
            response = requests.post(url, json=data, headers=headers)
            
            if response.status_code == 200:
                execution_time = time.time() - start_time
                
                # Calculate cost
                cost = CostCalculator.calculate_tts_cost(story_text, 'openai_tts')
                
                return "Audio generated successfully", execution_time, cost, None
            else:
                execution_time = time.time() - start_time
                return None, execution_time, 0, f"API error: {response.status_code} - {response.text[:200]}"
                
    except TimeoutException:
        return None, provider_config['timeout'], 0, f"Request timed out after {provider_config['timeout']} seconds"
    except Exception as e:
        execution_time = time.time() - start_time
        return None, execution_time, 0, f"Error: {str(e)}"

def test_google_tts(story_text, provider_config, provider_name):
    """Test Google Gemini TTS API"""
    api_key = os.getenv(provider_config['api_key_env'])
    if not api_key:
        return None, 0, 0, f"Missing API key for {provider_name}"
    
    start_time = time.time()
    
    url = f"https://generativelanguage.googleapis.com/v1beta/models/{provider_config['model']}:generateContent?key={api_key}"
    
    headers = {
        "Content-Type": "application/json"
    }
    
    data = {
        "contents": [{
            "parts": [{
                "text": f"Convert this story to speech: {story_text}"
            }]
        }],
        "generationConfig": {
            "voice": provider_config['voice'],
            "audioFormat": "MP3"
        }
    }
    
    try:
        with timeout(provider_config['timeout']):
            response = requests.post(url, json=data, headers=headers)
            
            if response.status_code == 200:
                execution_time = time.time() - start_time
                
                # Calculate cost
                cost = CostCalculator.calculate_tts_cost(story_text, 'google_tts_2.5_flash')
                
                return "Audio generated successfully", execution_time, cost, None
            else:
                execution_time = time.time() - start_time
                return None, execution_time, 0, f"API error: {response.status_code} - {response.text[:200]}"
                
    except TimeoutException:
        return None, provider_config['timeout'], 0, f"Request timed out after {provider_config['timeout']} seconds"
    except Exception as e:
        execution_time = time.time() - start_time
        return None, execution_time, 0, f"Error: {str(e)}"

def get_test_stories():
    """Get sample stories for TTS testing"""
    return [
        {
            "id": "story_01",
            "title": "The Magic Crayon",
            "text": "Once upon a time, there was a little girl named Emma who found a magic crayon. When she drew with it, everything she drew came to life! She drew a friendly dragon that could fly her to school, a talking cat that helped with homework, and a rainbow bridge to her grandmother's house. Emma learned that with creativity and kindness, she could make the world a more magical place."
        },
        {
            "id": "story_02", 
            "title": "The Brave Little Robot",
            "text": "In a toy store, there lived a small robot named Chip. Unlike the other toys, Chip could move and think on his own. One day, when the store's lights went out, Chip used his glowing eyes to help all the other toys find their way to safety. The toys realized that being different made Chip special, and they all became the best of friends."
        },
        {
            "id": "story_03",
            "title": "The Dancing Trees",
            "text": "In an enchanted forest, the trees loved to dance when the wind blew. Little Sarah discovered this secret when she got lost during a hike. The trees swayed and moved their branches to show her the way home. As she followed their graceful movements, Sarah learned that nature has its own special language of kindness and guidance."
        }
    ]

def main():
    """Main execution function"""
    print("Starting TTS Models Evaluation...")
    print(f"Testing {len(TTS_PROVIDERS)} TTS providers")
    print("=" * 60)
    
    # Create results directory
    results_dir = Path("../results/tts")
    results_dir.mkdir(parents=True, exist_ok=True)
    
    # Generate timestamp for unique filename
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    results_file = results_dir / f"tts_evaluation_{timestamp}.csv"
    
    # Get test stories
    test_stories = get_test_stories()
    
    # CSV headers
    headers = [
        'timestamp', 'story_id', 'story_title', 'story_text', 'story_length',
        'provider', 'model', 'voice', 'audio_output', 'execution_time', 
        'cost_usd', 'cost_formatted', 'error'
    ]
    
    total_tests = len(TTS_PROVIDERS) * len(test_stories)
    completed = 0
    
    with open(results_file, 'w', newline='', encoding='utf-8') as csvfile:
        writer = csv.DictWriter(csvfile, fieldnames=headers)
        writer.writeheader()
        
        for story in test_stories:
            story_id = story['id']
            story_title = story['title']
            story_text = story['text']
            story_length = len(story_text)
            
            print(f"\nTesting story: {story_title} ({story_length} characters)")
            print("-" * 50)
            
            for provider_name, provider_config in TTS_PROVIDERS.items():
                completed += 1
                progress = (completed / total_tests) * 100
                
                print(f"[{progress:.1f}%] Testing {provider_name}...")
                
                # Select appropriate test function
                if 'elevenlabs' in provider_name:
                    audio_output, execution_time, cost, error = test_elevenlabs_tts(
                        story_text, provider_config, provider_name
                    )
                elif 'openai' in provider_name:
                    audio_output, execution_time, cost, error = test_openai_tts(
                        story_text, provider_config, provider_name
                    )
                elif 'google' in provider_name:
                    audio_output, execution_time, cost, error = test_google_tts(
                        story_text, provider_config, provider_name
                    )
                else:
                    audio_output, execution_time, cost, error = None, 0, 0, "Unsupported provider"
                
                # Write results
                row_data = {
                    'timestamp': datetime.now().isoformat(),
                    'story_id': story_id,
                    'story_title': story_title,
                    'story_text': story_text,
                    'story_length': story_length,
                    'provider': provider_name,
                    'model': provider_config.get('model', 'N/A'),
                    'voice': provider_config.get('voice_id', provider_config.get('voice', 'N/A')),
                    'audio_output': audio_output or 'Failed',
                    'execution_time': round(execution_time, 2),
                    'cost_usd': round(cost, 6),
                    'cost_formatted': format_cost(cost),
                    'error': error or 'None'
                }
                
                writer.writerow(row_data)
                csvfile.flush()  # Ensure data is written immediately
                
                # Display results
                if audio_output:
                    print(f"  ✓ Success - {execution_time:.2f}s - {format_cost(cost)}")
                else:
                    print(f"  ✗ Failed - {execution_time:.2f}s - {error}")
                
                # Small delay between requests to be respectful to APIs
                time.sleep(1)
    
    print("\n" + "=" * 60)
    print(f"TTS evaluation completed!")
    print(f"Results saved to: {results_file}")
    print(f"Total tests: {total_tests}")
    print(f"Timestamp: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    
    # Calculate and display summary statistics
    print("\nSummary:")
    import pandas as pd
    
    try:
        df = pd.read_csv(results_file)
        
        # Success rate by provider
        success_rates = df.groupby('provider')['audio_output'].apply(
            lambda x: (x != 'Failed').mean() * 100
        ).round(1)
        
        print("\nSuccess Rates by Provider:")
        for provider, rate in success_rates.items():
            print(f"  {provider}: {rate}%")
        
        # Average costs by provider
        successful_df = df[df['audio_output'] != 'Failed']
        if not successful_df.empty:
            avg_costs = successful_df.groupby('provider')['cost_usd'].mean()
            
            print("\nAverage Costs by Provider (successful requests):")
            for provider, cost in avg_costs.items():
                print(f"  {provider}: {format_cost(cost)}")
        
        # Average execution times
        avg_times = df.groupby('provider')['execution_time'].mean()
        
        print("\nAverage Execution Times by Provider:")
        for provider, time_val in avg_times.items():
            print(f"  {provider}: {time_val:.2f}s")
            
    except ImportError:
        print("Install pandas for detailed summary statistics: pip install pandas")
    except Exception as e:
        print(f"Could not generate summary statistics: {e}")

if __name__ == "__main__":
    main()
