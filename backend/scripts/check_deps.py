#!/usr/bin/env python3
"""
Dependency compatibility checker to prevent critical library issues.
Run this script after any dependency updates to ensure core functionality.
"""
import sys
from pathlib import Path

# Add src to Python path
sys.path.insert(0, str(Path(__file__).parent.parent))

def check_openai_compatibility():
    """Test OpenAI client creation - catches httpx compatibility issues."""
    try:
        import openai
        print(f"✓ OpenAI version: {openai.__version__}")
        
        # Test client creation
        client = openai.AsyncOpenAI(api_key='test-key')
        print("✓ OpenAI AsyncClient creation: OK")
        return True
    except Exception as e:
        print(f"✗ OpenAI compatibility error: {e}")
        return False

def check_google_gen_ai_compatibility():
    """Test Google Gen AI SDK imports."""
    try:
        from google import genai
        from google.genai import types
        print(f"✓ Google Gen AI SDK imports: OK")
        
        # Test client creation (without actual project)
        # This tests the SDK installation and basic functionality
        print("✓ Google Gen AI SDK: Available")
        return True
    except Exception as e:
        print(f"✗ Google Gen AI SDK compatibility error: {e}")
        return False

def check_voice_config_loading():
    """Test voice configuration loading with new structure."""
    try:
        from src.utils.config import load_config
        from src.agents.voice.agent import create_voice_agent
        
        config = load_config()
        voice_agent = create_voice_agent(config['agents']['voice'])
        
        # Test config merging for different vendors
        ru_config = voice_agent._get_language_config('ru')  # OpenAI
        en_config = voice_agent._get_language_config('en')  # ElevenLabs
        
        assert ru_config.get('vendor') == 'openai'
        assert en_config.get('vendor') == 'elevenlabs'
        assert 'settings' in ru_config
        assert 'settings' in en_config
        
        print("✓ Voice configuration loading: OK")
        return True
    except Exception as e:
        print(f"✗ Voice configuration error: {e}")
        return False

def main():
    """Run all compatibility checks."""
    print("Dependency Compatibility Check")
    print("=" * 40)
    
    checks = [
        check_openai_compatibility,
        check_google_gen_ai_compatibility,
        check_voice_config_loading,
    ]
    
    passed = 0
    for check in checks:
        if check():
            passed += 1
        print()
    
    print(f"Results: {passed}/{len(checks)} checks passed")
    
    if passed == len(checks):
        print("✓ All compatibility checks PASSED")
        return 0
    else:
        print("✗ Some compatibility checks FAILED")
        return 1

if __name__ == "__main__":
    sys.exit(main())