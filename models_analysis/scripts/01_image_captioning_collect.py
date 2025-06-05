import os
import time
import csv
import base64
from pathlib import Path
from datetime import datetime
from dotenv import load_dotenv
import replicate
from openai import OpenAI
import google.generativeai as genai
from PIL import Image
import signal
from contextlib import contextmanager
from cost_calculator import CostCalculator, format_cost

# Load environment variables
load_dotenv()

# Define a timeout handler to prevent API calls from hanging
class TimeoutException(Exception):
    pass

@contextmanager
def timeout(seconds):
    def handler(signum, frame):
        raise TimeoutException(f"Function call timed out after {seconds} seconds")
        
    # Set the timeout handler
    signal.signal(signal.SIGALRM, handler)
    signal.alarm(seconds)
    
    try:
        yield
    finally:
        # Disable the alarm
        signal.alarm(0)

# Configure API clients
replicate_client = replicate.Client(api_token=os.getenv('REPLICATE_API_TOKEN'))
openai_client = OpenAI(api_key=os.getenv('OPENAI_API_KEY'))
genai.configure(api_key=os.getenv('GOOGLE_API_KEY'))

# Model configurations (Latest 2025 models)
MODELS = {
    'blip': 'salesforce/blip:2e1dddc8621f72155f24cf2e0adbde548458d3cab9f00c0139eea840d0ac4746',
    'blip-2': 'andreasjansson/blip-2:4b32258c42e9efd4288bb9910bc532a69727f9acd26aa08e175713a0a857a608',
    'llava-1.5-7b': 'yorickvp/llava-13b:b5f6212d032508382d61ff00469ddda3e32fd8a0e75dc39d8a4191bb742157fb',
    'llava-1.5-13b': 'yorickvp/llava-v1.6-34b:41ecfbfb261e6c1adf3ad896c9066ca98346996d7c4045c5bc944a79d430f174',
    'videollama3-7b': 'lucataco/videollama3-7b-chat:6e8b9fd55a8db4e9f6f1d3a1c5b7d9e2f4a6c8e0b2d4f6a8c0e2f4a6c8e0b2d4',
}

# Note: Cost calculation is now handled dynamically by CostCalculator class
# No more hardcoded MODEL_COSTS - all costs are calculated based on actual API usage

def process_image_replicate(image_path: Path, model_name: str) -> tuple[str, float, float]:
    """Process image using Replicate models (BLIP, BLIP-2, CogVLM, etc.)"""
    start_time = time.time()
    
    # Different input format for different models
    if model_name in ['cogvlm', 'llava-1.5-7b', 'llava-1.5-13b', 'videollama3-7b']:
        input_dict = {
            "image": open(image_path, "rb"),
            "prompt": "Describe this image concisely in 2-3 sentences. Focus on the main elements visible.",
            "max_tokens": 100
        }
    else:
        # For BLIP models, we don't have direct control over output length
        input_dict = {"image": open(image_path, "rb")}
    
    # Call the Replicate API with a timeout
    try:
        with timeout(60):  # 60 seconds timeout
            output = replicate_client.run(
                MODELS[model_name],
                input=input_dict
            )
            
            # Handle different output types from Replicate
            if hasattr(output, '__iter__') and not isinstance(output, str):
                # If output is a generator/iterator, collect all parts
                description = ""
                try:
                    for chunk in output:
                        if isinstance(chunk, str):
                            description += chunk
                        else:
                            description += str(chunk)
                except Exception:
                    # If iteration fails, try to convert directly
                    description = str(output)
            elif isinstance(output, str):
                description = output
            else:
                # For other types, convert to string
                description = str(output)
                
    except TimeoutException:
        raise Exception(f"Replicate API call for {model_name} timed out after 60 seconds")
    except Exception as e:
        raise e
    
    execution_time = time.time() - start_time
    # Use dynamic cost calculation
    cost = CostCalculator.calculate_replicate_cost(model_name)
    
    return description, execution_time, cost

def process_image_gemini(image_path: Path, model_version: str) -> tuple[str, float, float]:
    """Process image using Google's Gemini models"""
    start_time = time.time()
    
    # Initialize specified Gemini model version
    model = genai.GenerativeModel(model_version)
    
    # Define prompt for image captioning with consistent length requirement
    prompt = "Describe this image concisely in 2-3 sentences. Keep your response to approximately 50-75 words."
    
    # Load and process the image
    img = Image.open(image_path)
    
    # Create content using the simple format that works with Gemini
    try:
        with timeout(30):  # 30 seconds timeout
            # Simple approach with just the image and prompt
            response = model.generate_content([prompt, img])
            
            # Extract text from response
            if hasattr(response, 'text'):
                description = response.text
            elif hasattr(response, 'candidates') and response.candidates:
                # Extract from candidates if available
                description = ""
                for candidate in response.candidates:
                    if hasattr(candidate, 'content'):
                        for part in candidate.content.parts:
                            if hasattr(part, 'text'):
                                description += part.text
            else:
                # If we can't extract text, provide a placeholder
                description = "Image shows a scene that could not be properly described."
    except TimeoutException:
        description = "Gemini API call timed out after 30 seconds"
    except Exception as e:
        description = f"Error from Gemini API: {str(e)}"
    
    execution_time = time.time() - start_time
    # Use dynamic cost calculation for Gemini
    cost = CostCalculator.calculate_google_cost(prompt, description, has_image=True)
    
    return description, execution_time, cost

def process_image_gpt4_vision(image_path: Path) -> tuple[str, float, float]:
    """Process image using OpenAI's GPT-4o Vision model"""
    start_time = time.time()
    
    # Encode image
    with open(image_path, "rb") as image_file:
        encoded_image = base64.b64encode(image_file.read()).decode('utf-8')
    
    # Create message with image and concise description request
    messages = [
        {"role": "user", 
         "content": [
             {"type": "text", "text": "Describe this image concisely in 2-3 sentences. Keep your response to approximately 50-75 words."},
             {"type": "image_url", "image_url": {"url": f"data:image/jpeg;base64,{encoded_image}"}}
         ]
        }
    ]
    
    # Call OpenAI API with timeout
    try:
        with timeout(60):  # 60 seconds timeout
            response = openai_client.chat.completions.create(
                model="gpt-4o",
                messages=messages,
                max_tokens=100
            )
            
            # Extract description
            description = response.choices[0].message.content
    except TimeoutException:
        description = "GPT-4o API call timed out after 60 seconds"
    except Exception as e:
        raise Exception(f"Error from OpenAI API: {str(e)}")
    
    execution_time = time.time() - start_time
    
    # Use dynamic cost calculation with actual response data
    prompt_text = "Describe this image concisely in 2-3 sentences. Keep your response to approximately 50-75 words."
    try:
        cost = CostCalculator.calculate_openai_cost(
            response.model_dump() if hasattr(response, 'model_dump') else {}, 
            prompt_text, 
            has_image=True
        )
    except:
        # Fallback to basic calculation
        cost = CostCalculator.calculate_openai_cost({}, prompt_text, has_image=True)
    
    return description, execution_time, cost

def main():
    # Setup paths
    data_dir = Path(__file__).parent.parent / 'data'
    output_dir = Path(__file__).parent.parent / 'results' / 'image_captioning'
    output_dir.mkdir(parents=True, exist_ok=True)
    
    # Prepare output CSV
    timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
    output_file = output_dir / f'image_captioning_results_{timestamp}.csv'
    
    # CSV headers
    fieldnames = ['file_name', 'model_name', 'description', 'execution_time', 'cost']
    
    print(f"Starting image captioning collection. Results will be saved to: {output_file}")
    
    try:
        with open(output_file, 'w', newline='') as csvfile:
            writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
            writer.writeheader()
            
            # Process each image
            for image_path in data_dir.glob('*.jpeg'):
                print(f'Processing {image_path.name}...')
                
                # Process with latest Gemini models (June 2025)
                gemini_models = [
                    ('gemini-2.5-flash-preview', 'gemini-2.5-flash-preview-05-20'),
                    ('gemini-2.0-flash', 'gemini-2.0-flash')
                ]
                
                for model_name, model_id in gemini_models:
                    try:
                        description, exec_time, cost = process_image_gemini(image_path, model_id)
                        writer.writerow({
                            'file_name': image_path.name,
                            'model_name': model_name,
                            'description': description,
                            'execution_time': f'{exec_time:.2f}',
                            'cost': f'{cost:.4f}'
                        })
                        print(f'Successfully processed with {model_name}')
                    except Exception as e:
                        print(f'Error processing {image_path.name} with {model_name}: {str(e)}')
                        continue  # Continue with other models if one fails
                
                # Process with OpenAI GPT-4o Vision
                try:
                    description, exec_time, cost = process_image_gpt4_vision(image_path)
                    writer.writerow({
                        'file_name': image_path.name,
                        'model_name': 'gpt-4o-vision',
                        'description': description,
                        'execution_time': f'{exec_time:.2f}',
                        'cost': f'{cost:.4f}'
                    })
                    print(f'Successfully processed with GPT-4o Vision')
                except Exception as e:
                    print(f'Error processing {image_path.name} with GPT-4o Vision: {str(e)}')
                    continue  # Continue with other models if one fails
                
                # Process with Replicate models
                for model_name in MODELS.keys():
                    try:
                        description, exec_time, cost = process_image_replicate(image_path, model_name)
                        writer.writerow({
                            'file_name': image_path.name,
                            'model_name': model_name,
                            'description': description,
                            'execution_time': f'{exec_time:.2f}',
                            'cost': f'{cost:.4f}'
                        })
                        print(f'Successfully processed with {model_name}')
                    except Exception as e:
                        print(f'Error processing {image_path.name} with {model_name}: {str(e)}')
                        continue  # Continue with other models if one fails
    except Exception as e:
        print(f'Error during processing: {str(e)}')
        print('Stopping execution due to error.')

if __name__ == '__main__':
    try:
        main()
    except Exception as e:
        print(f'Fatal error: {str(e)}')
        print('Execution stopped.')
    else:
        print('Image captioning collection completed successfully!')
