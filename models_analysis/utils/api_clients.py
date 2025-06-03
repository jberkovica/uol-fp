"""
API client functions for different image captioning models.

This module provides standardized interfaces to various image captioning APIs:
- Replicate API (BLIP, BLIP-2, CogVLM, ViT)
- Google Vision API
- Google Gemini API
- OpenAI Vision API

Each API function returns a tuple of (caption, execution_time, cost)
"""
import time
import logging
import requests
import base64
from functools import wraps
import json

from models_analysis.config.models_config import (
    REPLICATE_API_TOKEN, GOOGLE_API_KEY, OPENAI_API_KEY, CLAUDE_API_KEY,
    REPLICATE_API_URL, GOOGLE_VISION_API_URL, GEMINI_API_URL, OPENAI_VISION_API_URL, CLAUDE_API_URL,
    REPLICATE_BLIP_MODEL, REPLICATE_BLIP2_MODEL, REPLICATE_COGVLM_MODEL, REPLICATE_VIT_MODEL,
    MODEL_PARAMS
)

# Set up logging
logger = logging.getLogger(__name__)

# Global counter for API requests (used for tiered pricing)
request_counters = {
    'google_vision': 0,
    'claude': 0,
    'gemini': 0,
    'gpt4o': 0,
    'blip': 0,
    'blip2': 0,
    'cogvlm': 0,
    'vit': 0
}

def calculate_cost(model_name):
    """Calculate the cost for a single API request based on model parameters."""
    # Increment request counter for this model
    request_counters[model_name] += 1
    
    model_params = MODEL_PARAMS[model_name]
    cost = 0.0
    
    # Calculate cost based on cost type
    if model_params.get('cost_type') == 'per_request':
        cost = model_params.get('cost_per_request', 0.0)
    
    elif model_params.get('cost_type') == 'per_1000_requests':
        # Get appropriate tier based on request count
        tiers = model_params.get('cost_tiers', {})
        base_cost = model_params.get('cost_per_1000', 0.0) / 1000
        
        # Default to base cost if no tiers defined
        if not tiers:
            cost = base_cost
        else:
            # Find appropriate tier
            count = request_counters[model_name]
            for tier_range, tier_cost in tiers.items():
                start, end = tier_range.split('-')
                start = int(start)
                end = float('inf') if end.endswith('+') else int(end)
                
                if start <= count <= end:
                    cost = tier_cost
                    break
    
    elif model_params.get('cost_type') == 'per_token':
        # For token-based pricing, we use average token counts
        avg_input_tokens = model_params.get('average_image_tokens', 0)
        avg_output_tokens = model_params.get('average_output_tokens', 0)
        
        input_cost_per_token = model_params.get('cost_per_1000_input_tokens', 0.0) / 1000
        output_cost_per_token = model_params.get('cost_per_1000_output_tokens', 0.0) / 1000
        
        cost = (avg_input_tokens * input_cost_per_token) + (avg_output_tokens * output_cost_per_token)
    
    return cost

def measure_execution_time(func):
    """Decorator to measure execution time and cost of API calls."""
    @wraps(func)
    def wrapper(*args, **kwargs):
        # Extract model name from function name
        # Example: get_blip_caption -> blip
        func_name = func.__name__
        model_name = None
        
        if 'blip2' in func_name or 'blip_2' in func_name:
            model_name = 'blip2'
        elif 'blip' in func_name:
            model_name = 'blip'
        elif 'cogvlm' in func_name:
            model_name = 'cogvlm'
        elif 'vit' in func_name:
            model_name = 'vit'
        elif 'google_vision' in func_name:
            model_name = 'google_vision'
        elif 'gemini' in func_name:
            model_name = 'gemini'
        elif 'gpt4' in func_name:
            model_name = 'gpt4o'
        
        # Track execution time in the decorator
        wrapper_start_time = time.time()
        cost = 0.0
        
        try:
            # Call the function and get result
            result = func(*args, **kwargs)
            
            # Calculate elapsed time
            wrapper_execution_time = time.time() - wrapper_start_time
            
            # Calculate cost if model_name is identified
            if model_name and model_name in MODEL_PARAMS:
                cost = calculate_cost(model_name)
                logger.info(f"{func.__name__} cost: ${cost:.6f}")
            
            # Process result based on its type
            if isinstance(result, tuple):
                if len(result) == 2:  # Function returns (caption, time)
                    # Use function's time if provided, otherwise use wrapper's time
                    caption, exec_time = result
                    return caption, exec_time, cost
                else:
                    # Handle any other tuple format safely
                    caption = result[0] if len(result) > 0 else "ERROR: No caption"
                    exec_time = result[1] if len(result) > 1 else wrapper_execution_time
                    return caption, exec_time, cost
            else:
                # Function returned a single value (likely just the caption)
                return result, wrapper_execution_time, cost
                
        except Exception as e:
            logger.error(f"Error in {func.__name__}: {e}")
            return f"ERROR: {e}", 0, 0
    return wrapper

# ----- Replicate API Functions -----

@measure_execution_time
def get_replicate_prediction(image_path, model_version, input_params, model_name=""):
    """
    Generic function to get predictions from Replicate API.
    
    Args:
        image_path: Path to the image file
        model_version: Replicate model version ID
        input_params: Dictionary of model-specific parameters
        model_name: Name of the model for logging
        
    Returns:
        Tuple of (caption, execution_time)
    """
    if not REPLICATE_API_TOKEN:
        logger.error(f"Replicate API token not provided for {model_name}")
        return f"ERROR: Replicate API token not provided", 0
    
    model_params = MODEL_PARAMS.get(model_name.lower(), {})
    max_retries = model_params.get('max_retries', 3)
    polling_interval = model_params.get('polling_interval', 10)
    max_polling_attempts = model_params.get('max_polling_attempts', 30)
    
    headers = {"Authorization": f"Token {REPLICATE_API_TOKEN}"}
    
    # Prepare base64 encoded image for the payload
    base64_image = ""
    try:
        with open(image_path, "rb") as image_file:
            base64_image = base64.b64encode(image_file.read()).decode('utf-8')
    except Exception as e:
        logger.error(f"Error encoding image for {model_name}: {e}")
        return f"ERROR: {str(e)}", 0
    
    # Prepare the input with the base64 image
    payload = {
        "version": model_version,
        "input": {
            **input_params,
            "image": f"data:image/jpeg;base64,{base64_image}"
        }
    }
    
    for attempt in range(max_retries):
        try:
            # Create prediction
            logger.info(f"Creating prediction with {model_name} (attempt {attempt+1}/{max_retries})")
            response = requests.post(
                REPLICATE_API_URL,
                headers=headers,
                json=payload
            )
            
            if response.status_code != 201:
                logger.warning(f"Replicate {model_name} API error: {response.status_code} - {response.text}")
                return f"ERROR: {response.status_code}", 0
                
            prediction = response.json()
            prediction_id = prediction.get('id')
            
            if not prediction_id:
                logger.error(f"No prediction ID returned from {model_name}")
                return "ERROR: No prediction ID returned", 0
                
            # Poll for completion
            status_url = f"https://api.replicate.com/v1/predictions/{prediction_id}"
            logger.info(f"Polling for {model_name} prediction {prediction_id}")
            
            for poll_attempt in range(max_polling_attempts):
                time.sleep(polling_interval)
                status_response = requests.get(status_url, headers=headers)
                
                if status_response.status_code != 200:
                    logger.warning(f"Replicate status check error: {status_response.status_code} - {status_response.text}")
                    break
                    
                status_data = status_response.json()
                status = status_data.get('status')
                
                if status == 'succeeded':
                    output = status_data.get('output', "ERROR: No output in response")
                    logger.info(f"Successful prediction from {model_name}")
                    
                    # Handle different output formats
                    
                    if isinstance(output, list) and output:
                        return output[0]
                    elif isinstance(output, dict) and "labels" in output:
                        top_labels = [label for label, score in zip(output.get("labels", []), output.get("scores", [])) 
                                   if score > 0.1][:3]
                        if top_labels:
                            return "Image showing: " + ", ".join(top_labels)
                    
                    return output
                    
                elif status == 'failed':
                    error = status_data.get('error', "Unknown error")
                    logger.error(f"{model_name} prediction failed: {error}")
                    return f"ERROR: {error}", 0
                    
                elif status in ['starting', 'processing']:
                    logger.debug(f"{model_name} prediction {prediction_id} status: {status}")
                    continue
                    
                else:
                    logger.warning(f"Unexpected status from {model_name}: {status}")
                    break
            
            logger.error(f"{model_name} prediction timed out after {max_polling_attempts} attempts")
            return "ERROR: Prediction timed out", 0
            
        except Exception as e:
            logger.error(f"Error calling {model_name} API: {e}")
            if attempt == max_retries - 1:
                return f"ERROR: {str(e)}", 0
            time.sleep(5)  # Wait before retry
    
    return "ERROR: Max retries exceeded", 0

@measure_execution_time
def get_replicate_blip_caption(image_path):
    """Get image caption from Replicate BLIP model."""
    # BLIP expects 'caption' as a string instruction, not a boolean
    input_params = {"caption": "Generate a detailed caption for this image"}
    return get_replicate_prediction(
        image_path, 
        REPLICATE_BLIP_MODEL, 
        input_params, 
        "BLIP"
    )

@measure_execution_time
def get_replicate_blip2_caption(image_path):
    """Get image caption from Replicate BLIP-2 model."""
    # BLIP-2 model expects caption as a boolean, unlike the original BLIP model
    input_params = {"caption": True}
    return get_replicate_prediction(
        image_path, 
        REPLICATE_BLIP2_MODEL, 
        input_params, 
        "BLIP2"
    )

@measure_execution_time
def get_replicate_cogvlm_caption(image_path):
    """Get image caption from Replicate CogVLM model."""
    prompt = MODEL_PARAMS.get('cogvlm', {}).get(
        'prompt', 
        "Describe this image in a simple sentence appropriate for a child."
    )
    input_params = {"prompt": prompt}
    return get_replicate_prediction(
        image_path, 
        REPLICATE_COGVLM_MODEL, 
        input_params, 
        "CogVLM"
    )

@measure_execution_time
def get_replicate_vit_caption(image_path):
    """Get image caption using Replicate Vision Transformer (ViT) model.
    
    Note: The ViT model is primarily a classification model, so we extract
    the class predictions and format them into a caption.
    """
    # This ViT implementation is a classification model that expects an 'image' parameter
    input_params = {"image": None}  # None will be replaced with the actual image in get_replicate_prediction
    
    # Get the raw prediction (which contains classification results)
    raw_result = get_replicate_prediction(
        image_path, 
        REPLICATE_VIT_MODEL, 
        input_params, 
        "ViT"
    )
    
    # If it's a valid result (not an error), format it into a caption
    if isinstance(raw_result, str) and not raw_result.startswith("ERROR"):
        try:
            # Try to interpret the result as a classification output
            # Format: "The image shows: [classifications]"
            return f"The image shows: {raw_result}"
        except Exception as e:
            logger.error(f"Error formatting ViT result: {e}")
            return raw_result
    
    return raw_result

# ----- Google API Functions -----

@measure_execution_time
def get_google_vision_caption(image_bytes):
    """Get image caption from Google Vision API."""
    if not GOOGLE_API_KEY:
        logger.error("Google API key not provided")
        return "ERROR: Google API key not provided", 0

    model_params = MODEL_PARAMS.get('google_vision', {})
    max_retries = model_params.get('max_retries', 3)
    max_results = model_params.get('max_results', 5)

    image_content = base64.b64encode(image_bytes).decode('utf-8')
    body = {
        'requests': [{
            'image': {
                'content': image_content
            },
            'features': [
                {'type': 'LABEL_DETECTION', 'maxResults': max_results},
                {'type': 'OBJECT_LOCALIZATION', 'maxResults': max_results}
            ]
        }]
    }

    for attempt in range(max_retries):
        try:
            url = f"{GOOGLE_VISION_API_URL}?key={GOOGLE_API_KEY}"
            response = requests.post(url, json=body)

            if response.status_code == 200:
                data = response.json()
                if 'responses' in data and data['responses']:
                    result = data['responses'][0]
                    
                    # Try to get object labels first
                    if 'localizedObjectAnnotations' in result and result['localizedObjectAnnotations']:
                        objects = [obj['name'].lower() for obj in result['localizedObjectAnnotations']][:3]
                        if objects:
                            return f"Image contains: {', '.join(objects)}"
                    
                    # Fall back to general labels
                    if 'labelAnnotations' in result and result['labelAnnotations']:
                        labels = [label['description'].lower() for label in result['labelAnnotations']][:3]
                        if labels:
                            return f"Image shows: {', '.join(labels)}"
                
                return "No clear objects detected"
            else:
                logger.warning(f"Google Vision API error: {response.status_code} - {response.text}")
                return f"ERROR: {response.status_code}", 0
                
        except Exception as e:
            logger.error(f"Error calling Google Vision API: {e}")
            if attempt == max_retries - 1:
                return f"ERROR: {str(e)}", 0
            time.sleep(5)  # Wait before retry

    return "ERROR: Max retries exceeded", 0

@measure_execution_time
def get_gemini_caption(image_bytes):
    """Get image caption from Google's Gemini Pro Vision model."""
    if not GOOGLE_API_KEY:
        logger.error("Google API key not provided for Gemini")
        return "ERROR: Google API key not provided", 0

    model_params = MODEL_PARAMS.get('gemini', {})
    max_retries = model_params.get('max_retries', 3)
    temperature = model_params.get('temperature', 0.2)
    max_output_tokens = model_params.get('max_output_tokens', 100)
    prompt = model_params.get('prompt', "Describe this image in a simple sentence appropriate for a child:")

    # Base64 encode the image
    image_content = base64.b64encode(image_bytes).decode('utf-8')

    # Updated payload for Gemini 1.5 Pro API using v1 endpoint format
    # Note: model is now specified in the URL, not in the payload
    payload = {
        "contents": [{
            "parts": [
                {"text": prompt},
                {"inline_data": {
                    "mime_type": "image/jpeg",
                    "data": image_content
                }}
            ]
        }],
        "generation_config": {
            "temperature": temperature,
            "max_output_tokens": max_output_tokens
        }
    }

    for attempt in range(max_retries):
        try:
            logger.info(f"Calling Gemini API (attempt {attempt+1}/{max_retries})")
            response = requests.post(GEMINI_API_URL, json=payload)

            if response.status_code == 200:
                result = response.json()
                if 'candidates' in result and result['candidates']:
                    content = result['candidates'][0]['content']
                    if 'parts' in content and content['parts']:
                        return content['parts'][0]['text']
                return "Empty response"
            else:
                logger.warning(f"Gemini API error: {response.status_code} - {response.text}")
                return f"ERROR: {response.status_code}", 0
                
        except Exception as e:
            logger.error(f"Error calling Gemini API: {e}")
            if attempt == max_retries - 1:
                return f"ERROR: {str(e)}", 0
            time.sleep(5)  # Wait before retry

    return "ERROR: Max retries exceeded", 0

# ----- Claude API functions
@measure_execution_time
def get_claude_response(text_prompt):
    """
    Get a text response from Anthropic Claude API.
    
    Args:
        text_prompt: Text prompt to send to Claude
        
    Returns:
        Tuple of (response_text, execution_time, cost)
    """
    if not CLAUDE_API_KEY:
        logger.error("Claude API key not provided")
        return "ERROR: Claude API key not provided", 0
    
    max_retries = 3
    
    # Calculate cost based on input/output tokens
    # Claude costs are estimated using Claude 3 Opus pricing as of June 2025
    # $15/1M input tokens, $75/1M output tokens (estimated average cost)
    # Roughly estimating 4 chars per token for English text
    estimated_tokens = len(text_prompt) / 4
    request_counters['claude'] += 1
    
    headers = {
        "x-api-key": CLAUDE_API_KEY,
        "anthropic-version": "2023-06-01",
        "content-type": "application/json"
    }
    
    payload = {
        "model": "claude-3-opus-20240229",
        "max_tokens": 1024,
        "messages": [
            {"role": "user", "content": text_prompt}
        ]
    }
    
    for attempt in range(max_retries):
        try:
            logger.info(f"Calling Claude API (attempt {attempt+1}/{max_retries})")
            response = requests.post(
                CLAUDE_API_URL,
                headers=headers,
                json=payload
            )
            
            if response.status_code != 200:
                logger.warning(f"Claude API error: {response.status_code} - {response.text}")
                if attempt == max_retries - 1:
                    return f"ERROR: {response.status_code}", 0
                time.sleep(2)
                continue
                
            result = response.json()
            response_text = result.get("content", [{}])[0].get("text", "")
            
            # Calculate cost (estimated)
            # Output tokens are roughly the length of the response / 4 (chars per token)
            output_tokens = len(response_text) / 4
            cost = (estimated_tokens * 15 / 1000000) + (output_tokens * 75 / 1000000)
            
            logger.info(f"Successful response from Claude API")
            return response_text, cost
            
        except Exception as e:
            logger.error(f"Error calling Claude API: {e}")
            if attempt == max_retries - 1:
                return f"ERROR: {str(e)}", 0
            time.sleep(2)
    
    return "ERROR: Maximum retries exceeded", 0

# ----- OpenAI API Functions -----

@measure_execution_time
def get_openai_vision_caption(image_path):
    """Get image caption from OpenAI GPT-4o Vision API."""
    if not OPENAI_API_KEY:
        logger.error("OpenAI API key not provided")
        return "ERROR: OpenAI API key not provided", 0

    model_params = MODEL_PARAMS.get('gpt4o', {})
    max_retries = model_params.get('max_retries', 3)
    model = model_params.get('model', "gpt-4o")
    max_tokens = model_params.get('max_tokens', 100)
    prompt = model_params.get('prompt', "Describe this image in a single sentence that would be appropriate for a child. Keep it simple and descriptive.")

    headers = {
        "Content-Type": "application/json",
        "Authorization": f"Bearer {OPENAI_API_KEY}"
    }

    # Encode the image
    base64_image = ""
    try:
        with open(image_path, "rb") as image_file:
            base64_image = base64.b64encode(image_file.read()).decode('utf-8')
    except Exception as e:
        logger.error(f"Error encoding image for OpenAI: {e}")
        return f"ERROR: {str(e)}", 0

    payload = {
        "model": model,
        "messages": [
            {
                "role": "user",
                "content": [
                    {
                        "type": "text",
                        "text": prompt
                    },
                    {
                        "type": "image_url",
                        "image_url": {
                            "url": f"data:image/jpeg;base64,{base64_image}"
                        }
                    }
                ]
            }
        ],
        "max_tokens": max_tokens
    }

    for attempt in range(max_retries):
        try:
            logger.info(f"Calling OpenAI Vision API (attempt {attempt+1}/{max_retries})")
            response = requests.post(OPENAI_VISION_API_URL, headers=headers, json=payload)

            if response.status_code == 200:
                result = response.json()
                if 'choices' in result and result['choices']:
                    return result['choices'][0]['message']['content'].strip()
                return "Empty response"
            else:
                logger.warning(f"OpenAI Vision API error: {response.status_code} - {response.text}")
                return f"ERROR: {response.status_code}", 0
                
        except Exception as e:
            logger.error(f"Error calling OpenAI Vision API: {e}")
            if attempt == max_retries - 1:
                return f"ERROR: {str(e)}", 0
            time.sleep(5)  # Wait before retry

    return "ERROR: Max retries exceeded", 0
