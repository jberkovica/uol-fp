#!/usr/bin/env python3
"""
Story Generation Models Evaluation Script
Generates child-friendly stories from image captions using various LLM providers
Updated for 2025 SOTA models with realistic pricing and story limits
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

# Updated story generation prompt template for better analysis
STORY_PROMPT_TEMPLATE = """You are a creative children's story writer. Based on this image description, create a short, engaging bedtime story suitable for children aged 4-8.

Image description: {image_caption}

Requirements:
- Write a story of EXACTLY 150-200 words (this is crucial for analysis)
- Use simple, age-appropriate language
- Include a positive message or gentle lesson
- Make it engaging and imaginative
- Ensure it's suitable for bedtime (calming, not scary)
- Give the story a clear title

Format your response as:
Title: [Story Title]

[Story content here]

Remember: The story MUST be between 150-200 words for proper evaluation."""

def process_story_openai(caption: str, model: str = "gpt-4o") -> tuple[str, float, float]:
    """Generate story using OpenAI models"""
    
    prompt = f"""Create a heartwarming children's bedtime story based on this image description: "{caption}"

Requirements:
- Write exactly 150-200 words
- Make it appropriate for children aged 5-8
- Include a gentle, positive message or lesson
- Use simple, engaging language
- Make it suitable for bedtime (calming, peaceful ending)
- Include a short title

Format:
Title: [Your Title]

[Your story here - exactly 150-200 words]"""
    
    start_time = time.time()
    
    try:
        client = OpenAI(api_key=os.getenv('OPENAI_API_KEY'))
        
        with timeout(60):  # 60 second timeout
            response = client.chat.completions.create(
                model=model,
                messages=[
                    {"role": "system", "content": "You are a talented children's story writer specializing in bedtime stories. Always follow the word count requirements exactly."},
                    {"role": "user", "content": prompt}
                ],
                max_tokens=350,  # Increased for longer stories
                temperature=0.7
            )
        
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
    
    prompt = f"""Please create a charming children's bedtime story based on this image description: "{caption}"

Story Requirements:
- Exactly 150-200 words (please count carefully)
- Perfect for children aged 5-8 years old
- Gentle, soothing tone suitable for bedtime
- Include a meaningful lesson about friendship, kindness, or courage
- Simple vocabulary that children can understand
- Peaceful, happy ending that promotes good dreams
- Include a creative title

Please format as:
Title: [Your Creative Title]

[Write your 150-200 word story here]"""
    
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

def process_story_gemini(caption: str, model_version: str = "gemini-2.0-flash") -> tuple[str, float, float]:
    """Generate story using Google Gemini models"""
    
    prompt = f"""Create a delightful children's bedtime story inspired by this image description: "{caption}"

Story Guidelines:
- Write exactly 150-200 words (this is important!)
- Target audience: children aged 5-8
- Theme: suitable for bedtime reading
- Tone: warm, gentle, and comforting
- Include a positive message or gentle life lesson
- Use simple, age-appropriate language
- End on a peaceful, dreamy note
- Add an engaging title

Format:
Title: [Imaginative Title]

[Your complete 150-200 word bedtime story]"""
    
    start_time = time.time()
    
    try:
        genai.configure(api_key=os.getenv('GOOGLE_API_KEY'))
        model = genai.GenerativeModel(model_version)
        
        generation_config = genai.types.GenerationConfig(
            max_output_tokens=400,  # Increased for longer stories
            temperature=0.7,
        )
        
        with timeout(60):
            response = model.generate_content(
                prompt,
                generation_config=generation_config,
                safety_settings={
                    genai.types.HarmCategory.HARM_CATEGORY_HATE_SPEECH: genai.types.HarmBlockThreshold.BLOCK_NONE,
                    genai.types.HarmCategory.HARM_CATEGORY_HARASSMENT: genai.types.HarmBlockThreshold.BLOCK_NONE,
                    genai.types.HarmCategory.HARM_CATEGORY_SEXUALLY_EXPLICIT: genai.types.HarmBlockThreshold.BLOCK_NONE,
                    genai.types.HarmCategory.HARM_CATEGORY_DANGEROUS_CONTENT: genai.types.HarmBlockThreshold.BLOCK_NONE,
                }
            )
        
        story = response.text.strip()
        execution_time = time.time() - start_time
        
        # Calculate cost using updated calculator
        cost = CostCalculator.calculate_google_cost(
            prompt, story, model=model_version
        )
        
        return story, execution_time, cost
        
    except Exception as e:
        execution_time = time.time() - start_time
        raise RuntimeError(f"Gemini API error: {str(e)}")

def process_story_deepseek(caption: str, model: str = "deepseek-chat") -> tuple[str, float, float]:
    """Generate story using DeepSeek models"""
    # Note: This is a placeholder for potential DeepSeek integration
    # Would require DeepSeek API setup and credentials
    return "DeepSeek integration not yet implemented", 0.0, 0.0

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
    
    # Updated 2025 Models to test (current available models)
    story_models = [
        ('gpt-4o', process_story_openai),
        ('gpt-4o-mini', lambda cap: process_story_openai(cap, "gpt-4o-mini")),
        ('claude-3.5-sonnet', process_story_anthropic),
        ('claude-3.5-haiku', lambda cap: process_story_anthropic(cap, "claude-3-5-haiku-20241022")),
        ('gemini-2.0-flash', process_story_gemini),
        ('gemini-1.5-pro', lambda cap: process_story_gemini(cap, "gemini-1.5-pro")),
        # ('deepseek-v3', process_story_deepseek),  # Uncomment when DeepSeek API is set up
    ]
    
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
