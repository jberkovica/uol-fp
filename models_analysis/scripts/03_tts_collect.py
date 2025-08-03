#!/usr/bin/env python3
"""
TTS Comparative Analysis Script for Mira Storyteller App
Evaluates text-to-speech quality across multiple providers for children's educational content

This script implements a focused TTS evaluation methodology:
- Selects one representative story from the story generation results
- Generates audio versions across multiple TTS providers
- Collects performance metrics and quality assessments
- Outputs structured data for comparative analysis

Author: MIRA Research Team
Date: December 2025
"""

import os
import time
import csv
import json
import hashlib
from datetime import datetime
from pathlib import Path
from typing import Dict, Tuple, Optional, List
import pandas as pd
from dotenv import load_dotenv

# Load environment variables from parent directory
load_dotenv('../.env')

# Audio processing libraries (will be installed as needed)
try:
    import boto3
    from google.cloud import texttospeech
    from elevenlabs import generate, set_api_key
    import requests
    import wave
    import io
except ImportError as e:
    print(f"Import warning: {e}")
    print("Some TTS providers may not be available. Install required packages as needed.")

class TTSComparativeAnalyzer:
    """
    Comprehensive TTS evaluation system for story narration comparison
    """
    
    def __init__(self):
        self.setup_clients()
        self.results_dir = Path("../results/tts")
        self.results_dir.mkdir(parents=True, exist_ok=True)
        
        # TTS Provider Configuration Matrix - Accessible Providers Only
        # ElevenLabs first for testing, then Google, then OpenAI
        self.tts_providers = {
            'elevenlabs': {
                'voices': [
                    # Child-friendly premium voices - perfect for educational content
                    'EXAVITQu4vr4xnSDxMaL',  # Sarah - young female, soft and gentle
                    'FGY2WhTYpPnrIDTdsKH5',  # Laura - young female, upbeat and energetic
                    'cgSgspJ2msm6clMCkdW9',  # Jessica - young female, expressive and animated
                    'bIHbv24MWmeRgasZH58o',  # Will - young male, friendly and enthusiastic
                    'TX3LPaxmHKxFdv7VOQHJ',  # Liam - young male, articulate American
                    
                    # Character/Storyteller voices - unique intonations
                    'N2lVS1w4EtoT3dr4eOWO',  # Callum - your favorite! Transatlantic storyteller
                    'IKne3meq5aSn9XLyUdCD',  # Charlie - Australian male, natural and warm
                    'XB0fDUnXU5powFXDhCwa',  # Charlotte - Swedish accent, unique character
                    'cjVigY5qzO86Huf0OWal',  # Eric - warm, fatherly voice
                    'XrExE9yKIg1WjnnlVkGX',  # Matilda - friendly American female
                    
                    # Premium adult voices for comparison
                    'Xb7hH8MSUJpSbSDYk0k2',  # Alice - confident British female
                    'iP95p4xoKVk53GoZ742B',  # Chris - casual American male
                ],
                'child_friendly': [
                    'EXAVITQu4vr4xnSDxMaL',  # Sarah - soft and gentle
                    'FGY2WhTYpPnrIDTdsKH5',  # Laura - upbeat and energetic
                    'cgSgspJ2msm6clMCkdW9',  # Jessica - expressive
                    'bIHbv24MWmeRgasZH58o',  # Will - friendly young male
                    'TX3LPaxmHKxFdv7VOQHJ',  # Liam - articulate young male
                    'N2lVS1w4EtoT3dr4eOWO',  # Callum - excellent storyteller
                    'IKne3meq5aSn9XLyUdCD',  # Charlie - natural and warm
                    'cjVigY5qzO86Huf0OWal',  # Eric - fatherly voice
                    'XrExE9yKIg1WjnnlVkGX',  # Matilda - friendly American
                ],
                'model': 'eleven_flash_v2_5'
            },
            'google': {
                'voices': [
                    # US voices - kid-friendly selection
                    'en-US-Neural2-H',  # Female child-like, perfect for kids
                    'en-US-Neural2-F',  # Female warm and gentle
                    'en-US-Neural2-J',  # Male warm and friendly
                    'en-US-Neural2-G',  # Female energetic and upbeat
                    'en-US-Neural2-I',  # Male young and friendly
                    
                    # British voices - storytelling magic
                    'en-GB-Neural2-A',  # British female, elegant
                    'en-GB-Neural2-B',  # British male, sophisticated
                    'en-GB-Neural2-C',  # British female, warm
                    'en-GB-Neural2-D',  # British male, friendly
                    
                    # Australian voices - unique intonations
                    'en-AU-Neural2-A',  # Australian female, cheerful
                    'en-AU-Neural2-B',  # Australian male, laid-back
                    'en-AU-Neural2-C',  # Australian female, energetic
                    'en-AU-Neural2-D',  # Australian male, warm
                ],
                'child_friendly': [
                    'en-US-Neural2-H',  # Child-like female
                    'en-US-Neural2-F',  # Warm female
                    'en-US-Neural2-G',  # Energetic female  
                    'en-US-Neural2-I',  # Young male
                    'en-GB-Neural2-C',  # Warm British female
                    'en-AU-Neural2-A',  # Cheerful Australian
                    'en-AU-Neural2-C',  # Energetic Australian
                ],
                'model': 'Neural2'
            },
            'openai': {
                'voices': ['alloy', 'echo', 'fable', 'onyx', 'nova', 'shimmer'],
                'child_friendly': ['fable', 'nova', 'shimmer'],  # Softer voices
                'model': 'tts-1'
            }
        }
    
    def setup_clients(self):
        """Initialize API clients for all TTS providers"""
        self.clients = {}
        
        # OpenAI TTS
        try:
            from openai import OpenAI
            openai_key = os.getenv('OPENAI_API_KEY')
            if openai_key:
                self.clients['openai'] = OpenAI(api_key=openai_key)
                print("OpenAI TTS client initialized")
        except Exception as e:
            print(f"OpenAI TTS setup failed: {e}")
        
        # Google Cloud TTS - Use REST API with same API key as other Google services
        try:
            import requests
            
            google_api_key = os.getenv('GOOGLE_API_KEY')
            if google_api_key:
                # Test connection by listing voices
                url = f"https://texttospeech.googleapis.com/v1/voices?key={google_api_key}"
                response = requests.get(url, timeout=10)
                if response.status_code == 200:
                    self.clients['google'] = {'api_key': google_api_key}
                    print("Google TTS REST API initialized with API key")
                else:
                    print(f"Google TTS REST API test failed: HTTP {response.status_code}")
        except Exception as e:
            print(f"Google TTS setup failed: {e}")
        
        # ElevenLabs - Use REST API approach like in test
        try:
            import requests
            
            elevenlabs_key = os.getenv('ELEVENLABS_API_KEY')
            if elevenlabs_key:
                print(f"DEBUG: ElevenLabs API key loaded: {elevenlabs_key[:10]}...{elevenlabs_key[-10:]}")
                # Test connection by listing voices
                headers = {"xi-api-key": elevenlabs_key}
                response = requests.get("https://api.elevenlabs.io/v1/voices", headers=headers, timeout=10)
                if response.status_code == 200:
                    self.clients['elevenlabs'] = {'api_key': elevenlabs_key}
                    print("ElevenLabs TTS REST API initialized")
                else:
                    print(f"ElevenLabs TTS REST API test failed: HTTP {response.status_code}: {response.text}")
            else:
                print("ELEVENLABS_API_KEY not found in environment")
        except Exception as e:
            print(f"ElevenLabs TTS setup failed: {e}")
    
    def select_representative_story(self) -> Tuple[str, Dict]:
        """
        Use a predefined representative story for TTS testing
        Returns: (story_text, metadata)
        """
        
        # Predefined short test story for TTS comparative analysis (fits free tier quota)
        test_story = """
The Little Robot and the Butterfly

In a cozy workshop, there lived a curious robot named Zippy. One morning, he met a colorful butterfly outside his window.

"Hello there!" called Zippy cheerfully. "What makes your wings so beautiful?"

The butterfly smiled. "Each color tells a story of flowers I've visited. Would you like to explore the garden with me?"

Zippy's eyes lit up with excitement. Together, they discovered a magical garden where roses hummed soft lullabies and sunflowers danced with the clouds.

"Curiosity opens doors to wonderful adventures," said the butterfly.

Zippy learned that friendship comes in many forms, and asking questions leads to amazing discoveries.
        """.strip()
        
        # Create metadata for the test story
        metadata = {
            'source_model': 'custom_test_story',
            'source_image': 'robot_and_butterfly_workshop',
            'word_count': len(test_story.split()),
            'meets_requirements': True,
            'age_appropriate': True,
            'has_dialogue': True,
            'positive_tone': True
        }
        
        print(f"Using predefined test story:")
        print(f"   Title: The Curious Little Robot")
        print(f"   Word count: {metadata['word_count']} words")
        print(f"   Character count: {len(test_story)} characters")
        print(f"   Features: Child-friendly dialogue, positive themes, perfect for TTS testing")
        
        return test_story, metadata
    
    def generate_openai_tts(self, text: str, voice: str) -> Tuple[bytes, float, float]:
        """Generate TTS using OpenAI TTS API"""
        start_time = time.time()
        
        try:
            response = self.clients['openai'].audio.speech.create(
                model="tts-1",
                voice=voice,
                input=text,
                response_format="wav"
            )
            
            audio_data = response.content
            execution_time = time.time() - start_time
            
            # OpenAI TTS pricing: $15 per 1M characters
            char_count = len(text)
            cost = (char_count / 1_000_000) * 15.0
            
            return audio_data, execution_time, cost
            
        except Exception as e:
            print(f"OpenAI TTS error for voice {voice}: {e}")
            return b"", time.time() - start_time, 0.0
    
    def generate_google_tts(self, text: str, voice: str) -> Tuple[bytes, float, float]:
        """Generate TTS using Google Cloud TTS REST API"""
        start_time = time.time()
        
        try:
            import requests
            
            api_key = self.clients['google']['api_key']
            url = f"https://texttospeech.googleapis.com/v1/text:synthesize?key={api_key}"
            
            # Determine language code based on voice
            if voice.startswith('en-GB'):
                language_code = "en-GB"
            elif voice.startswith('en-AU'):
                language_code = "en-AU"
            elif voice.startswith('en-CA'):
                language_code = "en-CA"
            else:
                language_code = "en-US"
            
            # Configure request payload
            payload = {
                "input": {"text": text},
                "voice": {
                    "languageCode": language_code,
                    "name": voice
                },
                "audioConfig": {
                    "audioEncoding": "LINEAR16",
                    "sampleRateHertz": 24000
                }
            }
            
            # Make TTS request
            response = requests.post(url, json=payload, timeout=30)
            
            if response.status_code == 200:
                result = response.json()
                import base64
                audio_data = base64.b64decode(result['audioContent'])
                
                execution_time = time.time() - start_time
                
                # Google TTS pricing: $16 per 1M characters for Neural2 voices
                char_count = len(text)
                cost = (char_count / 1_000_000) * 16.0
                
                return audio_data, execution_time, cost
            else:
                raise Exception(f"HTTP {response.status_code}: {response.text}")
            
        except Exception as e:
            print(f"Google TTS error for voice {voice}: {e}")
            return b"", time.time() - start_time, 0.0
    
    def generate_elevenlabs_tts(self, text: str, voice: str) -> Tuple[bytes, float, float]:
        """Generate TTS using ElevenLabs REST API with v2.5 model"""
        start_time = time.time()
        
        try:
            import requests
            
            api_key = self.clients['elevenlabs']['api_key']
            
            # First check if voice exists by listing available voices
            headers = {"xi-api-key": api_key}
            voices_response = requests.get("https://api.elevenlabs.io/v1/voices", headers=headers, timeout=10)
            
            if voices_response.status_code != 200:
                raise Exception(f"Cannot list voices: HTTP {voices_response.status_code}")
            
            available_voices = voices_response.json()
            voice_ids = [v['voice_id'] for v in available_voices.get('voices', [])]
            
            if voice not in voice_ids:
                print(f"    Voice {voice} not found in available voices")
                print(f"    Available voices: {voice_ids[:5]}...")  # Show first 5
                raise Exception(f"Voice {voice} not accessible")
            
            # Test available models for comprehensive analysis
            models_to_try = [
                "eleven_flash_v2_5",        # Ultra-fast, 50% cost reduction
                "eleven_multilingual_v2",   # Highest quality traditional model
                "eleven_turbo_v2_5"         # Balanced speed/quality
                # Note: eleven_v3 requires sales contact for early access
            ]
            
            audio_data = None
            last_error = None
            
            for model in models_to_try:
                try:
                    url = f"https://api.elevenlabs.io/v1/text-to-speech/{voice}"
                    headers = {"xi-api-key": api_key, "Content-Type": "application/json"}
                    
                    payload = {
                        "text": text,
                        "model_id": model,
                        "voice_settings": {
                            "stability": 0.5,
                            "similarity_boost": 0.8,
                            "style": 0.0,
                            "use_speaker_boost": True
                        }
                    }
                    
                    response = requests.post(url, json=payload, headers=headers, timeout=30)
                    
                    if response.status_code == 200:
                        audio_data = response.content
                        print(f"    Model {model} succeeded")
                        break  # Success, exit loop
                    else:
                        error_msg = f"HTTP {response.status_code}"
                        try:
                            error_detail = response.json()
                            error_msg += f": {error_detail}"
                        except:
                            error_msg += f": {response.text[:100]}"
                        print(f"    Model {model} failed: {error_msg}")
                        last_error = error_msg
                        continue
                        
                except Exception as model_error:
                    print(f"    Model {model} failed: {model_error}")
                    last_error = str(model_error)
                    continue
            
            if not audio_data:
                raise Exception(f"All ElevenLabs models failed. Last error: {last_error}")
            
            execution_time = time.time() - start_time
            
            # ElevenLabs pricing: ~$22 per 1M characters (2025 pricing, updated)
            char_count = len(text)
            cost = (char_count / 1_000_000) * 22.0
            
            return audio_data, execution_time, cost
            
        except Exception as e:
            print(f"ElevenLabs TTS error for voice {voice}: {e}")
            return b"", time.time() - start_time, 0.0
    
    # Amazon Polly and Azure TTS methods removed due to accessibility constraints
    # Focus on OpenAI TTS, Google Cloud TTS, and ElevenLabs for comparative analysis
    
    def assess_audio_quality(self, audio_data: bytes, provider: str, voice: str) -> Dict:
        """
        Assess audio quality metrics (basic implementation)
        In production, this would include more sophisticated audio analysis
        """
        if not audio_data:
            return {
                'file_size': 0,
                'duration_estimate': 0,
                'quality_score': 0,
                'error': True
            }
        
        file_size = len(audio_data)
        
        # Rough duration estimate (varies by format and quality)
        duration_estimate = file_size / 32000  # Approximate for 16kHz 16-bit audio
        
        # Basic quality score based on file size and provider reputation
        provider_quality_scores = {
            'openai': 8.5,
            'google': 9.0,
            'elevenlabs': 9.5,
            'amazon': 8.7,
            'azure': 8.3
        }
        
        base_score = provider_quality_scores.get(provider, 7.0)
        
        # Adjust based on file size (larger usually means better quality)
        size_factor = min(file_size / 100000, 1.5)  # Normalize and cap
        quality_score = base_score * size_factor
        
        return {
            'file_size': file_size,
            'duration_estimate': round(duration_estimate, 2),
            'quality_score': round(quality_score, 2),
            'error': False
        }
    
    def save_audio_file(self, audio_data: bytes, provider: str, voice: str, story_hash: str) -> str:
        """Save audio data to file and return filename"""
        if not audio_data:
            return ""
        
        # Create audio output directory
        audio_dir = self.results_dir / "audio_files"
        audio_dir.mkdir(exist_ok=True)
        
        # Generate filename
        filename = f"story_{story_hash}_{provider}_{voice}.wav"
        filepath = audio_dir / filename
        
        # Save audio data
        try:
            with open(filepath, 'wb') as f:
                f.write(audio_data)
            return str(filepath)
        except Exception as e:
            print(f"Error saving audio file {filename}: {e}")
            return ""
    
    def run_tts_comparison(self) -> str:
        """
        Main function to run comprehensive TTS comparison
        Returns: Path to results CSV file
        """
        print("=" * 80)
        print("TTS COMPARATIVE ANALYSIS - MIRA STORYTELLER APP")
        print("University of London Final Project")
        print("=" * 80)
        
        # Select representative story
        print("\n1. Selecting representative story...")
        story_text, story_metadata = self.select_representative_story()
        
        # Generate hash for consistent filename
        story_hash = hashlib.md5(story_text.encode()).hexdigest()[:8]
        
        print(f"\nStory preview (first 150 chars):")
        print(f'"{story_text[:150]}..."')
        print(f"\nTotal characters: {len(story_text)}")
        
        # Prepare results storage
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        results_file = self.results_dir / f"tts_comparison_results_{timestamp}.csv"
        
        results = []
        
        print(f"\n2. Generating TTS across {len(self.clients)} providers...")
        print(f"Available providers: {list(self.clients.keys())}")
        
        # Count total voice combinations for active providers
        total_combinations = sum(len(provider_config['voices']) 
                               for provider_name, provider_config in self.tts_providers.items()
                               if provider_name in self.clients)
        current_combination = 0
        
        # Process each provider and voice combination
        for provider_name, provider_config in self.tts_providers.items():
            if provider_name not in self.clients:
                print(f"\n  Skipping {provider_name} (not configured)")
                continue
                
            print(f"\n  Processing {provider_name.upper()} TTS...")
            
            for voice in provider_config['voices']:
                current_combination += 1
                print(f"    [{current_combination}/{total_combinations}] Generating with voice: {voice}")
                
                # Generate TTS
                if provider_name == 'openai':
                    audio_data, exec_time, cost = self.generate_openai_tts(story_text, voice)
                elif provider_name == 'google':
                    audio_data, exec_time, cost = self.generate_google_tts(story_text, voice)
                elif provider_name == 'elevenlabs':
                    audio_data, exec_time, cost = self.generate_elevenlabs_tts(story_text, voice)
                else:
                    print(f"    Unknown provider: {provider_name}")
                    continue
                
                # Assess quality
                quality_metrics = self.assess_audio_quality(audio_data, provider_name, voice)
                
                # Save audio file
                audio_file_path = self.save_audio_file(audio_data, provider_name, voice, story_hash)
                
                # Determine if voice is child-friendly
                is_child_friendly = voice in provider_config['child_friendly']
                
                # Store results
                result_row = {
                    'provider': provider_name,
                    'voice_id': voice,
                    'model': provider_config['model'],
                    'is_child_friendly': is_child_friendly,
                    'execution_time': round(exec_time, 3),
                    'cost_usd': round(cost, 6),
                    'audio_file_path': audio_file_path,
                    'file_size_bytes': quality_metrics['file_size'],
                    'duration_estimate_sec': quality_metrics['duration_estimate'],
                    'quality_score': quality_metrics['quality_score'],
                    'generation_error': quality_metrics['error'],
                    'story_hash': story_hash,
                    'story_source_model': story_metadata['source_model'],
                    'story_source_image': story_metadata['source_image'],
                    'story_word_count': story_metadata['word_count'],
                    'character_count': len(story_text),
                    'timestamp': timestamp
                }
                
                results.append(result_row)
                
                # Brief pause to avoid rate limiting
                time.sleep(1)
        
        # Save results to CSV
        print(f"\n3. Saving results to: {results_file}")
        
        with open(results_file, 'w', newline='', encoding='utf-8') as csvfile:
            if results:
                fieldnames = results[0].keys()
                writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
                writer.writeheader()
                writer.writerows(results)
        
        # Print summary
        print(f"\n4. TTS Comparison Complete!")
        print(f"   Generated: {len(results)} audio versions")
        print(f"   Total cost: ${sum(r['cost_usd'] for r in results):.4f}")
        print(f"   Average generation time: {sum(r['execution_time'] for r in results)/len(results):.2f}s")
        print(f"   Results saved: {results_file}")
        
        # Save story text for reference
        story_file = self.results_dir / f"representative_story_{story_hash}.txt"
        with open(story_file, 'w', encoding='utf-8') as f:
            f.write(f"Representative Story for TTS Analysis\n")
            f.write(f"Generated by: {story_metadata['source_model']}\n")
            f.write(f"Source image: {story_metadata['source_image']}\n")
            f.write(f"Word count: {story_metadata['word_count']}\n")
            f.write(f"Analysis timestamp: {timestamp}\n")
            f.write(f"\n{'='*50}\n\n")
            f.write(story_text)
        
        print(f"   Story text saved: {story_file}")
        
        return str(results_file)

def main():
    """Main execution function"""
    analyzer = TTSComparativeAnalyzer()
    
    try:
        results_file = analyzer.run_tts_comparison()
        print(f"\nTTS comparative analysis completed successfully!")
        print(f"Results available in: {results_file}")
        
    except Exception as e:
        print(f"\nError during TTS analysis: {e}")
        raise

if __name__ == "__main__":
    main()
