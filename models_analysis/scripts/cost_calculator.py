"""
Dynamic Cost Calculator for AI Models
Provides accurate cost estimation based on actual API usage
"""

import tiktoken
from typing import Dict, Tuple, Optional
import re

class CostCalculator:
    """Calculate costs for various AI model APIs based on actual usage"""
    
    # Current pricing as of June 2025 (prices in USD)
    PRICING = {
        # OpenAI GPT-4o Vision (June 2025)
        'gpt-4o': {
            'input_tokens_per_1k': 0.005,  # $5 per 1M tokens
            'output_tokens_per_1k': 0.015, # $15 per 1M tokens
            'image_detail_low': 0.00085,   # $0.85 per image (low detail)
            'image_detail_high': 0.00255   # $2.55 per image (high detail)
        },
        
        # Google Gemini 2.5 Flash (June 2025) - Latest model
        'gemini-2.5-flash': {
            'input_tokens_per_1k': 0.00015,   # $0.15 per 1M tokens
            'output_tokens_per_1k': 0.0006,   # $0.60 per 1M tokens (non-thinking)
            'output_thinking_per_1k': 0.0035, # $3.50 per 1M tokens (thinking)
            'image_input': 0.0001935          # $0.0001935 per image
        },
        
        # Google Gemini 2.0 Flash (June 2025)
        'gemini-2.0-flash': {
            'input_tokens_per_1k': 0.0001,    # $0.10 per 1M tokens
            'output_tokens_per_1k': 0.0004,   # $0.40 per 1M tokens
            'image_input': 0.0001935          # $0.0001935 per image
        },
        
        # Google Gemini Pro (legacy)
        'gemini-pro': {
            'input_tokens_per_1k': 0.00125,  # $1.25 per 1M tokens
            'output_tokens_per_1k': 0.00375, # $3.75 per 1M tokens
            'image_requests': 0.0025        # $0.0025 per image
        },
        
        # Replicate models (per prediction) - June 2025
        'replicate': {
            'blip': 0.0046,                    # ~$0.0046 per request
            'blip-2': 0.0060,                  # ~$0.0060 per request  
            'cogvlm': 0.0078,                  # ~$0.0078 per request
            'videollama3-7b': 0.008,           # ~$0.008 per request
            'llava-1.5-7b': 0.005,             # ~$0.005 per request
            'llava-1.5-13b': 0.012,            # ~$0.012 per request
            'llama-4-scout': 0.015,            # Token-based pricing
            'llama-4-maverick': 0.020,         # Token-based pricing  
            'ltx-video': 0.027                 # ~$0.027 per request
        },
        
        # Anthropic Claude 3.7 Sonnet (June 2025) - Latest model
        'claude-3.7-sonnet': {
            'input_tokens_per_1k': 0.003,   # $3 per 1M tokens  
            'output_tokens_per_1k': 0.015   # $15 per 1M tokens
        },
        
        # Anthropic Claude 3.5 Sonnet (legacy)
        'claude-3.5-sonnet': {
            'input_tokens_per_1k': 0.003,   # $3 per 1M tokens
            'output_tokens_per_1k': 0.015   # $15 per 1M tokens
        },
        
        # Text-to-Speech Services (June 2025)
        'tts': {
            'elevenlabs_multilingual': 0.15,  # $0.15 per 1K characters (Creator plan)
            'elevenlabs_flash': 0.075,        # Flash model is cheaper
            'openai_tts': 0.015,              # $15 per 1M characters  
            'google_tts_2.5_flash': 0.5,      # $0.50 per 1M input tokens
            'google_tts_2.5_pro': 1.0,        # $1.00 per 1M input tokens
            'azure_tts': 0.000016,            # $16 per 1M characters
            'aws_polly': 0.000004             # $4 per 1M characters
        }
    }
    
    @classmethod
    def count_tokens(cls, text: str, model: str = "gpt-4") -> int:
        """Count tokens in text using tiktoken"""
        try:
            # Map model names to tiktoken encodings
            encoding_map = {
                'gpt-4o': 'cl100k_base',
                'gpt-4': 'cl100k_base', 
                'gpt-3.5': 'cl100k_base',
                'claude': 'cl100k_base',  # Approximation
                'gemini': 'cl100k_base'   # Approximation
            }
            
            encoding_name = encoding_map.get(model, 'cl100k_base')
            encoding = tiktoken.get_encoding(encoding_name)
            return len(encoding.encode(text))
            
        except Exception as e:
            # Fallback: rough estimation (1 token ≈ 0.75 words)
            words = len(text.split())
            return int(words / 0.75)
    
    @classmethod
    def calculate_openai_cost(cls, response_data: Dict, prompt_text: str, 
                             has_image: bool = False, image_detail: str = "low") -> float:
        """Calculate OpenAI API cost from response metadata"""
        try:
            # Try to get usage from response
            if 'usage' in response_data:
                usage = response_data['usage']
                prompt_tokens = usage.get('prompt_tokens', 0)
                completion_tokens = usage.get('completion_tokens', 0)
                
                pricing = cls.PRICING['gpt-4o']
                
                cost = (
                    (prompt_tokens / 1000) * pricing['input_tokens_per_1k'] +
                    (completion_tokens / 1000) * pricing['output_tokens_per_1k']
                )
                
                # Add image cost if applicable
                if has_image:
                    image_key = f'image_detail_{image_detail}'
                    cost += pricing.get(image_key, pricing['image_detail_low'])
                
                return cost
                
        except Exception as e:
            print(f"Warning: Could not parse OpenAI usage data: {e}")
        
        # Fallback calculation
        prompt_tokens = cls.count_tokens(prompt_text)
        estimated_response_tokens = 75  # Average response length
        
        pricing = cls.PRICING['gpt-4o']
        cost = (
            (prompt_tokens / 1000) * pricing['input_tokens_per_1k'] +
            (estimated_response_tokens / 1000) * pricing['output_tokens_per_1k']
        )
        
        if has_image:
            cost += pricing['image_detail_low']
            
        return cost
    
    @classmethod
    def calculate_anthropic_cost(cls, prompt_text: str, response_text: str) -> float:
        """Calculate Anthropic Claude cost"""
        prompt_tokens = cls.count_tokens(prompt_text, 'claude')
        response_tokens = cls.count_tokens(response_text, 'claude')
        
        pricing = cls.PRICING['claude-3.5-sonnet']
        
        return (
            (prompt_tokens / 1000) * pricing['input_tokens_per_1k'] +
            (response_tokens / 1000) * pricing['output_tokens_per_1k']
        )
    
    @classmethod
    def calculate_google_cost(cls, prompt_text: str, response_text: str, 
                             has_image: bool = False) -> float:
        """Calculate Google Gemini cost"""
        prompt_tokens = cls.count_tokens(prompt_text, 'gemini')
        response_tokens = cls.count_tokens(response_text, 'gemini')
        
        pricing = cls.PRICING['gemini-pro']
        
        cost = (
            (prompt_tokens / 1000) * pricing['input_tokens_per_1k'] +
            (response_tokens / 1000) * pricing['output_tokens_per_1k']
        )
        
        if has_image:
            cost += pricing['image_requests']
            
        return cost
    
    @classmethod
    def calculate_replicate_cost(cls, model_name: str) -> float:
        """Calculate Replicate model cost (fixed per prediction)"""
        return cls.PRICING['replicate'].get(model_name, 0.005)  # Default fallback
    
    @classmethod
    def calculate_tts_cost(cls, text: str, provider: str) -> float:
        """Calculate Text-to-Speech cost"""
        char_count = len(text)
        
        if provider in cls.PRICING['tts']:
            rate = cls.PRICING['tts'][provider]
            
            if provider == 'elevenlabs':
                return (char_count / 1000) * rate
            else:
                return (char_count / 1000000) * rate
        
        return 0.0  # Unknown provider
    
    @classmethod
    def estimate_monthly_cost(cls, daily_requests: int, cost_per_request: float) -> Dict[str, float]:
        """Estimate monthly costs based on daily usage"""
        daily_cost = daily_requests * cost_per_request
        weekly_cost = daily_cost * 7
        monthly_cost = daily_cost * 30
        yearly_cost = daily_cost * 365
        
        return {
            'daily': daily_cost,
            'weekly': weekly_cost,
            'monthly': monthly_cost,
            'yearly': yearly_cost
        }
    
    @classmethod
    def compare_providers(cls, prompt_text: str, response_text: str, 
                         has_image: bool = False) -> Dict[str, float]:
        """Compare costs across different providers for the same task"""
        costs = {}
        
        # OpenAI GPT-4o
        costs['gpt-4o'] = cls.calculate_openai_cost(
            {}, prompt_text, has_image
        )
        
        # Google Gemini
        costs['gemini-pro'] = cls.calculate_google_cost(
            prompt_text, response_text, has_image
        )
        
        # Anthropic Claude (text only)
        if not has_image:
            costs['claude-3.5-sonnet'] = cls.calculate_anthropic_cost(
                prompt_text, response_text
            )
        
        return costs
    
    @classmethod
    def get_pricing_info(cls) -> Dict:
        """Return current pricing information for reference"""
        return cls.PRICING.copy()


# Utility functions for cost analysis
def format_cost(cost: float) -> str:
    """Format cost for display"""
    if cost < 0.01:
        return f"${cost:.6f}"
    elif cost < 1.0:
        return f"${cost:.4f}"
    else:
        return f"${cost:.2f}"

def cost_per_1000_requests(cost_per_request: float) -> float:
    """Calculate cost per 1000 requests"""
    return cost_per_request * 1000

def break_even_analysis(fixed_costs: float, cost_per_request: float, 
                       revenue_per_user: float) -> int:
    """Calculate break-even point in number of users"""
    if revenue_per_user <= cost_per_request:
        return float('inf')  # Never breaks even
    
    return int(fixed_costs / (revenue_per_user - cost_per_request)) 