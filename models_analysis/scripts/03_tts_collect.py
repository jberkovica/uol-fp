#!/usr/bin/env python3
"""
TTS Comparative Analysis Script for MIRA Project
University of London Final Project

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

# Load environment variables
load_dotenv()

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
        self.results_dir = Path("../results/tts_analysis")
        self.results_dir.mkdir(parents=True, exist_ok=True)
        
        # TTS Provider Configuration Matrix
        self.tts_providers = {
            'openai': {
                'voices': ['alloy', 'echo', 'fable', 'onyx', 'nova', 'shimmer'],
                'child_friendly': ['fable', 'nova', 'shimmer'],  # Softer voices
                'model': 'tts-1'
            },
            'google': {
                'voices': [
                    'en-US-Neural2-H',  # Female child-like
                    'en-US-Neural2-F',  # Female warm
                    'en-US-Neural2-J',  # Male warm
                    'en-GB-Neural2-A',  # British female
                    'en-GB-Neural2-B'   # British male
                ],
                'child_friendly': ['en-US-Neural2-H', 'en-US-Neural2-F'],
                'model': 'Neural2'
            },
            'elevenlabs': {
                'voices': [
                    'Rachel',    # Warm female
                    'Domi',      # Friendly female  
                    'Bella',     # Soft female
                    'Antoni',    # Warm male
                    'Elli',      # Young female
                    'Josh'       # Friendly male
                ],
                'child_friendly': ['Bella', 'Elli', 'Domi'],
                'model': 'eleven_monolingual_v1'
            },
            'amazon': {
                'voices': [
                    'Joanna',    # US English female
                    'Salli',     # US English female warm
                    'Kendra',    # US English female
                    'Matthew',   # US English male
                    'Justin',    # US English male young
                    'Amy'        # British English female
                ],
                'child_friendly': ['Salli', 'Justin', 'Amy'],
                'model': 'neural'
            },
            'azure': {
                'voices': [
                    'en-US-AriaNeural',     # Female friendly
                    'en-US-JennyNeural',    # Female assistant
                    'en-US-GuyNeural',      # Male friendly
                    'en-GB-LibbyNeural',    # British female child
                    'en-GB-MaisieNeural',   # British female young
                    'en-US-DavisNeural'     # Male narrator
                ],
                'child_friendly': ['en-GB-LibbyNeural', 'en-GB-MaisieNeural', 'en-US-AriaNeural'],
                'model': 'neural'
            }
        }
    
    def setup_clients(self):
        """Initialize API clients for all TTS providers"""
        self.clients = {}
        
        # OpenAI TTS
        try:
            from openai import OpenAI
            self.clients['openai'] = OpenAI(api_key=os.getenv('OPENAI_API_KEY'))
        except Exception as e:
            print(f"OpenAI TTS setup failed: {e}")
        
        # Google Cloud TTS
        try:
            # Set up Google Cloud credentials
            google_creds = os.getenv('GOOGLE_APPLICATION_CREDENTIALS')
            if google_creds:
                self.clients['google'] = texttospeech.TextToSpeechClient()
        except Exception as e:
            print(f"Google TTS setup failed: {e}")
        
        # ElevenLabs
        try:
            elevenlabs_key = os.getenv('ELEVENLABS_API_KEY')
            if elevenlabs_key:
                set_api_key(elevenlabs_key)
                self.clients['elevenlabs'] = True  # ElevenLabs uses global API key
        except Exception as e:
            print(f"ElevenLabs TTS setup failed: {e}")
        
        # Amazon Polly
        try:
            aws_access_key = os.getenv('AWS_ACCESS_KEY_ID')
            aws_secret_key = os.getenv('AWS_SECRET_ACCESS_KEY')
            if aws_access_key and aws_secret_key:
                self.clients['amazon'] = boto3.client(
                    'polly',
                    aws_access_key_id=aws_access_key,
                    aws_secret_access_key=aws_secret_key,
                    region_name='us-east-1'
                )
        except Exception as e:
            print(f"Amazon Polly setup failed: {e}")
        
        # Azure Cognitive Services
        try:
            azure_key = os.getenv('AZURE_SPEECH_KEY')
            azure_region = os.getenv('AZURE_SPEECH_REGION', 'eastus')
            if azure_key:
                self.clients['azure'] = {
                    'key': azure_key,
                    'region': azure_region
                }
        except Exception as e:
            print(f"Azure TTS setup failed: {e}")
    
    def select_representative_story(self) -> Tuple[str, Dict]:
        """
        Select a high-quality representative story from generated results
        Returns: (story_text, metadata)
        """
        # Look for latest story generation results
        results_pattern = "../results/story_generation_results_*.csv"
        import glob
        
        result_files = glob.glob(results_pattern)
        if not result_files:
            raise FileNotFoundError("No story generation results found. Run 02_story_generation_collect.py first.")
        
        # Load most recent results
        latest_file = max(result_files, key=os.path.getctime)
        df = pd.read_csv(latest_file)
        
        # Filter for high-quality stories (good length, structure, etc.)
        quality_stories = df[
            (df['word_count'] >= 150) & 
            (df['word_count'] <= 200) &
            (df['meets_length_req'] == True) &
            (df['has_title'] == True) &
            (df['positive_tone'] == True) &
            (df['age_appropriate'] == True)
        ]
        
        if quality_stories.empty:
            print("No high-quality stories found, using best available...")
            quality_stories = df.nlargest(5, 'word_count')
        
        # Select story from best-performing model (e.g., GPT-4o or Claude)
        preferred_models = ['gpt-4o', 'claude-3.5-sonnet', 'gemini-2.0-flash']
        
        selected_story = None
        for model in preferred_models:
            model_stories = quality_stories[quality_stories['story_model'] == model]
            if not model_stories.empty:
                selected_story = model_stories.iloc[0]
                break
        
        if selected_story is None:
            selected_story = quality_stories.iloc[0]
        
        story_text = selected_story['generated_story']
        metadata = {
            'source_model': selected_story['story_model'],
            'source_image': selected_story['image_file'],
            'word_count': selected_story['word_count'],
            'source_file': latest_file
        }
        
        print(f"Selected story from {metadata['source_model']} ({metadata['word_count']} words)")
        print(f"Source image: {metadata['source_image']}")
        
        return story_text, metadata
    
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
        """Generate TTS using Google Cloud TTS"""
        start_time = time.time()
        
        try:
            # Configure the text input
            synthesis_input = texttospeech.SynthesisInput(text=text)
            
            # Configure voice selection
            voice_config = texttospeech.VoiceSelectionParams(
                language_code="en-US",
                name=voice
            )
            
            # Configure audio output
            audio_config = texttospeech.AudioConfig(
                audio_encoding=texttospeech.AudioEncoding.LINEAR16
            )
            
            # Perform TTS request
            response = self.clients['google'].synthesize_speech(
                input=synthesis_input,
                voice=voice_config,
                audio_config=audio_config
            )
            
            execution_time = time.time() - start_time
            
            # Google TTS pricing: $16 per 1M characters for Neural2 voices
            char_count = len(text)
            cost = (char_count / 1_000_000) * 16.0
            
            return response.audio_content, execution_time, cost
            
        except Exception as e:
            print(f"Google TTS error for voice {voice}: {e}")
            return b"", time.time() - start_time, 0.0
    
    def generate_elevenlabs_tts(self, text: str, voice: str) -> Tuple[bytes, float, float]:
        """Generate TTS using ElevenLabs API"""
        start_time = time.time()
        
        try:
            audio_data = generate(
                text=text,
                voice=voice,
                model="eleven_monolingual_v1"
            )
            
            execution_time = time.time() - start_time
            
            # ElevenLabs pricing: approximately $0.30 per 1K characters
            char_count = len(text)
            cost = (char_count / 1000) * 0.30
            
            return audio_data, execution_time, cost
            
        except Exception as e:
            print(f"ElevenLabs TTS error for voice {voice}: {e}")
            return b"", time.time() - start_time, 0.0
    
    def generate_amazon_tts(self, text: str, voice: str) -> Tuple[bytes, float, float]:
        """Generate TTS using Amazon Polly"""
        start_time = time.time()
        
        try:
            response = self.clients['amazon'].synthesize_speech(
                Text=text,
                OutputFormat='pcm',
                VoiceId=voice,
                Engine='neural'
            )
            
            audio_data = response['AudioStream'].read()
            execution_time = time.time() - start_time
            
            # Amazon Polly pricing: $16 per 1M characters for neural voices
            char_count = len(text)
            cost = (char_count / 1_000_000) * 16.0
            
            return audio_data, execution_time, cost
            
        except Exception as e:
            print(f"Amazon Polly TTS error for voice {voice}: {e}")
            return b"", time.time() - start_time, 0.0
    
    def generate_azure_tts(self, text: str, voice: str) -> Tuple[bytes, float, float]:
        """Generate TTS using Azure Cognitive Services"""
        start_time = time.time()
        
        try:
            import requests
            
            subscription_key = self.clients['azure']['key']
            region = self.clients['azure']['region']
            
            # Get access token
            token_url = f"https://{region}.api.cognitive.microsoft.com/sts/v1.0/issueToken"
            headers = {'Ocp-Apim-Subscription-Key': subscription_key}
            token_response = requests.post(token_url, headers=headers)
            access_token = token_response.text
            
            # TTS request
            tts_url = f"https://{region}.tts.speech.microsoft.com/cognitiveservices/v1"
            
            ssml = f"""
            <speak version='1.0' xml:lang='en-US'>
                <voice xml:lang='en-US' name='{voice}'>
                    {text}
                </voice>
            </speak>
            """
            
            headers = {
                'Authorization': f'Bearer {access_token}',
                'Content-Type': 'application/ssml+xml',
                'X-Microsoft-OutputFormat': 'riff-24khz-16bit-mono-pcm'
            }
            
            response = requests.post(tts_url, headers=headers, data=ssml)
            
            execution_time = time.time() - start_time
            
            # Azure TTS pricing: $15 per 1M characters for neural voices
            char_count = len(text)
            cost = (char_count / 1_000_000) * 15.0
            
            return response.content, execution_time, cost
            
        except Exception as e:
            print(f"Azure TTS error for voice {voice}: {e}")
            return b"", time.time() - start_time, 0.0
    
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
        print("TTS COMPARATIVE ANALYSIS - MIRA PROJECT")
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
        
        total_combinations = sum(len(voices['voices']) for voices in self.tts_providers.values() 
                               if any(provider in self.clients for provider in [voices]))
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
                elif provider_name == 'amazon':
                    audio_data, exec_time, cost = self.generate_amazon_tts(story_text, voice)
                elif provider_name == 'azure':
                    audio_data, exec_time, cost = self.generate_azure_tts(story_text, voice)
                else:
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
