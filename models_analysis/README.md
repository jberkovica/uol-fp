# Mira Storyteller - Comprehensive AI Model Analysis

Updated for 2025 with extensive evaluation of state-of-the-art models across image captioning, story generation, and text-to-speech capabilities.

## Project Overview

This comprehensive analysis evaluates contemporary AI models across three critical pipeline stages for the Mira Storyteller application:

1. **Image Captioning**: Converting children's drawings into descriptive text
2. **Story Generation**: Creating engaging, age-appropriate narratives
3. **Text-to-Speech**: Producing child-friendly audio narration

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
# Core Providers
OPENAI_API_KEY=your_openai_key_here
GOOGLE_API_KEY=your_google_ai_key_here
ANTHROPIC_API_KEY=your_anthropic_key_here

# Additional Providers
REPLICATE_API_TOKEN=your_replicate_token_here
ELEVENLABS_API_KEY=your_elevenlabs_key_here
MISTRAL_API_KEY=your_mistral_key_here
DEEPSEEK_API_KEY=your_deepseek_key_here
```

## Models Evaluated

### Image Captioning Models

**Tier 1 - Premium Vision Models**:

-   **OpenAI**: GPT-4o Vision, GPT-4o-mini Vision
-   **Google**: Gemini 2.5 Pro Vision, Gemini 2.0 Flash Vision
-   **Anthropic**: Claude 3.5 Sonnet Vision, Claude 3.5 Haiku Vision

**Tier 2 - Specialized Vision Models (via Replicate)**:

-   **LLaVA**: LLaVA-1.5-7B, LLaVA-1.6-34B
-   **BLIP**: BLIP-2, InstructBLIP, various BLIP variants

### Story Generation Models

**Tier 1 - Premium Language Models**:

-   **OpenAI**: GPT-4o, GPT-4o-mini, GPT-4-turbo
-   **Anthropic**: Claude 3.5 Sonnet, Claude 3.5 Haiku
-   **Google**: Gemini 2.5 Pro, Gemini 2.0 Flash, Gemini Pro
-   **Mistral**: Mistral Large, Mistral Medium
-   **DeepSeek**: DeepSeek-V3, DeepSeek-Chat

**Tier 2 - Open Source Models (via Replicate)**:

-   **Meta**: Llama 3.1 (70B, 8B), Llama 3.2 variants
-   **Fine-tuned Models**: Various creative writing specialized models

### Text-to-Speech Models

**Premium TTS Services**:

-   **OpenAI**: TTS-1, TTS-1-HD (multiple voices)
-   **ElevenLabs**: v3 Turbo, v3 Multilingual (child-friendly voices)
-   **Google Cloud**: Neural2, WaveNet, Standard voices

## Current Pricing Analysis (2025)

### Language Models (per 1M tokens)

-   **GPT-4o**: $2.50/$10.00 (input/output)
-   **Claude 3.5 Sonnet**: $3.00/$15.00 (input/output)
-   **Gemini 2.5 Pro**: $2.50/$15.00 (input/output)
-   **Mistral Large**: $2.00/$6.00 (input/output)
-   **DeepSeek-V3**: $0.14/$0.28 (input/output)
-   **Llama models**: ~$0.005-0.015 per prediction (Replicate)

### Vision Models (per image + tokens)

-   **GPT-4o Vision**: $2.50/$10.00 per 1M tokens + image processing
-   **Gemini Vision**: $2.50/$15.00 per 1M tokens + image processing
-   **Claude Vision**: $3.00/$15.00 per 1M tokens + image processing

### Text-to-Speech (per character/word)

-   **OpenAI TTS**: $15.00 per 1M characters
-   **ElevenLabs**: $0.18-0.24 per 1K characters (varies by model)
-   **Google Cloud**: $4.00-16.00 per 1M characters

**Recommended evaluation budget**: $50-100 for comprehensive testing across all models

## Usage

All scripts support real-time output monitoring while saving logs for later analysis using the `tee` command.

### 1. Collect Image Captioning Data

```bash
cd scripts
python -u 01_image_captioning_collect.py | tee 01_image_captioning_collect.log
```

Evaluates all vision models on children's drawings and photos with metrics for:

-   Accuracy and detail level
-   Child-appropriate language
-   Creative element recognition
-   Cost per image analysis

### 2. Collect Story Generation Data

```bash
cd scripts
python -u 02_story_generation_collect.py | tee 02_story_generation_collect.log
```

Tests story generation across all language models with evaluation of:

-   Narrative quality and creativity
-   Age-appropriate content
-   Story structure and coherence
-   Cost per story generation

### 3. Collect TTS Comparative Analysis

```bash
cd scripts
python -u 03_tts_collect.py | tee 03_tts_collect.log
```

Comprehensive TTS evaluation including:

-   Voice quality and naturalness
-   Child-friendly voice options
-   Audio generation speed
-   Cost per story narration

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
├── scripts/                    # Data collection scripts
│   ├── 00_test_api_keys.py    # API connectivity testing
│   ├── 01_image_captioning_collect.py
│   ├── 02_story_generation_collect.py
│   ├── 03_tts_collect.py
│   └── cost_calculator.py     # Cost analysis utilities
├── data/                      # Input datasets and test materials
├── results/                   # Generated analysis results
│   ├── image_captioning/     # Vision model outputs
│   ├── story_generation/     # Language model outputs
│   └── tts/                  # Audio generation results
└── analysis/                 # Research analysis and reports
    ├── notebooks/            # Jupyter analysis notebooks
    └── dev/                  # Development analysis files
```

## Evaluation Methodology

### Image Captioning Evaluation

-   **Accuracy**: Correctness of identified elements
-   **Creativity**: Recognition of imaginative elements
-   **Child-Appropriateness**: Language suitable for children
-   **Detail Level**: Comprehensiveness of descriptions
-   **Cost Efficiency**: Price per image analysis

### Story Generation Evaluation

-   **Narrative Quality**: Story structure and flow
-   **Creativity**: Originality and imagination
-   **Age Appropriateness**: Content suitable for target age groups
-   **Engagement**: Potential to captivate young audiences
-   **Safety**: Absence of inappropriate content
-   **Cost Efficiency**: Price per story generation

### Text-to-Speech Evaluation

-   **Voice Quality**: Naturalness and clarity
-   **Child Appeal**: Suitability for young listeners
-   **Pronunciation**: Accuracy with creative names/words
-   **Speed**: Audio generation time
-   **Cost Efficiency**: Price per story narration

## Key Research Findings

### Optimal Model Selection

-   **Image Captioning**: Evidence-based recommendations for production use
-   **Story Generation**: Cost-quality balance analysis across providers
-   **Text-to-Speech**: Child-friendly voice optimization

### Cost-Effectiveness Analysis

-   Comprehensive pricing comparison across all providers
-   Usage pattern optimization for sustainable operation
-   Budget recommendations for different deployment scales

### Performance Benchmarking

-   Standardized evaluation metrics across model categories
-   Quality scoring frameworks for objective comparison
-   Reliability and consistency analysis

## Security Notes

-   Never commit `.env` files to version control
-   Monitor API usage and set billing limits
-   Use separate API keys for development/production
-   Rotate keys periodically
-   Implement rate limiting for production deployments

## Analysis Features

-   **Comprehensive Cost Analysis**: Detailed pricing comparison across all providers
-   **Quality Metrics**: Standardized evaluation criteria for each model type
-   **Performance Benchmarking**: Speed and reliability testing
-   **Academic Reporting**: Research-grade analysis and documentation
-   **Interactive Visualizations**: Data exploration and presentation tools
-   **Production Recommendations**: Evidence-based model selection guidance

---

_Updated January 2025 with comprehensive evaluation of 25+ models across three AI pipeline stages_
