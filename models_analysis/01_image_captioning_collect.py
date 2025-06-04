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

# Model configurations
MODELS = {
    'blip': 'salesforce/blip:2e1dddc8621f72155f24cf2e0adbde548458d3cab9f00c0139eea840d0ac4746',
    'blip-2': 'andreasjansson/blip-2:4b32258c42e9efd4288bb9910bc532a69727f9acd26aa08e175713a0a857a608',
    # CogVLM commented out because it's timing out
    # 'cogvlm': 'cjwbw/cogvlm:a5092d718ea77a073e6d8f6969d5c0fb87d0ac7e4cdb7175427331e1798a34ed'
}

# Cost estimates for each model per request based on provider pricing
MODEL_COSTS = {
    'blip': 0.0046,      # Replicate pricing for BLIP (~$0.0046 per request)
    'blip-2': 0.0060,    # Replicate pricing for BLIP-2 (slightly higher than BLIP)
    # 'cogvlm': 0.0078,  # Replicate pricing for CogVLM (~$0.0078 per request) - commented out as we're not using it
    'gemini-pro': 0.0025,    # Google Gemini Pro Preview (higher tier pricing)
    'gpt-4o': 0.0100     # OpenAI GPT-4o Vision API (approximated from token usage)
}

def process_image_replicate(image_path: Path, model_name: str) -> tuple[str, float, float]:
    """Process image using Replicate models (BLIP, BLIP-2, CogVLM, etc.)"""
    start_time = time.time()
    
    # Different input format for different models
    if model_name == 'cogvlm':
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
    except TimeoutException:
        raise Exception(f"Replicate API call for {model_name} timed out after 60 seconds")
    except Exception as e:
        raise e
    
    execution_time = time.time() - start_time
    # Get cost from the MODEL_COSTS dictionary
    cost = MODEL_COSTS[model_name]
    
    return output, execution_time, cost

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
    # Set cost based on model version
    cost = MODEL_COSTS['gemini-pro']
    
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
    
    # Get accurate cost from the MODEL_COSTS dictionary
    cost = MODEL_COSTS['gpt-4o']
    
    return description, execution_time, cost

def main():
    # Setup paths
    data_dir = Path(__file__).parent / 'data'
    output_dir = Path(__file__).parent / 'results'
    output_dir.mkdir(exist_ok=True)
    
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
                
                # Process with Gemini Pro Preview (single call)
                try:
                    description, exec_time, cost = process_image_gemini(image_path, 'gemini-2.5-pro-preview-05-06')
                    writer.writerow({
                        'file_name': image_path.name,
                        'model_name': 'gemini-2.5-pro-preview',
                        'description': description,
                        'execution_time': f'{exec_time:.2f}',
                        'cost': f'{cost:.4f}'
                    })
                    print(f'Successfully processed with Gemini 2.5 Pro Preview')
                except Exception as e:
                    print(f'Error processing {image_path.name} with Gemini Pro: {str(e)}')
                    print('Stopping execution due to error.')
                    return  # Stop execution on error
                
                # Process with Replicate models (CogVLM commented out in MODELS dictionary)
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
                        print('Stopping execution due to error.')
                        return  # Stop execution on error
                
                # Process with GPT-4o
                try:
                    description, exec_time, cost = process_image_gpt4_vision(image_path)
                    writer.writerow({
                        'file_name': image_path.name,
                        'model_name': 'gpt-4o',
                        'description': description,
                        'execution_time': f'{exec_time:.2f}',
                        'cost': f'{cost:.4f}'
                    })
                    print(f'Successfully processed with GPT-4o')
                except Exception as e:
                    print(f'Error processing {image_path.name} with GPT-4o: {str(e)}')
                    print('Stopping execution due to error.')
                    return  # Stop execution on error
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
