"""
Dynamic Cost Calculator for AI Models
Provides accurate cost estimation based on actual API usage
Updated with 2025 pricing for all major providers
"""

import tiktoken
from typing import Dict, Tuple, Optional
import re

class CostCalculator:
    """Calculate costs for various AI model APIs based on actual usage"""
    
    # Updated 2025 pricing per million tokens (USD)
    OPENAI_PRICING = {
        # Latest 2025 models (removed o3-mini due to high cost and API issues)
        'gpt-4.5-preview': {'input': 10.00, 'output': 30.00},
        'gpt-4.1': {'input': 5.00, 'output': 15.00},
        'gpt-4.1-mini': {'input': 0.30, 'output': 1.20},
        'gpt-4.1-nano': {'input': 0.10, 'output': 0.40},
        
        # Current GPT-4o series
        'gpt-4o': {'input': 5.00, 'output': 15.00},
        'gpt-4o-2024-11-20': {'input': 2.50, 'output': 10.00},
        'gpt-4o-2024-08-06': {'input': 2.50, 'output': 10.00},
        'gpt-4o-2024-05-13': {'input': 5.00, 'output': 15.00},
        'gpt-4o-mini': {'input': 0.15, 'output': 0.60},
        'gpt-4o-mini-2024-07-18': {'input': 0.15, 'output': 0.60},
        
        # Legacy models
        'gpt-4-turbo': {'input': 10.00, 'output': 30.00},
        'gpt-4-turbo-2024-04-09': {'input': 10.00, 'output': 30.00},
        'gpt-4': {'input': 30.00, 'output': 60.00},
        'gpt-3.5-turbo': {'input': 0.50, 'output': 1.50},
        'gpt-3.5-turbo-0125': {'input': 0.50, 'output': 1.50},
    }

    ANTHROPIC_PRICING = {
        # Latest Claude 4 models (2025)
        'claude-opus-4': {'input': 15.00, 'output': 75.00},
        'claude-opus-4-20250514': {'input': 15.00, 'output': 75.00},
        'claude-sonnet-4': {'input': 3.00, 'output': 15.00},
        'claude-sonnet-4-20250514': {'input': 3.00, 'output': 15.00},
        
        # Claude 3.x series
        'claude-3-opus': {'input': 15.00, 'output': 75.00},
        'claude-3-opus-20240229': {'input': 15.00, 'output': 75.00},
        'claude-3.7-sonnet': {'input': 3.00, 'output': 15.00},
        'claude-3-7-sonnet-20250219': {'input': 3.00, 'output': 15.00},
        'claude-3.5-sonnet': {'input': 3.00, 'output': 15.00},
        'claude-3-5-sonnet-20241022': {'input': 3.00, 'output': 15.00},
        'claude-3.5-haiku': {'input': 0.80, 'output': 4.00},
        'claude-3-5-haiku-20241022': {'input': 0.80, 'output': 4.00},
        'claude-3-haiku': {'input': 0.25, 'output': 1.25},
        'claude-3-haiku-20240307': {'input': 0.25, 'output': 1.25}
    }

    GOOGLE_PRICING = {
        # Latest Gemini 2.5 models (2025)
        'gemini-2.5-pro-preview': {'input': 3.50, 'output': 14.00},
        'gemini-2.5-flash-preview': {'input': 0.30, 'output': 1.20},
        'gemini-2.5-pro-preview-06-05': {'input': 3.50, 'output': 14.00},
        'gemini-2.5-flash-preview-05-20': {'input': 0.30, 'output': 1.20},
        
        # Gemini 2.0 models
        'gemini-2.0-flash': {'input': 0.30, 'output': 1.20},
        'gemini-2.0-flash-preview': {'input': 0.30, 'output': 1.20},
        'gemini-2.0-pro': {'input': 3.50, 'output': 14.00},
        
        # Gemini 1.5 models
        'gemini-1.5-pro': {'input': 3.50, 'output': 14.00},
        'gemini-1.5-pro-001': {'input': 3.50, 'output': 14.00},
        'gemini-1.5-flash': {'input': 0.30, 'output': 1.20},
        'gemini-1.5-flash-001': {'input': 0.30, 'output': 1.20},
        'gemini-1.5-flash-8b': {'input': 0.15, 'output': 0.60},
        
        # Legacy models
        'gemini-1.0-pro': {'input': 0.50, 'output': 1.50},
        'gemini-1.0-ultra': {'input': 1.00, 'output': 3.00},
        'gemini-pro': {'input': 0.50, 'output': 1.50},  # Fallback for older code
    }

    # Replicate/Other models
    REPLICATE_PRICING = {
        'blip': 0.0046,                    # ~$0.0046 per request
        'blip-2': 0.0060,                  # ~$0.0060 per request  
        'cogvlm': 0.0078,                  # ~$0.0078 per request
        'videollama3-7b': 0.008,           # ~$0.008 per request
        'llava-1.5-7b': 0.005,             # ~$0.005 per request
        'llava-1.5-13b': 0.012,            # ~$0.012 per request
        'llama-4-scout': 0.015,            # Token-based pricing
        'llama-4-maverick': 0.020,         # Token-based pricing  
        'ltx-video': 0.027                 # ~$0.027 per request
    }

    # DeepSeek pricing (with off-peak discounts) - Updated API model names
    DEEPSEEK_PRICING = {
        'deepseek-reasoner': {'input': 0.55, 'output': 2.19, 'input_cached': 0.14},  # DeepSeek-R1-0528
        'deepseek-chat': {'input': 0.27, 'output': 1.10, 'input_cached': 0.07}      # DeepSeek-V3-0324
    }
    
    # TTS pricing (per million characters - updated 2025)
    TTS_PRICING = {
        # ElevenLabs models (2025) - Based on Creator plan pricing
        'elevenlabs_v3': 220.00,             # ~$220 per 1M characters (NEW: most expressive, 80% off until June)
        'elevenlabs_multilingual': 220.00,   # ~$220 per 1M characters (Creator plan: $22/100k chars)
        'elevenlabs_flash': 220.00,          # ~$220 per 1M characters (same pricing tier)
        'elevenlabs_turbo': 220.00,          # ~$220 per 1M characters (same pricing tier)
        
        # OpenAI models (2025)
        'openai_tts_hd': 30.00,              # $30.00 per 1M characters (HD quality)
        'openai_tts': 15.00,                 # $15.00 per 1M characters (standard)
        
        # Google Cloud TTS models
        'google_cloud_tts_neural2': 16.00,   # $16.00 per 1M characters (Neural2 voices)
        'google_cloud_tts_wavenet': 16.00,   # $16.00 per 1M characters (WaveNet voices)  
        'google_cloud_tts': 4.00,            # $4.00 per 1M characters (standard voices)
        
        # Market reference (2025)
        'openai_s1': 15.00,                  # OpenAudio S1 - most affordable state-of-the-art
        'azure_tts_hd': 30.00                # Azure HD voices (reference)
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
                             has_image: bool = False, model: str = "gpt-4o") -> float:
        """Calculate OpenAI API cost from response metadata"""
        try:
            # Try to get usage from response
            if 'usage' in response_data:
                usage = response_data['usage']
                prompt_tokens = usage.get('prompt_tokens', 0)
                completion_tokens = usage.get('completion_tokens', 0)
                
                pricing = cls.OPENAI_PRICING.get(model, cls.OPENAI_PRICING['gpt-4o'])
                
                cost = (
                    (prompt_tokens / 1000000) * pricing['input'] +
                    (completion_tokens / 1000000) * pricing['output']
                )
                
                return cost
                
        except Exception as e:
            print(f"Warning: Could not parse OpenAI usage data: {e}")
        
        # Fallback calculation
        prompt_tokens = cls.count_tokens(prompt_text)
        estimated_response_tokens = 200  # Average for story generation
        
        pricing = cls.OPENAI_PRICING.get(model, cls.OPENAI_PRICING['gpt-4o'])
        cost = (
            (prompt_tokens / 1000000) * pricing['input'] +
            (estimated_response_tokens / 1000000) * pricing['output']
        )
            
        return cost
    
    @classmethod
    def calculate_anthropic_cost(cls, prompt_text: str, response_text: str, 
                                model: str = "claude-3-7-sonnet-20250219") -> float:
        """Calculate Anthropic Claude cost"""
        prompt_tokens = cls.count_tokens(prompt_text, 'claude')
        response_tokens = cls.count_tokens(response_text, 'claude')
        
        pricing = cls.ANTHROPIC_PRICING.get(model, cls.ANTHROPIC_PRICING['claude-3.5-sonnet'])
        
        return (
            (prompt_tokens / 1000000) * pricing['input'] +
            (response_tokens / 1000000) * pricing['output']
        )
    
    @classmethod
    def calculate_google_cost(cls, prompt_text: str, response_text: str, 
                             has_image: bool = False, model: str = "gemini-2.5-pro-preview") -> float:
        """Calculate Google Gemini cost"""
        prompt_tokens = cls.count_tokens(prompt_text, 'gemini')
        response_tokens = cls.count_tokens(response_text, 'gemini')
        
        pricing = cls.GOOGLE_PRICING.get(model, cls.GOOGLE_PRICING['gemini-pro'])
        
        cost = (
            (prompt_tokens / 1000000) * pricing['input'] +
            (response_tokens / 1000000) * pricing['output']
        )
            
        return cost
    
    @classmethod
    def calculate_deepseek_cost(cls, prompt_text: str, response_text: str, 
                               model: str = "deepseek-chat", cached: bool = False) -> float:
        """Calculate DeepSeek cost with off-peak discount considerations"""
        prompt_tokens = cls.count_tokens(prompt_text)
        response_tokens = cls.count_tokens(response_text)
        
        pricing = cls.DEEPSEEK_PRICING.get(model, cls.DEEPSEEK_PRICING['deepseek-chat'])
        
        input_rate = pricing['input_cached'] if cached else pricing['input']
        
        return (
            (prompt_tokens / 1000000) * input_rate +
            (response_tokens / 1000000) * pricing['output']
        )
    
    @classmethod
    def calculate_replicate_cost(cls, model_name: str) -> float:
        """Calculate Replicate model cost (fixed per prediction)"""
        return cls.REPLICATE_PRICING.get(model_name, 0.005)  # Default fallback
    
    @classmethod
    def calculate_tts_cost(cls, text: str, provider: str = "openai_tts") -> float:
        """Calculate TTS cost based on character count"""
        char_count = len(text)
        
        # Get pricing per million characters
        pricing = cls.TTS_PRICING.get(provider, cls.TTS_PRICING['openai_tts'])
        
        # Calculate cost
        cost = (char_count / 1000000) * pricing
        
        return cost
    
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
            {}, prompt_text, has_image, 'gpt-4o'
        )
        
        # Google Gemini
        costs['gemini-2.5-pro'] = cls.calculate_google_cost(
            prompt_text, response_text, has_image, 'gemini-2.5-pro-preview'
        )
        
        # Anthropic Claude
        costs['claude-3.7-sonnet'] = cls.calculate_anthropic_cost(
            prompt_text, response_text, 'claude-3-7-sonnet-20250219'
        )
        
        # DeepSeek
        costs['deepseek-v3'] = cls.calculate_deepseek_cost(
            prompt_text, response_text, 'deepseek-v3'
        )
        
        return costs
    
    @classmethod
    def get_pricing_info(cls) -> Dict:
        """Return current pricing information for reference"""
        return {
            'openai': cls.OPENAI_PRICING,
            'anthropic': cls.ANTHROPIC_PRICING,
            'google': cls.GOOGLE_PRICING,
            'deepseek': cls.DEEPSEEK_PRICING,
            'replicate': cls.REPLICATE_PRICING,
            'tts': cls.TTS_PRICING
        }

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
    """Calculate break-even point for usage-based services"""
    if revenue_per_user <= cost_per_request:
        return -1  # Cannot break even
    return int(fixed_costs / (revenue_per_user - cost_per_request)) 