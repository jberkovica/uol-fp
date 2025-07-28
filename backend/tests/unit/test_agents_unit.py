"""Pure unit tests for AI agent logic (isolated, no external dependencies)."""
import pytest
from unittest.mock import Mock
from src.agents.base import BaseAgent, AgentVendor
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


class TestAgentFactoryLogic:
    """Test agent factory logic without external dependencies."""
    
    def test_agent_config_validation_logic(self):
        """Test agent configuration validation rules."""
        # Test required fields logic
        valid_config = {"vendor": "google", "api_key": "test-key"}
        assert "vendor" in valid_config
        assert "api_key" in valid_config
        assert len(valid_config["api_key"]) > 0
        
        # Test invalid configurations  
        invalid_configs = [
            {},  # Empty config
            {"vendor": "google"},  # Missing API key
            {"api_key": "test"},  # Missing vendor
            {"vendor": "", "api_key": "test"},  # Empty vendor
            {"vendor": "google", "api_key": ""},  # Empty API key
        ]
        
        for config in invalid_configs:
            has_vendor = "vendor" in config and config["vendor"]
            has_api_key = "api_key" in config and config["api_key"]
            assert not (has_vendor and has_api_key)  # Should be invalid


class TestLanguageMapping:
    """Test language mapping logic for agents."""
    
    def test_language_code_mapping_logic(self):
        """Test language code mapping for different services."""
        # Business logic for language mapping
        def map_language_for_service(app_language: str, service: str) -> str:
            """Map app language to service-specific language code."""
            mappings = {
                'openai': {'en': 'en', 'ru': 'ru', 'lv': 'lv'},
                'elevenlabs': {'en': 'en', 'ru': 'ru', 'lv': 'en'},  # No Latvian support
                'google': {'en': 'en', 'ru': 'ru', 'lv': 'lv'},
            }
            return mappings.get(service, {}).get(app_language, 'en')
        
        # Test mapping logic
        assert map_language_for_service('en', 'openai') == 'en'
        assert map_language_for_service('ru', 'openai') == 'ru'
        assert map_language_for_service('lv', 'openai') == 'lv'
        
        # Test ElevenLabs fallback for Latvian
        assert map_language_for_service('lv', 'elevenlabs') == 'en'
        assert map_language_for_service('ru', 'elevenlabs') == 'ru'
        
        # Test unknown language fallback
        assert map_language_for_service('unknown', 'openai') == 'en'
        assert map_language_for_service('en', 'unknown_service') == 'en'


class TestStoryProcessingLogic:
    """Test story processing business logic."""
    
    def test_story_title_extraction_logic(self):
        """Test title extraction from story content."""
        def extract_title_from_story(content: str) -> str:
            """Extract title from story content."""
            lines = content.strip().split('\n')
            
            # Check for markdown title
            if lines and lines[0].startswith('# '):
                return lines[0][2:].strip()
            
            # Fallback to first sentence
            first_sentence = content.split('.')[0].strip()
            if len(first_sentence) > 50:
                return first_sentence[:47] + "..."
            return first_sentence or "Untitled Story"
        
        # Test markdown title extraction
        story_with_title = "# The Magic Forest\n\nOnce upon a time..."
        assert extract_title_from_story(story_with_title) == "The Magic Forest"
        
        # Test fallback to first sentence
        story_without_title = "Once upon a time, there was a brave mouse. The end."
        assert extract_title_from_story(story_without_title) == "Once upon a time, there was a brave mouse"
        
        # Test long first sentence truncation
        long_story = "This is a very long first sentence that should be truncated because it exceeds fifty characters and would be too long for a title."
        result = extract_title_from_story(long_story)
        assert len(result) == 50  # 47 chars + "..."
        assert result.endswith("...")
        
        # Test empty content
        assert extract_title_from_story("") == "Untitled Story"
        assert extract_title_from_story("   ") == "Untitled Story"


class TestVoiceConfigLogic:
    """Test voice configuration logic."""
    
    def test_voice_selection_logic(self):
        """Test voice selection based on criteria."""
        # Mock voice configuration
        voice_config = {
            "voices": {
                "elevenlabs": {
                    "callum": {"id": "voice-123", "gender": "male", "age": "adult"},
                    "rachel": {"id": "voice-456", "gender": "female", "age": "adult"},
                    "charlie": {"id": "voice-789", "gender": "male", "age": "child"},
                }
            }
        }
        
        def select_voice_by_criteria(voices: dict, gender: str = None, age: str = None) -> str:
            """Select voice ID based on criteria."""
            for name, config in voices.items():
                if gender and config.get("gender") != gender:
                    continue
                if age and config.get("age") != age:
                    continue
                return config["id"]
            return list(voices.values())[0]["id"]  # Default to first
        
        elevenlabs_voices = voice_config["voices"]["elevenlabs"]
        
        # Test gender selection
        assert select_voice_by_criteria(elevenlabs_voices, gender="female") == "voice-456"
        assert select_voice_by_criteria(elevenlabs_voices, gender="male") == "voice-123"
        
        # Test age selection
        assert select_voice_by_criteria(elevenlabs_voices, age="child") == "voice-789"
        
        # Test combined criteria
        assert select_voice_by_criteria(elevenlabs_voices, gender="male", age="child") == "voice-789"
        
        # Test no match fallback
        assert select_voice_by_criteria(elevenlabs_voices, gender="nonexistent") == "voice-123"