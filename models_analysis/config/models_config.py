"""
Configuration settings for model endpoints and parameters.
Contains all model IDs, API endpoints, and configuration parameters.
"""
import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# API Keys
REPLICATE_API_TOKEN = os.getenv('REPLICATE_API_TOKEN')
GOOGLE_API_KEY = os.getenv('GOOGLE_API_KEY')
OPENAI_API_KEY = os.getenv('OPENAI_API_KEY')
CLAUDE_API_KEY = os.getenv("CLAUDE_API_KEY")

# API Endpoints
REPLICATE_API_URL = "https://api.replicate.com/v1/predictions"
GOOGLE_VISION_API_URL = "https://vision.googleapis.com/v1/images:annotate"
# Updated to use Gemini API with the correct format for the stable version
# The correct model is 'models/gemini-1.5-pro' based on the API documentation
GEMINI_API_URL = f"https://generativelanguage.googleapis.com/v1/models/gemini-1.5-pro:generateContent?key={GOOGLE_API_KEY}"
OPENAI_VISION_API_URL = "https://api.openai.com/v1/chat/completions"
CLAUDE_API_URL = "https://api.anthropic.com/v1/messages"

# Model IDs and Versions
# Replicate Models (Updated to latest versions June 2025)
# BLIP - Salesforce's original BLIP model
REPLICATE_BLIP_MODEL = "salesforce/blip:2e1dddc8621f72155f24cf2e0adbde548458d3cab9f00c0139eea840d0ac4746"

# BLIP-2 - Second generation with improved performance
REPLICATE_BLIP2_MODEL = "andreasjansson/blip-2:4b32258c42e9efd4288bb9910bc532a69727f9acd26aa08e175713a0a857a608"

# CogVLM - Using a known working version from naklecha/cogvlm
REPLICATE_COGVLM_MODEL = "naklecha/cogvlm:03bb2a3156b39df8688a1f9097bc80389b376388a6dfeef0a4c5aa8119e17ef8"

# ViT - Trying a simpler implementation of Vision Transformer model
# Note: Using a default version without specific hash to get latest working version
REPLICATE_VIT_MODEL = "falcons-ai/nsfw_image_detection:47ba3d95d76e4900e2c5075483672b14c6107aa6041badcf7cb13321db650647"

# Model Parameters
MODEL_PARAMS = {
    'blip': {
        'max_retries': 3,
        'timeout': 30,  # seconds
        'polling_interval': 10,  # seconds
        'max_polling_attempts': 30,
        'cost_per_request': 0.0002,  # $0.0002 per request
        'cost_unit': 'USD',
        'cost_type': 'per_request'
    },
    'blip2': {
        'max_retries': 3,
        'timeout': 30,
        'polling_interval': 10,
        'max_polling_attempts': 30,
        'cost_per_request': 0.0004,  # $0.0004 per request
        'cost_unit': 'USD',
        'cost_type': 'per_request'
    },
    'cogvlm': {
        'max_retries': 3,
        'timeout': 30,
        'polling_interval': 10,
        'max_polling_attempts': 30,
        'prompt': "Describe this image in a simple sentence appropriate for a child.",
        'cost_per_request': 0.0005,  # $0.0005 per request
        'cost_unit': 'USD',
        'cost_type': 'per_request'
    },
    'vit': {
        'max_retries': 3,
        'timeout': 30,
        'polling_interval': 10,
        'max_polling_attempts': 30,
        'cost_per_request': 0.0001,  # $0.0001 per request
        'cost_unit': 'USD',
        'cost_type': 'per_request'
    },
    'google_vision': {
        'max_retries': 3,
        'timeout': 30,
        'max_results': 5,
        'cost_per_1000': 1.50,  # $1.50 per 1000 images
        'cost_unit': 'USD',
        'cost_type': 'per_1000_requests',
        'cost_tiers': {
            '0-1000': 0.0015,  # $1.50 per 1000 images = $0.0015 per image
            '1001-5000000': 0.001,  # $1.00 per 1000 images
            '5000001+': 0.00075  # $0.75 per 1000 images
        }
    },
    'gemini': {
        'max_retries': 3,
        'timeout': 30,
        'temperature': 0.2,
        'max_output_tokens': 100,
        'prompt': "Describe this image in a simple sentence appropriate for a child:",
        'cost_per_1000_input_tokens': 0.0025,  # $0.0025 per 1000 input tokens
        'cost_per_1000_output_tokens': 0.0025,  # $0.0025 per 1000 output tokens
        'cost_unit': 'USD',
        'cost_type': 'per_token',
        'average_image_tokens': 1500,  # Estimated average image tokens
        'average_output_tokens': 30  # Estimated average output tokens
    },
    'gpt4o': {
        'max_retries': 3,
        'timeout': 30,
        'model': "gpt-4o",
        'max_tokens': 100,
        'prompt': "Describe this image in a single sentence that would be appropriate for a child. Keep it simple and descriptive.",
        'cost_per_1000_input_tokens': 0.005,  # $0.005 per 1000 input tokens
        'cost_per_1000_output_tokens': 0.015,  # $0.015 per 1000 output tokens
        'cost_unit': 'USD',
        'cost_type': 'per_token',
        'average_image_tokens': 2000,  # Estimated average image tokens
        'average_output_tokens': 40  # Estimated average output tokens
    }
}

# Path configurations
DATA_FOLDER = os.path.join(os.path.dirname(os.path.dirname(__file__)), "data")
OUTPUT_FOLDER = os.path.join(os.path.dirname(os.path.dirname(__file__)), "output")
CHARTS_FOLDER = os.path.join(OUTPUT_FOLDER, "charts")
RESULTS_FOLDER = os.path.join(OUTPUT_FOLDER, "results")
LOGS_FOLDER = os.path.join(OUTPUT_FOLDER, "logs")
ANNOTATIONS_PATH = os.path.join(DATA_FOLDER, "annotations.json")

# Make sure output directories exist
for folder in [CHARTS_FOLDER, RESULTS_FOLDER, LOGS_FOLDER]:
    os.makedirs(folder, exist_ok=True)
