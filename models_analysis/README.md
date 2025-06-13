# Mira Storyteller App

Updated for 2025 with the latest state-of-the-art models and comprehensive evaluation framework.

## Quick Setup

### 1. Install Dependencies

```bash
cd models_analysis
pip install -r requirements.txt
```

### 2. Environment Setup

Create a `.env` file in the `scripts/` directory:

```bash
# Create .env file
cd scripts
touch .env
```

Add your API keys to the `.env` file:

```bash
OPENAI_API_KEY=your_openai_key_here
GOOGLE_API_KEY=your_google_ai_key_here
ANTHROPIC_API_KEY=your_anthropic_key_here
REPLICATE_API_TOKEN=your_replicate_token_here
```

### Image Captioning Models

-   **OpenAI**: GPT-4o Vision
-   **Google**: Gemini 2.5 Pro, Gemini 2.0 Flash
-   **Replicate**: BLIP, BLIP-2, LLaVA-1.5-7B

### Story Generation Models

-   **OpenAI**: GPT-4o, GPT-4o-mini
-   **Anthropic**: Claude 3.7 Sonnet, Claude 3.5 Haiku
-   **Google**: Gemini 2.5 Pro, Gemini 2.0 Flash

## Current Pricing (2025)

-   GPT-4o: $2.50/$10.00 per 1M tokens (in/out)
-   Claude 3.7 Sonnet: $3.00/$15.00 per 1M tokens (in/out)
-   Gemini 2.5 Pro: $2.50/$15.00 per 1M tokens (in/out)
-   Replicate models: ~$0.005-0.015 per prediction

**Recommended budget**: $20-50 for comprehensive testing

## Usage

All scripts support real-time output monitoring while saving logs for later analysis using the `tee` command.

### 1. Collect Image Captioning Data

```bash
cd scripts
python -u 01_image_captioning_collect.py | tee 01_image_captioning_collect.log
```

### 2. Collect Story Generation Data

```bash
cd scripts
python -u 02_story_generation_collect.py | tee 02_story_generation_collect.log
```

### 3. Collect TTS Comparative Analysis

```bash
cd scripts
python -u 03_tts_collect.py | tee 03_tts_collect.log
```

### 4. Run Analysis

```bash
cd analysis/notebooks
jupyter lab
# Open and run the analysis notebooks
```

**Note**: The `-u` flag ensures unbuffered output for real-time monitoring, while `tee` saves the output to log files for later review and debugging.

## Project Structure

```
models_analysis/
├── scripts/           # Data collection scripts
│   ├── env.example   # Environment variables template
│   ├── 01_image_captioning_collect.py
│   ├── 02_story_generation_collect.py
│   └── cost_calculator.py
├── data/             # Input data and annotations
├── results/          # Generated CSV results
└── analysis/         # Jupyter notebooks for analysis
```

## Security Notes

-   Never commit `.env` files to version control
-   Monitor API usage and set billing limits
-   Use separate API keys for development/production
-   Rotate keys periodically

## Analysis Features

-   Comprehensive cost analysis across providers
-   Quality metrics for generated content
-   Performance benchmarking
-   Academic-style reporting
-   Interactive visualizations

---

_Updated December 2025 with latest SOTA models and pricing_
