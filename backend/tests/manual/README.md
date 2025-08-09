# Manual Testing Tools

This folder contains manual testing and benchmarking tools that are NOT part of the automated test suite.
These are utilities for evaluating AI vendors, performance testing, and quality assessment.

## Storyteller Vendor Benchmark

Compare different AI vendors for story generation quality and performance.

### Quick Usage

```bash
# Test default vendors (Mistral, OpenAI, Google) with 1 scenario
python tests/manual/storyteller_vendor_benchmark.py --quick

# Test all configured vendors
python tests/manual/storyteller_vendor_benchmark.py --all

# Detailed test with 3 scenarios per vendor
python tests/manual/storyteller_vendor_benchmark.py --detailed

# Test specific vendor
python tests/manual/storyteller_vendor_benchmark.py --vendor openai-3.5

# Test with custom model
python tests/manual/storyteller_vendor_benchmark.py --vendor openai --model gpt-4
```

### Available Vendors

- `mistral` - Mistral Medium (reliable, consistent)
- `gpt-4o-mini` - GPT-4o-mini (best quality/cost balance) 
- `gpt-3.5-turbo` - GPT-3.5-turbo (fast, lower quality)
- `google` - Gemini 2.0 Flash (fastest, markdown format)
- `anthropic` - Claude 3 Haiku (if configured)

### Output

- Console output with speed and quality rankings
- Saved results file with timestamp in same directory
- Metrics include: processing time, word count, JSON compliance, quality score

### Requirements

- Set API keys in `.env` file:
  - `MISTRAL_API_KEY`
  - `OPENAI_API_KEY`
  - `GOOGLE_API_KEY`
  - `ANTHROPIC_API_KEY` (optional)

### When to Use

- Before switching AI vendors
- Testing new models
- Cost/performance optimization
- Quality assurance after prompt changes