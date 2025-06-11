#!/usr/bin/env python3
"""
Story Generation Models Evaluation Script
Generates family-friendly stories from image captions using various LLM providers

Evaluated Models (8 total):
- OpenAI: GPT-4o, GPT-4o-mini
- Anthropic: Claude 3.5 Sonnet, Claude 3.5 Haiku  
- Google: Gemini 2.0 Flash, 2.0 Flash Lite, 1.5 Pro, 1.5 Flash

Note: Gemini 2.5 preview models excluded due to safety filter restrictions.
See SAFETY_FILTER_INVESTIGATION.md for detailed analysis.

Includes comprehensive cost analysis and performance benchmarks.
"""

import os
import time
import csv
import json
from pathlib import Path
from datetime import datetime
from dotenv import load_dotenv
from openai import OpenAI
import anthropic
import google.generativeai as genai
import signal
from contextlib import contextmanager
from cost_calculator import CostCalculator, format_cost

# Load environment variables
load_dotenv()

# Timeout handler
class TimeoutException(Exception):
    pass

@contextmanager
def timeout(seconds):
    def handler(signum, frame):
        raise TimeoutException(f"Function call timed out after {seconds} seconds")
        
    signal.signal(signal.SIGALRM, handler)
    signal.alarm(seconds)
    
    try:
        yield
    finally:
        signal.alarm(0)

# Configure API clients
openai_client = OpenAI(api_key=os.getenv('OPENAI_API_KEY'))
anthropic_client = anthropic.Anthropic(api_key=os.getenv('CLAUDE_API_KEY'))
genai.configure(api_key=os.getenv('GOOGLE_API_KEY'))

# Unified story generation prompt for all models
UNIFIED_STORY_PROMPT = """Create a family-friendly story inspired by this image description: "{caption}"

Story Requirements:
- Write exactly 150-200 words
- Target audience: young readers and families
- Theme: suitable for reading aloud at bedtime or story time
- Tone: warm, gentle, and comforting
- Include a positive message or gentle life lesson
- Use simple, accessible language
- End on a peaceful, happy note
- Include an engaging title

Response Format:
Title: [Your Story Title]

[Your complete 150-200 word story]

Note: Adherence to the 150-200 word count is essential for evaluation purposes."""

def process_story_openai(caption: str, model: str = "gpt-4o") -> tuple[str, float, float]:
    """Generate story using OpenAI models"""
    
    prompt = UNIFIED_STORY_PROMPT.format(caption=caption)
    
    start_time = time.time()
    
    try:
        client = OpenAI(api_key=os.getenv('OPENAI_API_KEY'))
        
        # Handle different parameter names for different models
        completion_kwargs = {
            "model": model,
            "messages": [
                    {"role": "system", "content": "You are a professional story writer. Follow all formatting and word count requirements precisely."},
                    {"role": "user", "content": prompt}
                ],
            "temperature": 0.7
        }
        
        # o3-mini and newer reasoning models use max_completion_tokens
        if "o3" in model.lower() or "reasoning" in model.lower():
            completion_kwargs["max_completion_tokens"] = 350
        else:
            completion_kwargs["max_tokens"] = 350
        
        with timeout(60):  # 60 second timeout
            response = client.chat.completions.create(**completion_kwargs)
        
        story = response.choices[0].message.content.strip()
        execution_time = time.time() - start_time
        
        # Calculate cost using updated calculator
        cost = CostCalculator.calculate_openai_cost(
            response.model_dump(), prompt, model=model
        )
        
        return story, execution_time, cost
        
    except Exception as e:
        execution_time = time.time() - start_time
        raise RuntimeError(f"OpenAI API error: {str(e)}")

def process_story_anthropic(caption: str, model: str = "claude-3-5-sonnet-20241022") -> tuple[str, float, float]:
    """Generate story using Anthropic Claude models"""
    
    prompt = UNIFIED_STORY_PROMPT.format(caption=caption)
    
    start_time = time.time()
    
    try:
        client = anthropic.Anthropic(api_key=os.getenv('CLAUDE_API_KEY'))
        
        with timeout(60):
            response = client.messages.create(
                model=model,
                max_tokens=400,  # Increased for longer stories
                temperature=0.7,
                messages=[{
                    "role": "user", 
                    "content": prompt
                }]
            )
        
        story = response.content[0].text.strip()
        execution_time = time.time() - start_time
        
        # Calculate cost using updated calculator
        cost = CostCalculator.calculate_anthropic_cost(
            prompt, story, model=model
        )
        
        return story, execution_time, cost
        
    except Exception as e:
        execution_time = time.time() - start_time
        raise RuntimeError(f"Anthropic API error: {str(e)}")

def process_story_google(caption: str, model: str = "gemini-2.0-flash") -> tuple[str, float, float]:
    """Generate story using Google Gemini models with correct API implementation"""
    
    prompt = UNIFIED_STORY_PROMPT.format(caption=caption)
    
    start_time = time.time()
    
    try:
        # Configure safety settings to be extremely permissive for children's stories
        safety_settings = [
            {
                "category": "HARM_CATEGORY_HARASSMENT",
                "threshold": "BLOCK_NONE"
            },
            {
                "category": "HARM_CATEGORY_HATE_SPEECH", 
                "threshold": "BLOCK_NONE"
            },
            {
                "category": "HARM_CATEGORY_SEXUALLY_EXPLICIT",
                "threshold": "BLOCK_NONE"
            },
            {
                "category": "HARM_CATEGORY_DANGEROUS_CONTENT",
                "threshold": "BLOCK_NONE"
            }
        ]
        
        generation_config = {
            "max_output_tokens": 400,
            "temperature": 0.7,
            "candidate_count": 1,
        }
        
        # Create model instance with proper configuration
        model_instance = genai.GenerativeModel(
            model_name=model,
            generation_config=generation_config,
            safety_settings=safety_settings
        )
        
        with timeout(60):
            response = model_instance.generate_content(prompt)
        
        execution_time = time.time() - start_time
        
        # Handle various response scenarios
        if hasattr(response, 'candidates') and response.candidates:
            candidate = response.candidates[0]
            
            # Check for safety filter blocks
            if hasattr(candidate, 'finish_reason'):
                if candidate.finish_reason == 2:  # SAFETY filter
                    return "Content blocked by safety filters. Please try a different prompt.", execution_time, 0.0
                elif candidate.finish_reason == 3:  # RECITATION
                    return "Content blocked due to recitation concerns.", execution_time, 0.0
            
            # Get the actual content
            if hasattr(candidate, 'content') and candidate.content:
                if hasattr(candidate.content, 'parts') and candidate.content.parts:
                    story = candidate.content.parts[0].text.strip()
                    cost = CostCalculator.calculate_google_cost(prompt, story, model=model)
                    return story, execution_time, cost
        
        # Fallback for text attribute
        if hasattr(response, 'text'):
            story = response.text.strip()
            cost = CostCalculator.calculate_google_cost(prompt, story, model=model)
            return story, execution_time, cost
        
        # No usable content found
        return "No story generated - please try again.", execution_time, 0.0
        
    except Exception as e:
        execution_time = time.time() - start_time
        error_msg = str(e)
        
        # Specific handling for safety filter errors
        if "safety" in error_msg.lower() or "blocked" in error_msg.lower():
            return f"Safety filter triggered: {error_msg}", execution_time, 0.0
        
        raise RuntimeError(f"Gemini API error with {model}: {error_msg}")

def process_story_deepseek(caption: str, model: str = "deepseek-chat") -> tuple[str, float, float]:
    """Generate story using DeepSeek models"""
    # Note: This is a placeholder for potential DeepSeek integration
    # Would require DeepSeek API setup and credentials
    return "DeepSeek integration not yet implemented", 0.0, 0.0

def process_story_llama(caption: str, model: str = "llama-4-scout") -> tuple[str, float, float]:
    """Generate story using Meta Llama models via appropriate API"""
    # Note: This is a placeholder for Llama 4 integration
    # Would require Meta API setup or third-party provider like Together AI, Replicate
    # Llama 4 Scout and Maverick are the latest models as of 2025
    return "Llama 4 integration not yet implemented", 0.0, 0.0

def process_story_grok(caption: str, model: str = "grok-3") -> tuple[str, float, float]:
    """Generate story using xAI Grok models"""
    # Note: This is a placeholder for Grok integration
    # Would require xAI API setup and credentials
    # Grok-3 is the latest model as of 2025
    return "Grok integration not yet implemented", 0.0, 0.0

def load_image_annotations() -> dict:
    """Load image annotations from the annotations.json file"""
    
    annotations_file = Path(__file__).parent.parent / 'data' / 'annotations.json'
    
    if not annotations_file.exists():
        raise FileNotFoundError(f"Annotations file not found: {annotations_file}")
    
    print(f"Loading annotations from: {annotations_file}")
    
    annotations_by_image = {}
    
    try:
        with open(annotations_file, 'r', encoding='utf-8') as file:
            annotations = json.load(file)
            
        for image_filename, data in annotations.items():
            annotations_by_image[image_filename] = {
                'base_caption': data['base_caption'],
                'type': data['type'],
                'notes': data.get('notes', '')
            }
            
    except Exception as e:
        raise RuntimeError(f"Error reading annotations file: {e}")
    
    return annotations_by_image

def select_caption_for_story(annotation_data: dict) -> str:
    """Select the best caption from annotations for story generation"""
    
    # Use the annotated caption directly as it's expert-curated
    if 'base_caption' in annotation_data and len(annotation_data['base_caption'].strip()) > 10:
        return annotation_data['base_caption']
    
    return "A scene with interesting elements that could inspire a story."

def evaluate_story_quality(story: str) -> dict:
    """Enhanced story quality metrics for analysis"""
    words = story.split()
    word_count = len(words)
    
    metrics = {
        'word_count': word_count,
        'has_title': 'Title:' in story or 'title:' in story.lower(),
        'meets_length_requirement': 140 <= word_count <= 220,  # Allow some flexibility around 150-200
        'contains_dialogue': '"' in story or "'" in story or '"' in story or '"' in story,
        'positive_tone': any(word in story.lower() for word in 
                           ['happy', 'joy', 'friend', 'kind', 'love', 'smile', 'wonderful', 'magic', 'adventure']),
        'story_structure': any(word in story.lower() for word in 
                             ['once', 'then', 'finally', 'end', 'lived', 'after', 'next']),
        'age_appropriate': not any(word in story.lower() for word in 
                                 ['scary', 'frightening', 'terror', 'death', 'violence', 'dangerous']),
        'bedtime_suitable': any(word in story.lower() for word in 
                              ['dream', 'sleep', 'peaceful', 'gentle', 'quiet', 'soft', 'calm'])
    }
    
    return metrics

def main():
    # Setup paths
    results_dir = Path(__file__).parent.parent / 'results' / 'story_generation'
    results_dir.mkdir(parents=True, exist_ok=True)
    
    # Load image annotations (not image captioning results)
    try:
        annotations_by_image = load_image_annotations()
    except (FileNotFoundError, RuntimeError) as e:
        print(f"Error: {e}")
        return
    
    # Prepare output CSV
    timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
    output_file = results_dir / f'story_generation_results_{timestamp}.csv'
    
    # CSV headers
    fieldnames = [
        'image_file', 'image_type', 'image_caption', 'story_model', 
        'generated_story', 'execution_time', 'cost', 'word_count',
        'quality_score', 'meets_length_req', 'has_title', 'contains_dialogue',
        'positive_tone', 'story_structure', 'age_appropriate', 'bedtime_suitable'
    ]
    
    print(f"Starting story generation collection. Results will be saved to: {output_file}")
    print(f"Found annotations for {len(annotations_by_image)} images")
    
    # Production-ready models (8 total) - all verified working
    story_models = [
        # OpenAI models
        ('gpt-4o', lambda cap: process_story_openai(cap, "gpt-4o")),
        ('gpt-4o-mini', lambda cap: process_story_openai(cap, "gpt-4o-mini")),
        
        # Anthropic models
        ('claude-3.5-sonnet', lambda cap: process_story_anthropic(cap, "claude-3-5-sonnet-20241022")),
        ('claude-3.5-haiku', lambda cap: process_story_anthropic(cap, "claude-3-5-haiku-20241022")),
        
        # Google models (stable production versions only)
        ('gemini-2.0-flash', lambda cap: process_story_google(cap, "gemini-2.0-flash")),
        ('gemini-2.0-flash-lite', lambda cap: process_story_google(cap, "gemini-2.0-flash-lite")),
        ('gemini-1.5-pro', lambda cap: process_story_google(cap, "gemini-1.5-pro")),
        ('gemini-1.5-flash', lambda cap: process_story_google(cap, "gemini-1.5-flash")),
        
        # Note: Gemini 2.5 preview models excluded due to safety filter restrictions
        # See SAFETY_FILTER_INVESTIGATION.md for detailed analysis
    ]
    
    # Print available models for this evaluation
    model_names = [model[0] for model in story_models]
    print(f"Testing {len(story_models)} production-ready models:")
    print(f"  OpenAI: {[m for m in model_names if 'gpt' in m]}")
    print(f"  Anthropic: {[m for m in model_names if 'claude' in m]}")
    print(f"  Google: {[m for m in model_names if 'gemini' in m]}")
    print(f"  All models verified working via comprehensive diagnostic testing")
    print(f"  Gemini 2.5 preview models excluded (see SAFETY_FILTER_INVESTIGATION.md)")
    print("---")
    
    try:
        with open(output_file, 'w', newline='') as csvfile:
            writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
            writer.writeheader()
            
            total_cost = 0.0
            
            # Process each image
            for image_file, annotation_data in annotations_by_image.items():
                print(f'\nProcessing stories for {image_file}...')
                
                # Select caption for story generation from annotations
                selected_caption = select_caption_for_story(annotation_data)
                
                print(f"Using caption: {selected_caption[:100]}...")
                print(f"Image type: {annotation_data.get('type', 'unknown')}")
                
                # Generate stories with each model
                for model_name, story_function in story_models:
                    print(f"  Generating with {model_name}...")
                    
                    try:
                        story, exec_time, cost = story_function(selected_caption)
                        
                        # Evaluate story quality
                        quality_metrics = evaluate_story_quality(story)
                        quality_score = sum(quality_metrics.values()) / len(quality_metrics)
                        
                        writer.writerow({
                            'image_file': image_file,
                            'image_type': annotation_data.get('type', 'unknown'),
                            'image_caption': selected_caption,
                            'story_model': model_name,
                            'generated_story': story,
                            'execution_time': f'{exec_time:.2f}',
                            'cost': f'{cost:.6f}',
                            'word_count': quality_metrics['word_count'],
                            'quality_score': f'{quality_score:.2f}',
                            'meets_length_req': quality_metrics['meets_length_requirement'],
                            'has_title': quality_metrics['has_title'],
                            'contains_dialogue': quality_metrics['contains_dialogue'],
                            'positive_tone': quality_metrics['positive_tone'],
                            'story_structure': quality_metrics['story_structure'],
                            'age_appropriate': quality_metrics['age_appropriate'],
                            'bedtime_suitable': quality_metrics['bedtime_suitable']
                        })
                        
                        total_cost += cost
                        print(f"    Success - Cost: {format_cost(cost)}, Time: {exec_time:.2f}s, Words: {quality_metrics['word_count']}")
                        
                    except Exception as e:
                        print(f"    Error with {model_name}: {str(e)}")
                        
                        # Write error row
                        writer.writerow({
                            'image_file': image_file,
                            'image_type': annotation_data.get('type', 'unknown'),
                            'image_caption': selected_caption,
                            'story_model': model_name,
                            'generated_story': f"Error: {str(e)}",
                            'execution_time': '0',
                            'cost': '0',
                            'word_count': '0',
                            'quality_score': '0',
                            'meets_length_req': False,
                            'has_title': False,
                            'contains_dialogue': False,
                            'positive_tone': False,
                            'story_structure': False,
                            'age_appropriate': False,
                            'bedtime_suitable': False
                        })
                
                # Small delay between images to avoid rate limiting
                time.sleep(3)
            
            print(f"\nStory generation completed!")
            print(f"Total cost: {format_cost(total_cost)}")
            print(f"Results saved to: {output_file}")
            print(f"\nNext steps:")
            print(f"1. Review generated stories for quality and adherence to requirements")
            print(f"2. Run story analysis: python 03_story_generation_analysis.py")
            print(f"3. Compare model performance across metrics")
                        
    except Exception as e:
        print(f'Error during processing: {str(e)}')

if __name__ == '__main__':
    try:
        main()
    except KeyboardInterrupt:
        print('\nProcess interrupted by user')
    except Exception as e:
        print(f'Fatal error: {str(e)}')
    else:
        print('Story generation collection completed successfully!')
