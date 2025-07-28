# Test Strategy & Structure

This document explains our test strategy, which prioritizes **meaningful tests** that protect critical business logic over achieving high coverage percentages.

## Philosophy: Quality Over Quantity

✅ **We Test:**
- Business logic that can break
- Input validation and security
- Data model constraints
- Edge cases and error conditions
- Critical failure scenarios

❌ **We Don't Test:**
- Simple getters/setters
- Framework code
- External library behavior
- Implementation details

## Test Structure

### Unit Tests (`tests/unit/`) - **49 passing**
Fast, isolated tests that run in < 1 second total.

- **`test_validators.py`** - Core input validation (16 tests)
  - Image validation (base64, size, format)
  - Name validation with Unicode support
  - Age, UUID, story content validation
  
- **`test_types.py`** - Pydantic model validation (14 tests)
  - Domain models (Kid, Story)
  - Request/response types
  - Enum constraints
  
- **`test_business_logic.py`** - Core business logic (13 tests)
  - Story processing logic
  - Security validation
  - Language handling
  - Error formatting
  
- **`test_agents_unit.py`** - Agent logic without API calls (6 tests)
  - Configuration validation
  - Language mapping
  - Voice selection logic

### Integration Tests (`tests/integration/`) 
Tests that involve multiple components or external services.

- **`test_api_endpoints.py`** - API endpoint testing
- **`disabled/test_agents_integration.py`** - AI agent tests (DISABLED)

### Disabled Tests (`tests/integration/disabled/`)
Tests that require API calls and cost money. Only run when necessary.

## Running Tests

### Unit Tests (Recommended - Fast & Free)
```bash
# Run all unit tests (< 1 second)
python -m pytest tests/unit/ -v

# Run specific test file
python -m pytest tests/unit/test_validators.py -v

# Run with coverage (if needed)
python -m pytest tests/unit/ --cov=src --cov-report=term-missing
```

### Integration Tests (Use Sparingly)
```bash
# Run integration tests (slower, may require setup)
python -m pytest tests/integration/ -v

# Skip disabled tests (default behavior)
python -m pytest tests/integration/ -v -m "not skip"
```

### Disabled Tests (Cost Money!)
```bash
# Only run when absolutely necessary
# 1. Set API keys: export OPENAI_API_KEY="..." etc.
# 2. Move file from disabled/ to integration/  
# 3. Remove @pytest.mark.skip decorator
# 4. Run: python -m pytest tests/integration/test_agents_integration.py -v
```

## Test Quality Standards

### ✅ Good Tests
- **Test behavior, not implementation**
- **Cover security vulnerabilities** (XSS, injection, etc.)
- **Test edge cases** (empty input, boundary values)
- **Have clear assertions** that explain failures
- **Run fast** (< 100ms each for unit tests)
- **Are isolated** (no external dependencies)

### Example Good Test
```python
def test_kid_name_security_validation(self):
    """Test kid name validation against malicious input."""
    malicious_inputs = [
        "<script>alert('xss')</script>",
        "Robert'); DROP TABLE kids;--",
        "../../etc/passwd",
    ]
    
    for malicious_input in malicious_inputs:
        with pytest.raises(ValidationError, match="Name can only contain letters"):
            validate_kid_name(malicious_input)
```

### ❌ Avoid These Tests
```python
# Don't test simple getters
def test_kid_name_getter(self):
    kid = Kid(name="Alice")
    assert kid.name == "Alice"  # Useless test

# Don't test external libraries
def test_pydantic_validation(self):
    # Testing Pydantic's validation logic, not ours
    pass

# Don't test implementation details
def test_internal_method_call_count(self):
    # Tests how something works, not what it does
    pass
```

## Coverage Goals

- **Unit Tests**: Focus on critical business logic, not 100% coverage
- **Integration Tests**: Cover major user workflows  
- **Security**: All input validation paths tested
- **Edge Cases**: Boundary conditions and error states

## Adding New Tests

### For New Features
1. **Start with unit tests** for the core logic
2. **Add integration tests** for workflows
3. **Test security implications** of any user input
4. **Consider edge cases** and failure modes

### Test File Naming
- `test_[module]_unit.py` - Pure unit tests
- `test_[module]_integration.py` - Integration tests
- `test_[feature]_logic.py` - Business logic tests

### When to Skip Tests
- Mark expensive tests with `@pytest.mark.skip(reason="Costs money")`
- Move costly tests to `disabled/` folder
- Document how to enable them when needed

## Current Status

✅ **49 Unit Tests Passing** - Core business logic protected  
⚠️ **Integration Tests** - Some failing due to setup issues  
🚫 **AI Agent Tests** - Disabled to prevent API costs  

This test suite protects your most critical business logic without wasting time on trivial tests or burning through API credits during development.