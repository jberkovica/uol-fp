"""Unit tests for AI agents."""
import pytest
from unittest.mock import Mock, patch, AsyncMock
from src.agents.base import BaseAgent, AgentVendor
from src.agents.vision.agent import VisionAgent, create_vision_agent
from src.agents.storyteller.agent import StorytellerAgent, create_storyteller_agent
from src.agents.voice.agent import VoiceAgent, create_voice_agent
from src.types.domain import Language


class TestBaseAgent:
    """Test the base agent interface."""
    
    def test_agent_initialization(self):
        """Test agent initialization with config."""
        config = {"api_key": "test-key", "model": "test-model"}
        
        class TestAgent(BaseAgent):
            async def process(self, input_data, **kwargs):
                return "test"
            
            def validate_config(self):
                return True
        
        agent = TestAgent(AgentVendor.GOOGLE, config)
        assert agent.vendor == AgentVendor.GOOGLE
        assert agent.api_key == "test-key"
        assert agent.model == "test-model"
    
    def test_agent_vendor_enum(self):
        """Test agent vendor enumeration."""
        assert AgentVendor.GOOGLE == "google"
        assert AgentVendor.OPENAI == "openai"
        assert AgentVendor.MISTRAL == "mistral"
        assert AgentVendor.ELEVENLABS == "elevenlabs"


class TestVisionAgent:
    """Test the vision agent."""
    
    def test_vision_agent_creation(self):
        """Test vision agent factory function."""
        config = {"vendor": "google", "api_key": "test-key", "model": "gemini-2.0-flash-exp"}
        agent = create_vision_agent(config)
        
        assert isinstance(agent, VisionAgent)
        assert agent.vendor == AgentVendor.GOOGLE
        assert agent.api_key == "test-key"
    
    def test_vision_agent_config_validation(self):
        """Test vision agent configuration validation."""
        config = {"vendor": "google", "api_key": "test-key", "model": "gemini-2.0-flash-exp"}
        agent = create_vision_agent(config)
        
        assert agent.validate_config() == True
        
        # Test missing API key
        agent.api_key = None
        with pytest.raises(ValueError, match="API key not provided"):
            agent.validate_config()
    
    @patch('src.agents.vision.agent.yaml.safe_load')
    @patch('builtins.open')
    def test_vision_agent_prompt_loading(self, mock_open, mock_yaml):
        """Test vision agent loads prompts from YAML."""
        mock_yaml.return_value = {
            "prompts": {
                "image_caption": {
                    "default": "Describe this image",
                    "google": "Google-specific prompt"
                }
            }
        }
        mock_open.return_value.__enter__.return_value.read.return_value = "mock yaml"
        
        config = {"vendor": "google", "api_key": "test-key", "model": "gemini-2.0-flash-exp"}
        agent = create_vision_agent(config)
        
        assert "prompts" in agent.prompts
        mock_open.assert_called()
    
    @pytest.mark.asyncio
    async def test_vision_agent_unsupported_vendor(self):
        """Test vision agent with unsupported vendor."""
        config = {"vendor": "unsupported", "api_key": "test-key", "model": "test"}
        agent = VisionAgent(AgentVendor.AWS, config)  # AWS not supported in vision
        
        with pytest.raises(ValueError, match="Unsupported vendor"):
            await agent.process("fake_image_data")


class TestStorytellerAgent:
    """Test the storyteller agent."""
    
    def test_storyteller_agent_creation(self):
        """Test storyteller agent factory function."""
        config = {
            "vendor": "mistral",
            "api_key": "test-key",
            "model": "mistral-medium-latest",
            "max_tokens": 300,
            "temperature": 0.7
        }
        agent = create_storyteller_agent(config)
        
        assert isinstance(agent, StorytellerAgent)
        assert agent.vendor == AgentVendor.MISTRAL
        assert agent.max_tokens == 300
        assert agent.temperature == 0.7
    
    def test_storyteller_agent_config_validation(self):
        """Test storyteller agent configuration validation."""
        config = {
            "vendor": "mistral",
            "api_key": "test-key",
            "model": "mistral-medium-latest"
        }
        agent = create_storyteller_agent(config)
        
        assert agent.validate_config() == True
        
        # Test missing model
        agent.model = None
        with pytest.raises(ValueError, match="Model not specified"):
            agent.validate_config()
    
    @patch('src.agents.storyteller.agent.yaml.safe_load')
    @patch('builtins.open')
    def test_storyteller_prompt_loading(self, mock_open, mock_yaml):
        """Test storyteller agent loads prompts from YAML."""
        mock_yaml.return_value = {
            "prompts": {
                "story_generation": {
                    "system": {"default": "You are a storyteller"},
                    "user": {"default": "Create a story about {image_description}"}
                }
            }
        }
        
        config = {"vendor": "mistral", "api_key": "test-key", "model": "mistral-medium-latest"}
        agent = create_storyteller_agent(config)
        
        assert "prompts" in agent.prompts
    
    def test_storyteller_language_mapping(self):
        """Test language code to name mapping."""
        config = {"vendor": "mistral", "api_key": "test-key", "model": "mistral-medium-latest"}
        agent = create_storyteller_agent(config)
        
        assert agent._get_language_name(Language.ENGLISH) == "English"
        assert agent._get_language_name(Language.RUSSIAN) == "Russian"
        assert agent._get_language_name(Language.LATVIAN) == "Latvian"
        assert agent._get_language_name(Language.SPANISH) == "Spanish"
    
    def test_story_title_extraction(self):
        """Test story title extraction from content."""
        config = {"vendor": "mistral", "api_key": "test-key", "model": "mistral-medium-latest"}
        agent = create_storyteller_agent(config)
        
        # Test with title-like first line
        story = "The Magic Forest\n\nOnce upon a time..."
        title = agent._extract_title(story)
        assert title == "The Magic Forest"
        
        # Test with regular sentence
        story = "Once upon a time, there was a magical forest. The trees were tall and green."
        title = agent._extract_title(story)
        assert title == "Once upon a time, there was..."


class TestVoiceAgent:
    """Test the voice agent."""
    
    def test_voice_agent_creation(self):
        """Test voice agent factory function."""
        config = {
            "vendor": "elevenlabs",
            "api_key": "test-key",
            "default_voice": "callum"
        }
        agent = create_voice_agent(config)
        
        assert isinstance(agent, VoiceAgent)
        assert agent.vendor == AgentVendor.ELEVENLABS
        assert agent.default_voice == "callum"
    
    def test_voice_agent_config_validation(self):
        """Test voice agent configuration validation."""
        config = {"vendor": "elevenlabs", "api_key": "test-key"}
        agent = create_voice_agent(config)
        
        assert agent.validate_config() == True
        
        # Test missing API key
        agent.api_key = None
        with pytest.raises(ValueError, match="API key not provided"):
            agent.validate_config()
    
    @patch('src.agents.voice.agent.yaml.safe_load')
    @patch('builtins.open')
    def test_voice_config_loading(self, mock_open, mock_yaml):
        """Test voice agent loads voice config from YAML."""
        mock_yaml.return_value = {
            "voices": {
                "elevenlabs": {
                    "callum": {"id": "voice-id-123"},
                    "rachel": {"id": "voice-id-456"}
                }
            },
            "settings": {
                "elevenlabs": {
                    "stability": 0.5,
                    "similarity_boost": 0.5
                }
            }
        }
        
        config = {"vendor": "elevenlabs", "api_key": "test-key"}
        agent = create_voice_agent(config)
        
        assert "voices" in agent.voice_config
        assert "settings" in agent.voice_config
    
    def test_voice_id_mapping(self):
        """Test voice name to ID mapping."""
        mock_voice_config = {
            "voices": {
                "elevenlabs": {
                    "callum": {"id": "voice-id-123"},
                    "rachel": {"id": "voice-id-456"}
                }
            }
        }
        
        config = {"vendor": "elevenlabs", "api_key": "test-key"}
        agent = create_voice_agent(config)
        agent.voice_config = mock_voice_config
        
        voice_id = agent._get_voice_id("callum")
        assert voice_id == "voice-id-123"
        
        # Test fallback to voice name if not found
        voice_id = agent._get_voice_id("unknown")
        assert voice_id == "unknown"
    
    def test_list_voices(self):
        """Test listing available voices."""
        mock_voice_config = {
            "voices": {
                "elevenlabs": {
                    "callum": {"id": "voice-id-123", "description": "Male voice"},
                    "rachel": {"id": "voice-id-456", "description": "Female voice"}
                }
            }
        }
        
        config = {"vendor": "elevenlabs", "api_key": "test-key"}
        agent = create_voice_agent(config)
        agent.voice_config = mock_voice_config
        
        voices = agent.list_voices()
        assert "callum" in voices
        assert "rachel" in voices
        assert voices["callum"]["description"] == "Male voice"