"""
Unit tests for the improved storyteller agent with JSON response handling.
NO API CALLS - all external dependencies are mocked.
"""
import pytest
import json
from unittest.mock import Mock, patch, AsyncMock, MagicMock
from src.agents.storyteller.agent import StorytellerAgent, create_storyteller_agent
from src.agents.base import AgentVendor
from src.types.story_models import LLMStoryResponse, StoryGenerationContext


class TestStorytellerAgent:
    """Test suite for StorytellerAgent."""
    
    @pytest.fixture
    def agent_config(self):
        """Basic agent configuration."""
        return {
            "vendor": "mistral",
            "model": "mistral-medium-latest",
            "api_key": "test-api-key",
            "max_tokens": 300,
            "temperature": 0.7
        }
    
    @pytest.fixture
    def story_context(self):
        """Sample story generation context."""
        return StoryGenerationContext(
            image_description="A friendly dragon playing with balloons",
            kid_name="Emma",
            age=5,
            language="en",
            word_count="150-200",
            genres=["fantasy", "adventure"],
            parent_notes="loves dragons"
        )
    
    def test_agent_creation(self, agent_config):
        """Test agent can be created with valid config."""
        agent = create_storyteller_agent(agent_config)
        assert agent is not None
        assert agent.vendor == AgentVendor.MISTRAL
        assert agent.model == "mistral-medium-latest"
        assert agent.max_tokens == 300
        assert agent.temperature == 0.7
    
    def test_validate_config_missing_api_key(self):
        """Test validation fails without API key."""
        config = {"vendor": "mistral", "model": "test-model"}
        agent = StorytellerAgent(AgentVendor.MISTRAL, config)
        
        with pytest.raises(ValueError, match="API key not provided"):
            agent.validate_config()
    
    def test_validate_config_missing_model(self):
        """Test validation fails without model."""
        config = {"vendor": "mistral", "api_key": "test-key"}
        agent = StorytellerAgent(AgentVendor.MISTRAL, config)
        
        with pytest.raises(ValueError, match="Model not specified"):
            agent.validate_config()
    
    def test_build_generation_context(self, agent_config):
        """Test context building from kwargs."""
        agent = create_storyteller_agent(agent_config)
        
        context = agent._build_generation_context(
            "A magical forest",
            kid_name="Alex",
            age=7,
            language="en",
            genres=["magic", "adventure"],
            appearance="brown hair, blue eyes"
        )
        
        assert context.image_description == "A magical forest"
        assert context.kid_name == "Alex"
        assert context.age == 7
        assert context.language == "en"
        assert context.genres == ["magic", "adventure"]
        assert context.appearance_description == "brown hair, blue eyes"
    
    def test_build_unified_prompt(self, agent_config, story_context):
        """Test unified prompt generation."""
        agent = create_storyteller_agent(agent_config)
        prompt = agent._build_unified_prompt(story_context)
        
        # Check key elements are in prompt
        assert "JSON" in prompt
        assert "Emma" in prompt
        assert "preschool" in prompt.lower() or "simple sentences" in prompt.lower()
        assert "150-200" in prompt
        assert "friendly dragon" in prompt.lower()
        assert '"title"' in prompt
        assert '"content"' in prompt
    
    def test_parse_json_response_valid(self, agent_config):
        """Test parsing valid JSON response."""
        agent = create_storyteller_agent(agent_config)
        
        valid_json = json.dumps({
            "title": "The Magic Adventure",
            "content": "Once upon a time " * 30  # Make it long enough
        })
        
        result = agent._parse_json_response(valid_json)
        assert isinstance(result, LLMStoryResponse)
        assert result.title == "The Magic Adventure"
        assert "Once upon a time" in result.content
    
    def test_parse_json_response_with_markdown(self, agent_config):
        """Test parsing JSON wrapped in markdown code blocks."""
        agent = create_storyteller_agent(agent_config)
        
        markdown_json = '''```json
        {
            "title": "The Dragon Story",
            "content": "''' + "A wonderful story " * 30 + '''"
        }
        ```'''
        
        result = agent._parse_json_response(markdown_json)
        assert isinstance(result, LLMStoryResponse)
        assert result.title == "The Dragon Story"
        assert "wonderful story" in result.content
    
    def test_fallback_parse_response(self, agent_config):
        """Test fallback parsing for non-JSON response."""
        agent = create_storyteller_agent(agent_config)
        
        non_json = """
        **The Brave Dragon**
        
        Once upon a time, there was a brave dragon who loved to help others.
        """ + "The dragon lived in a magical forest. " * 10
        
        result = agent._fallback_parse_response(non_json)
        assert isinstance(result, LLMStoryResponse)
        assert result.title  # Should extract something as title
        assert "brave dragon" in result.content.lower()
    
    def test_get_language_name_from_code(self, agent_config):
        """Test language code to name conversion."""
        agent = create_storyteller_agent(agent_config)
        
        assert agent._get_language_name_from_code("en") == "English"
        assert agent._get_language_name_from_code("ru") == "Russian"
        assert agent._get_language_name_from_code("lv") == "Latvian"
        assert agent._get_language_name_from_code("es") == "Spanish"
        assert agent._get_language_name_from_code("unknown") == "English"  # Default
    
    def test_vendor_client_initialization(self, agent_config):
        """Test vendor client initialization without actual API calls."""
        agent = create_storyteller_agent(agent_config)
        
        # Test Mistral (no client needed)
        assert agent.get_vendor_client() is None
        
        # Test OpenAI initialization (mocked)
        agent.vendor = AgentVendor.OPENAI
        agent._client = None
        with patch('openai.OpenAI') as mock_openai:
            mock_openai.return_value = Mock()
            client = agent.get_vendor_client()
            mock_openai.assert_called_once_with(api_key="test-api-key")
        
        # Test Google initialization (mocked)
        agent.vendor = AgentVendor.GOOGLE
        agent._client = None
        with patch('google.generativeai.configure') as mock_configure:
            client = agent.get_vendor_client()
            mock_configure.assert_called_once_with(api_key="test-api-key")
    
    @pytest.mark.asyncio
    async def test_process_with_mocked_vendor_response(self, agent_config):
        """Test full processing flow with mocked vendor response."""
        agent = create_storyteller_agent(agent_config)
        
        # Mock successful JSON response from vendor
        mock_json_response = json.dumps({
            "title": "Emma's Dragon Adventure",
            "content": "Once upon a time, Emma met a friendly dragon who loved colorful balloons. " * 10
        })
        
        with patch.object(agent, '_generate_with_vendor', new_callable=AsyncMock) as mock_generate:
            mock_generate.return_value = mock_json_response
            
            result = await agent.process(
                "A dragon with balloons",
                kid_name="Emma",
                age=5,
                language="en"
            )
            
            # Verify the method was called
            mock_generate.assert_called_once()
            
            # Verify result
            assert result["title"] == "Emma's Dragon Adventure"
            assert "Emma" in result["content"]
            assert "dragon" in result["content"]
    
    @pytest.mark.asyncio
    async def test_process_with_malformed_json_fallback(self, agent_config):
        """Test processing when vendor returns non-JSON (fallback parsing)."""
        agent = create_storyteller_agent(agent_config)
        
        # Mock non-JSON response (like from Google with markdown)
        mock_markdown_response = '''```json
        {
            "title": "The Balloon Dragon",
            "content": "''' + "A magical dragon story " * 25 + '''"
        }
        ```'''
        
        with patch.object(agent, '_generate_with_vendor', new_callable=AsyncMock) as mock_generate:
            mock_generate.return_value = mock_markdown_response
            
            result = await agent.process(
                "A dragon with balloons",
                kid_name="Emma",
                age=5
            )
            
            # Should successfully parse despite markdown wrapper
            assert result["title"] == "The Balloon Dragon"
            assert "magical dragon" in result["content"]
    
    @pytest.mark.asyncio
    async def test_process_with_plain_text_fallback(self, agent_config):
        """Test processing when vendor returns plain text story."""
        agent = create_storyteller_agent(agent_config)
        
        # Mock plain text response (worst case scenario)
        mock_text_response = """The Brave Little Dragon

Once upon a time, there was a brave little dragon named Sparky. """ + "He loved to play with balloons. " * 20
        
        with patch.object(agent, '_generate_with_vendor', new_callable=AsyncMock) as mock_generate:
            mock_generate.return_value = mock_text_response
            
            result = await agent.process(
                "A dragon with balloons",
                kid_name="Emma",
                age=5
            )
            
            # Should extract title and content even from plain text
            assert result["title"]
            assert result["content"]
            assert "dragon" in result["content"].lower()


class TestStoryModels:
    """Test story model validation."""
    
    def test_story_response_validation(self):
        """Test StoryResponse validation."""
        # Valid story
        story = LLMStoryResponse(
            title="Test Title",
            content="This is a test story. " * 20
        )
        assert story.title == "Test Title"
        
        # Title cleaning
        story = LLMStoryResponse(
            title="**Test Title**",
            content="This is a test story. " * 20
        )
        assert story.title == "Test Title"  # Markdown removed
        
        # Too short content
        with pytest.raises(ValueError, match="at least 50 characters"):
            LLMStoryResponse(
                title="Test",
                content="Too short"
            )
    
    def test_story_generation_context(self):
        """Test StoryGenerationContext."""
        context = StoryGenerationContext(
            image_description="A forest",
            kid_name="Sam",
            age=4,
            language="en"
        )
        
        assert context.get_age_group() == "preschool (simple sentences)"
        
        # Test context string building
        context.genres = ["adventure", "magic"]
        context.parent_notes = "loves animals"
        context.include_appearance = 0.6
        context.appearance_description = "brown hair"
        
        context_str = context.build_context_string()
        assert "adventure" in context_str
        assert "brown hair" in context_str  # Should include since probability > 0.5
        assert "loves animals" in context_str