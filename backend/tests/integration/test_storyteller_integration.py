"""
Integration tests for storyteller agent with real AI API calls.

WARNING: These tests make real API calls and cost money!
They are excluded from default test runs.

To run these tests:
1. Set API keys: export MISTRAL_API_KEY="..." OPENAI_API_KEY="..." GOOGLE_API_KEY="..."
2. Run: pytest -m "integration and ai_required" tests/integration/

These tests verify:
- Real API integration with AI providers
- JSON response parsing across vendors
- Actual story generation quality
- Performance benchmarking
"""
import pytest
import asyncio
import os
from dotenv import load_dotenv
from src.agents.storyteller.agent import create_storyteller_agent
from src.types.story_models import StoryGenerationContext

load_dotenv()


@pytest.mark.integration
@pytest.mark.ai_required
@pytest.mark.slow
@pytest.mark.skipif(not os.getenv("MISTRAL_API_KEY"), reason="MISTRAL_API_KEY not set")
class TestMistralIntegration:
    """Integration tests for Mistral storyteller."""
    
    @pytest.mark.asyncio
    async def test_mistral_generates_json_story(self):
        """Test that Mistral actually returns JSON format with our prompt."""
        config = {
            "vendor": "mistral",
            "model": "mistral-medium-latest",
            "api_key": os.getenv("MISTRAL_API_KEY"),
            "max_tokens": 300,
            "temperature": 0.7
        }
        
        agent = create_storyteller_agent(config)
        
        result = await agent.process(
            "A magical garden with talking flowers",
            kid_name="Sophie",
            age=6,
            language="en"
        )
        
        # Verify we got a proper response
        assert result["title"]
        assert result["content"]
        assert len(result["content"].split()) >= 100  # Reasonable length
        assert "Sophie" in result["content"] or "sophie" in result["content"].lower()


@pytest.mark.integration
@pytest.mark.ai_required
@pytest.mark.slow
@pytest.mark.skipif(not os.getenv("OPENAI_API_KEY"), reason="OPENAI_API_KEY not set")
class TestOpenAIIntegration:
    """Integration tests for OpenAI storyteller."""
    
    @pytest.mark.asyncio
    async def test_openai_generates_json_story(self):
        """Test that OpenAI returns proper JSON format."""
        config = {
            "vendor": "openai",
            "model": "gpt-3.5-turbo",  # Use cheaper model for tests
            "api_key": os.getenv("OPENAI_API_KEY"),
            "max_tokens": 300,
            "temperature": 0.7
        }
        
        agent = create_storyteller_agent(config)
        
        result = await agent.process(
            "A brave robot exploring space",
            kid_name="Alex",
            age=7,
            language="en"
        )
        
        assert result["title"]
        assert result["content"]
        assert "Alex" in result["content"] or "alex" in result["content"].lower()


@pytest.mark.integration
@pytest.mark.ai_required
@pytest.mark.slow
@pytest.mark.skipif(not os.getenv("GOOGLE_API_KEY"), reason="GOOGLE_API_KEY not set")
class TestGoogleIntegration:
    """Integration tests for Google Gemini storyteller."""
    
    @pytest.mark.asyncio
    async def test_google_generates_story(self):
        """Test that Google Gemini generates a story (may be markdown-wrapped)."""
        config = {
            "vendor": "google",
            "model": "gemini-2.0-flash-exp",
            "api_key": os.getenv("GOOGLE_API_KEY"),
            "max_tokens": 300,
            "temperature": 0.7
        }
        
        agent = create_storyteller_agent(config)
        
        result = await agent.process(
            "A friendly dolphin in the ocean",
            kid_name="Maya",
            age=5,
            language="en"
        )
        
        assert result["title"]
        assert result["content"]
        # Google tends to make shorter stories
        assert len(result["content"].split()) >= 50


@pytest.mark.integration
@pytest.mark.ai_required
@pytest.mark.slow
class TestVendorComparison:
    """Compare different vendors (requires all API keys)."""
    
    @pytest.mark.asyncio
    @pytest.mark.skipif(
        not all([os.getenv("MISTRAL_API_KEY"), os.getenv("OPENAI_API_KEY")]),
        reason="Need both MISTRAL and OPENAI keys for comparison"
    )
    async def test_compare_mistral_vs_openai(self):
        """Compare Mistral and OpenAI outputs for same input."""
        test_input = "A unicorn in a rainbow forest"
        test_context = {
            "kid_name": "Emma",
            "age": 5,
            "language": "en"
        }
        
        # Test Mistral
        mistral_config = {
            "vendor": "mistral",
            "model": "mistral-medium-latest",
            "api_key": os.getenv("MISTRAL_API_KEY"),
            "max_tokens": 300,
            "temperature": 0.7
        }
        mistral_agent = create_storyteller_agent(mistral_config)
        mistral_result = await mistral_agent.process(test_input, **test_context)
        
        # Test OpenAI
        openai_config = {
            "vendor": "openai",
            "model": "gpt-3.5-turbo",
            "api_key": os.getenv("OPENAI_API_KEY"),
            "max_tokens": 300,
            "temperature": 0.7
        }
        openai_agent = create_storyteller_agent(openai_config)
        openai_result = await openai_agent.process(test_input, **test_context)
        
        # Both should produce valid stories
        assert mistral_result["title"] and mistral_result["content"]
        assert openai_result["title"] and openai_result["content"]
        
        # Both should include the kid's name
        assert "Emma" in mistral_result["content"] or "emma" in mistral_result["content"].lower()
        assert "Emma" in openai_result["content"] or "emma" in openai_result["content"].lower()
        
        print(f"\nMistral word count: {len(mistral_result['content'].split())}")
        print(f"OpenAI word count: {len(openai_result['content'].split())}")


# Run integration tests separately with:
# pytest tests/integration/test_storyteller_integration.py -v -m integration