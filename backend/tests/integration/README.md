# Integration Tests

Integration tests verify how multiple components work together and how the system integrates with external services.

## Test Files

### `test_api_endpoints.py` - Safe Integration Tests
**Safe to run** - Uses mocked dependencies, no external calls
- API endpoint behavior and routing
- Request/response serialization  
- Error handling and validation
- Legacy endpoint compatibility

### `test_storyteller_integration.py` - AI Integration Tests  
**COSTS MONEY** - Makes real API calls to AI providers
- Real API integration with Mistral, OpenAI, Google
- JSON response parsing across vendors
- Actual story generation quality testing
- Performance benchmarking

**WARNING: AI tests are excluded from default runs to prevent API costs**

## Running Integration Tests

### Default (Excludes Expensive Tests)
```bash
# Run safe integration tests only
pytest tests/integration/ -v

# Or be more specific - exclude AI tests
pytest tests/integration/ -v -m "integration and not ai_required"
```

### Run AI Tests (Expensive!)
```bash
# 1. Set required API keys
export MISTRAL_API_KEY="your-key-here"
export OPENAI_API_KEY="your-key-here"  
export GOOGLE_API_KEY="your-key-here"

# 2. Run AI integration tests (costs money!)
pytest tests/integration/ -v -m "integration and ai_required"

# Or run specific vendor
pytest tests/integration/test_storyteller_integration.py::TestMistralIntegration -v
```

### Run All Integration Tests
```bash
# Run everything (will skip AI tests if keys not set)
pytest tests/integration/ -v -m integration
```

## Test Markers

- `@pytest.mark.integration` - All integration tests
- `@pytest.mark.ai_required` - Tests requiring AI API keys (cost money)
- `@pytest.mark.slow` - Tests that take > 1 second
- `@pytest.mark.skipif` - Skip if requirements not met

## Cost Management

### AI Test Costs (Approximate)
- **Mistral**: ~$0.001 per test (medium model)
- **OpenAI**: ~$0.0001 per test (GPT-3.5-turbo)
- **Google**: ~$0.0001 per test (Gemini Flash)

**Total cost per full AI test run: ~$0.01**

### Best Practices
1. **Run unit tests first** - catch most issues without cost
2. **Use AI tests sparingly** - only when changing AI integration
3. **Test one vendor at a time** during development
4. **Use manual benchmark tool** for comprehensive comparison

## Troubleshooting

### Common Issues
```bash
# API key not set
pytest tests/integration/test_storyteller_integration.py -v
# SKIPPED - MISTRAL_API_KEY not set

# Fix: Set the required key
export MISTRAL_API_KEY="your-key-here"
```

### Dependencies Missing
```bash
# Install test dependencies  
pip install pytest pytest-asyncio httpx

# Install optional dependencies
pip install python-dotenv
```

## Adding New Integration Tests

### For API Endpoints (Safe)
1. Add to `test_api_endpoints.py`
2. Use `@pytest.mark.integration` marker
3. Mock all external dependencies
4. Test request/response formats

### For AI Integration (Expensive)
1. Add to `test_storyteller_integration.py` 
2. Use all markers: `@pytest.mark.integration`, `@pytest.mark.ai_required`, `@pytest.mark.slow`
3. Add `@pytest.mark.skipif` for API key check
4. Keep tests focused and minimal

Example:
```python
@pytest.mark.integration
@pytest.mark.ai_required
@pytest.mark.slow
@pytest.mark.skipif(not os.getenv("YOUR_API_KEY"), reason="API key not set")
class TestYourAIIntegration:
    @pytest.mark.asyncio
    async def test_your_integration(self):
        # Minimal test that verifies real integration
        pass
```