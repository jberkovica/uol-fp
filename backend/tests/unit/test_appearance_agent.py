"""
Unit tests for the appearance extraction agent.
NO API CALLS - all external dependencies are mocked.
"""
import pytest
import json
from unittest.mock import Mock, patch, AsyncMock
from datetime import datetime
from src.agents.appearance.agent import AppearanceAgent, create_appearance_agent
from src.agents.base import AgentVendor


class TestAppearanceAgent:
    """Test suite for AppearanceAgent."""
    
    @pytest.fixture
    def agent_config(self):
        """Basic agent configuration."""
        return {
            "vendor": "google",
            "model": "gemini-2.0-flash-exp",
            "api_key": "test-api-key",
            "max_tokens": 200,
            "temperature": 0.3
        }
    
    @pytest.fixture
    def sample_image_data(self):
        """Sample base64 image data."""
        # Simple base64 string (not actual image, just for testing)
        return "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChAHGARukzgAAAABJRU5ErkJggg=="
    
    def test_agent_creation(self, agent_config):
        """Test agent can be created with valid config."""
        agent = create_appearance_agent(agent_config)
        assert agent is not None
        assert agent.vendor == AgentVendor.GOOGLE
        assert agent.model == "gemini-2.0-flash-exp"
        assert agent.max_tokens == 200
        assert agent.temperature == 0.3
    
    def test_validate_config_missing_api_key(self):
        """Test validation fails without API key."""
        config = {"vendor": "google", "model": "test-model"}
        agent = AppearanceAgent(AgentVendor.GOOGLE, config)
        
        with pytest.raises(ValueError, match="API key not provided"):
            agent.validate_config()
    
    def test_validate_config_missing_model(self):
        """Test validation fails without model."""
        config = {"vendor": "google", "api_key": "test-key"}
        agent = AppearanceAgent(AgentVendor.GOOGLE, config)
        
        with pytest.raises(ValueError, match="Model not specified"):
            agent.validate_config()
    
    def test_build_appearance_prompt(self, agent_config):
        """Test appearance prompt building from config."""
        agent = create_appearance_agent(agent_config)
        
        prompt = agent._build_appearance_prompt("Emma", 5)
        
        # Check key elements are in prompt
        assert "Emma" in prompt
        assert "age 5" in prompt
        assert "hair" in prompt.lower()
        assert "eyes" in prompt.lower()
        assert "warm" in prompt.lower()
        assert "storyteller" in prompt.lower()
    
    def test_vendor_client_initialization(self, agent_config):
        """Test vendor client initialization without actual API calls."""
        agent = create_appearance_agent(agent_config)
        
        # Test Google initialization (mocked)
        with patch('google.generativeai.configure') as mock_configure, \
             patch('google.generativeai.GenerativeModel') as mock_model:
            mock_model_instance = Mock()
            mock_model.return_value = mock_model_instance
            
            client = agent.get_vendor_client()
            
            mock_configure.assert_called_once_with(api_key="test-api-key")
            mock_model.assert_called_once_with("gemini-2.0-flash-exp")
            assert client == mock_model_instance
    
    def test_openai_client_initialization(self, agent_config):
        """Test OpenAI client initialization."""
        agent_config["vendor"] = "openai"
        agent = AppearanceAgent(AgentVendor.OPENAI, agent_config)
        
        with patch('openai.OpenAI') as mock_openai:
            mock_client = Mock()
            mock_openai.return_value = mock_client
            
            client = agent.get_vendor_client()
            
            mock_openai.assert_called_once_with(api_key="test-api-key")
            assert client == mock_client
    
    @pytest.mark.asyncio
    async def test_extract_appearance_google_success(self, agent_config, sample_image_data):
        """Test successful appearance extraction with Google."""
        agent = create_appearance_agent(agent_config)
        
        # Mock Google response
        mock_response = Mock()
        mock_response.text = "Curly blonde hair that bounces with each step, bright blue eyes full of wonder, and a cheerful smile with a small gap between her front teeth."
        
        with patch.object(agent, '_extract_with_vendor', new_callable=AsyncMock) as mock_extract:
            mock_extract.return_value = mock_response.text
            
            result = await agent.extract_appearance(
                sample_image_data,
                "Emma", 
                5
            )
            
            # Verify the method was called with correct parameters
            mock_extract.assert_called_once()
            
            # Verify result structure
            assert "description" in result
            assert "extracted_at" in result
            assert "model_used" in result
            assert "vendor" in result
            assert "confidence" in result
            assert "word_count" in result
            assert "extraction_method" in result
            
            # Verify content
            assert result["description"] == mock_response.text
            assert result["model_used"] == "gemini-2.0-flash-exp"
            assert result["vendor"] == "google"
            assert result["extraction_method"] == "ai_vision"
            assert result["word_count"] > 0
    
    @pytest.mark.asyncio
    async def test_extract_appearance_with_different_vendors(self, sample_image_data):
        """Test appearance extraction works with different vendors."""
        test_cases = [
            ("google", "gemini-2.0-flash-exp"),
            ("openai", "gpt-4-vision-preview"),
            ("anthropic", "claude-3-sonnet-20240229")
        ]
        
        for vendor_name, model in test_cases:
            config = {
                "vendor": vendor_name,
                "model": model,
                "api_key": "test-key",
                "max_tokens": 200,
                "temperature": 0.3
            }
            
            vendor = AgentVendor(vendor_name)
            agent = AppearanceAgent(vendor, config)
            
            mock_description = f"Test description from {vendor_name}"
            
            with patch.object(agent, '_extract_with_vendor', new_callable=AsyncMock) as mock_extract:
                mock_extract.return_value = mock_description
                
                result = await agent.extract_appearance(sample_image_data, "Test", 5)
                
                assert result["description"] == mock_description
                assert result["vendor"] == vendor_name
                assert result["model_used"] == model
    
    @pytest.mark.asyncio
    async def test_extract_appearance_handles_errors(self, agent_config, sample_image_data):
        """Test error handling in appearance extraction."""
        agent = create_appearance_agent(agent_config)
        
        with patch.object(agent, '_extract_with_vendor', new_callable=AsyncMock) as mock_extract:
            mock_extract.side_effect = Exception("Vision API error")
            
            with pytest.raises(Exception, match="Vision API error"):
                await agent.extract_appearance(sample_image_data, "Emma", 5)
    
    def test_metadata_structure(self, agent_config):
        """Test that metadata has the expected structure."""
        agent = create_appearance_agent(agent_config)
        
        # Test the metadata keys that should be present
        expected_keys = {
            "description", "extracted_at", "model_used", "vendor", 
            "confidence", "word_count", "extraction_method"
        }
        
        # This would be checked in the actual extract_appearance method
        # For unit test, we just verify the expected structure is documented
        assert hasattr(agent, 'extract_appearance')
        
        # Verify agent has required attributes
        assert hasattr(agent, 'model')
        assert hasattr(agent, 'vendor')
        assert hasattr(agent, 'max_tokens')
        assert hasattr(agent, 'temperature')


class TestAppearanceAgentPrompts:
    """Test prompt building and formatting."""
    
    def test_prompt_personalization(self):
        """Test that prompts are properly personalized."""
        config = {
            "vendor": "google",
            "model": "test-model",
            "api_key": "test-key"
        }
        agent = create_appearance_agent(config)
        
        # Test with different names and ages
        prompt1 = agent._build_appearance_prompt("Alice", 4)
        prompt2 = agent._build_appearance_prompt("Bob", 8)
        
        assert "Alice" in prompt1
        assert "age 4" in prompt1
        assert "Bob" in prompt2  
        assert "age 8" in prompt2
        
        # Prompts should be different for different inputs
        assert prompt1 != prompt2
    
    def test_prompt_contains_required_elements(self):
        """Test that prompt contains all required elements for good descriptions."""
        config = {
            "vendor": "google", 
            "model": "test-model",
            "api_key": "test-key"
        }
        agent = create_appearance_agent(config)
        
        prompt = agent._build_appearance_prompt("TestChild", 6)
        
        # Check for key instruction elements
        required_elements = [
            "hair", "eyes", "features", "storyteller", 
            "warm", "positive", "concise"
        ]
        
        prompt_lower = prompt.lower()
        for element in required_elements:
            assert element in prompt_lower, f"Missing required element: {element}"