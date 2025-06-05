#!/usr/bin/env python3
"""
Story Generation Models Evaluation Script
Generates child-friendly stories from image captions using various LLM providers
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
anthropic_client = anthropic.Anthropic(api_key=os.getenv('ANTHROPIC_API_KEY'))
genai.configure(api_key=os.getenv('GOOGLE_API_KEY'))

# Story generation prompt template
STORY_PROMPT_TEMPLATE = """You are a creative children's story writer. Based on this image description, create a short, engaging bedtime story suitable for children aged 4-8.

Image description: {image_caption}

Requirements:
- Write a story of 150-200 words
- Use simple, age-appropriate language
- Include a positive message or gentle lesson
- Make it engaging and imaginative
- Ensure it's suitable for bedtime (calming, not scary)
- Give the story a nice title

Format your response as:
Title: [Story Title]

[Story content here]
"""

def process_story_openai(caption: str, model: str = "gpt-4o") -> tuple[str, float, float]:
    """Generate story using OpenAI GPT models"""
    start_time = time.time()
    
    prompt = STORY_PROMPT_TEMPLATE.format(image_caption=caption)
    
    try:
        with timeout(60):
            response = openai_client.chat.completions.create(
                model=model,
                messages=[
                    {"role": "system", "content": "You are a creative children's story writer specializing in bedtime stories."},
                    {"role": "user", "content": prompt}
                ],
                max_tokens=300,
                temperature=0.8  # Higher creativity for storytelling
            )
            
            story = response.choices[0].message.content
            
    except TimeoutException:
        story = f"OpenAI {model} API call timed out after 60 seconds"
    except Exception as e:
        story = f"Error from OpenAI {model} API: {str(e)}"
    
    execution_time = time.time() - start_time
    
    # Calculate cost using response metadata
    try:
        cost = CostCalculator.calculate_openai_cost(
            response.model_dump() if hasattr(response, 'model_dump') else {},
            prompt,
            has_image=False
        )
    except:
        cost = CostCalculator.calculate_openai_cost({}, prompt, has_image=False)
    
    return story, execution_time, cost

def process_story_anthropic(caption: str, model: str = "claude-3-5-sonnet-20241022") -> tuple[str, float, float]:
    """Generate story using Anthropic Claude"""
    start_time = time.time()
    
    prompt = STORY_PROMPT_TEMPLATE.format(image_caption=caption)
    
    try:
        with timeout(60):
            response = anthropic_client.messages.create(
                model=model,
                max_tokens=300,
                temperature=0.8,
                system="You are a creative children's story writer specializing in bedtime stories.",
                messages=[
                    {"role": "user", "content": prompt}
                ]
            )
            
            story = response.content[0].text
            
    except TimeoutException:
        story = f"Anthropic {model} API call timed out after 60 seconds"
    except Exception as e:
        story = f"Error from Anthropic {model} API: {str(e)}"
    
    execution_time = time.time() - start_time
    
    # Calculate cost
    cost = CostCalculator.calculate_anthropic_cost(prompt, story)
    
    return story, execution_time, cost

def process_story_gemini(caption: str, model_version: str = "gemini-2.5-pro-preview-05-06") -> tuple[str, float, float]:
    """Generate story using Google Gemini"""
    start_time = time.time()
    
    model = genai.GenerativeModel(model_version)
    prompt = STORY_PROMPT_TEMPLATE.format(image_caption=caption)
    
    try:
        with timeout(60):
            response = model.generate_content(
                prompt,
                generation_config={
                    'temperature': 0.8,
                    'max_output_tokens': 300,
                }
            )
            
            if hasattr(response, 'text'):
                story = response.text
            else:
                story = "Could not extract story from Gemini response"
                
    except TimeoutException:
        story = f"Gemini {model_version} API call timed out after 60 seconds"
    except Exception as e:
        story = f"Error from Gemini {model_version} API: {str(e)}"
    
    execution_time = time.time() - start_time
    
    # Calculate cost
    cost = CostCalculator.calculate_google_cost(prompt, story, has_image=False)
    
    return story, execution_time, cost

def process_story_ollama(caption: str, model: str = "llama3.2") -> tuple[str, float, float]:
    """Generate story using local Ollama models"""
    # TODO: Implement Ollama integration
    # This would require installing and running Ollama locally
    # For now, return placeholder
    return "Ollama integration not yet implemented", 0.0, 0.0

def load_image_captions() -> dict:
    """Load image captions from the annotations.json file"""
    
    annotations_file = Path(__file__).parent.parent / 'data' / 'annotations.json'
    
    if not annotations_file.exists():
        raise FileNotFoundError(f"Annotations file not found: {annotations_file}")
    
    print(f"Loading captions from: {annotations_file}")
    
    captions_by_image = {}
    
    try:
        with open(annotations_file, 'r', encoding='utf-8') as file:
            annotations = json.load(file)
            
        for image_filename, data in annotations.items():
            captions_by_image[image_filename] = {
                'annotations': data['expected_caption'],
                'type': data['type'],
                'notes': data.get('notes', '')
            }
            
    except Exception as e:
        raise RuntimeError(f"Error reading annotations file: {e}")
    
    return captions_by_image

def select_best_caption(captions: dict) -> str:
    """Select the best caption from annotations for story generation"""
    
    # Use the annotated caption directly as it's expert-curated
    if 'annotations' in captions and len(captions['annotations'].strip()) > 10:
        return captions['annotations']
    
    return "A scene with interesting elements that could inspire a story."

def evaluate_story_quality(story: str) -> dict:
    """Basic story quality metrics"""
    metrics = {
        'word_count': len(story.split()),
        'has_title': 'Title:' in story,
        'appropriate_length': 100 <= len(story.split()) <= 250,
        'contains_dialogue': '"' in story or "'" in story,
        'positive_tone': any(word in story.lower() for word in 
                           ['happy', 'joy', 'friend', 'kind', 'love', 'smile', 'wonderful']),
        'story_structure': any(word in story.lower() for word in 
                             ['once', 'then', 'finally', 'end', 'lived'])
    }
    
    return metrics

def main():
    # Setup paths
    results_dir = Path(__file__).parent.parent / 'results' / 'story_generation'
    results_dir.mkdir(parents=True, exist_ok=True)
    
    # Load image captions from annotations
    try:
        captions_by_image = load_image_captions()
    except (FileNotFoundError, RuntimeError) as e:
        print(f"Error: {e}")
        return
    
    # Prepare output CSV
    timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
    output_file = results_dir / f'story_generation_results_{timestamp}.csv'
    
    # CSV headers
    fieldnames = [
        'image_file', 'caption_source', 'image_caption', 'story_model', 
        'generated_story', 'execution_time', 'cost', 'word_count',
        'quality_score'
    ]
    
    print(f"Starting story generation collection. Results will be saved to: {output_file}")
    print(f"Found captions for {len(captions_by_image)} images")
    
    # Latest Models to test (June 2025)
    story_models = [
        ('gpt-4o', process_story_openai),
        ('gpt-4.5', lambda cap: process_story_openai(cap, "gpt-4.5")),
        ('claude-3.7-sonnet', lambda cap: process_story_anthropic(cap, "claude-3-7-sonnet-20250219")),
        ('gemini-2.5-flash', lambda cap: process_story_gemini(cap, "gemini-2.5-flash-preview")),
        ('gemini-2.0-flash', lambda cap: process_story_gemini(cap, "gemini-2.0-flash")),
        # ('llama3.2', process_story_ollama),  # Uncomment when Ollama is set up
    ]
    
    try:
        with open(output_file, 'w', newline='') as csvfile:
            writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
            writer.writeheader()
            
            total_cost = 0.0
            
            # Process each image
            for image_file, captions in captions_by_image.items():
                print(f'\nProcessing stories for {image_file}...')
                
                # Select best caption for story generation
                selected_caption = select_best_caption(captions)
                caption_source = "annotations"
                
                print(f"Using caption: {selected_caption[:100]}...")
                
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
                            'caption_source': caption_source,
                            'image_caption': selected_caption,
                            'story_model': model_name,
                            'generated_story': story,
                            'execution_time': f'{exec_time:.2f}',
                            'cost': f'{cost:.6f}',
                            'word_count': quality_metrics['word_count'],
                            'quality_score': f'{quality_score:.2f}'
                        })
                        
                        total_cost += cost
                        print(f"    ✅ Success - Cost: {format_cost(cost)}, Time: {exec_time:.2f}s")
                        
                    except Exception as e:
                        print(f"    ❌ Error with {model_name}: {str(e)}")
                        
                        # Write error row
                        writer.writerow({
                            'image_file': image_file,
                            'caption_source': caption_source,
                            'image_caption': selected_caption,
                            'story_model': model_name,
                            'generated_story': f"Error: {str(e)}",
                            'execution_time': '0',
                            'cost': '0',
                            'word_count': '0',
                            'quality_score': '0'
                        })
                
                # Small delay between images to avoid rate limiting
                time.sleep(2)
            
            print(f"\n📊 Story generation completed!")
            print(f"Total cost: {format_cost(total_cost)}")
            print(f"Results saved to: {output_file}")
                        
    except Exception as e:
        print(f'Error during processing: {str(e)}')

if __name__ == '__main__':
    try:
        main()
    except KeyboardInterrupt:
        print('\n⏹️  Process interrupted by user')
    except Exception as e:
        print(f'❌ Fatal error: {str(e)}')
    else:
        print('✅ Story generation collection completed successfully!')
