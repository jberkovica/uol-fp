# AI Models Analysis Framework

## Comprehensive Evaluation Methodology - University of London Final Project

This directory contains the systematic analysis framework for evaluating AI models across all three stages of the Smart Visual Storyteller pipeline: image captioning, story generation, and text-to-speech synthesis.

## Research Objective

The study aims to establish evidence-based selection criteria for AI models across the complete storytelling pipeline by evaluating performance across multiple dimensions including computational efficiency, cost-effectiveness, output quality, and reliability. The research provides quantitative and qualitative analysis to support informed model selection for practical deployment in educational applications.

## Analysis Framework Structure

```
models_analysis/
├── README.md                           # Analysis methodology documentation
├── requirements.txt                    # Python dependencies
├── data/                              # Test datasets
│   ├── annotations.json              # Ground truth annotations
│   ├── drawing_*.jpeg                # Children's artwork samples
│   └── toy_*.jpeg                    # Toy photograph samples
├── scripts/                          # Data collection scripts
│   ├── 01_image_captioning_collect.py  # Image-to-text model evaluation
│   ├── 02_story_generation_collect.py  # Text generation model evaluation
│   ├── 03_tts_collect.py               # Text-to-speech model evaluation
│   └── cost_calculator.py              # Cost analysis utilities
├── results/                           # Analysis outputs by model type
│   ├── image_captioning/             # Caption analysis results
│   ├── story_generation/             # Story generation analysis
│   └── tts/                         # TTS analysis results
└── analysis/                         # Research notebooks
```

## Models Under Evaluation

### 1. Image Captioning Models

Contemporary vision-language models evaluated for converting visual content to descriptive text:

**Commercial API Models:**

-   **OpenAI GPT-4o Vision** - Established multimodal model with proven performance
-   **Google Gemini 2.5 Flash Preview** - Latest multimodal reasoning model
-   **Google Gemini 2.0 Flash** - High-performance vision model optimized for speed

**Open Source Models:**

-   **Replicate LLaVA 1.5 (7B)** - Large language and vision assistant
-   **BLIP** - Bidirectional language-image pre-training model
-   **BLIP-2** - Enhanced version with improved performance

### 2. Story Generation Models

Advanced language models evaluated for creative narrative generation:

**Commercial API Models:**

-   **OpenAI GPT-4o** - General-purpose language model with strong creative capabilities
-   **Anthropic Claude 3.7 Sonnet** - Creative writing specialist model
-   **Google Gemini 2.5 Flash** - Fast model with extensive context capabilities
-   **Google Gemini 2.0 Flash** - Balanced performance model

**Open Source Models:**

-   **Meta Llama 4 variants** - Latest open source language models
-   **Other Replicate models** - Community-maintained alternatives

### 3. Text-to-Speech Models

High-quality TTS systems evaluated for child-friendly audio generation:

**Premium Services:**

-   **ElevenLabs Multilingual v2** - Premium voice synthesis with natural intonation
-   **ElevenLabs Flash v2.5** - Low-latency option for real-time applications
-   **OpenAI TTS** - High-quality, reliable text-to-speech

**Integrated Solutions:**

-   **Google Cloud TTS** - Enterprise-grade speech synthesis
-   **Azure Speech Services** - Microsoft's TTS platform

## Evaluation Methodology

### Quantitative Metrics

**Performance Assessment:**

-   Response latency measurement under standard conditions
-   Computational resource requirements analysis
-   API reliability and consistency evaluation
-   Cost per request calculation with volume considerations

**Quality Metrics:**

-   Output length and complexity analysis
-   Content accuracy and relevance assessment
-   Technical quality measurements (audio fidelity for TTS)

### Qualitative Assessment

**Content Analysis:**

-   **Image Captioning**: Object identification, scene description accuracy, artistic medium recognition
-   **Story Generation**: Narrative coherence, creativity level, age-appropriateness, engagement potential
-   **Text-to-Speech**: Voice naturalness, emotional expression, clarity, child-friendliness

**Contextual Evaluation:**

-   Domain-specific performance for children's content
-   Cultural sensitivity and appropriateness
-   Educational value assessment

## Analysis Pipeline

### Data Collection Protocol

1. **Standardized Testing**: Identical datasets processed by all models
2. **Performance Monitoring**: Comprehensive timing and resource tracking
3. **Quality Documentation**: Systematic output evaluation and annotation
4. **Cost Tracking**: Real-time expense monitoring with detailed breakdowns

### Statistical Analysis

1. **Exploratory Data Analysis**: Dataset characterization and quality assessment
2. **Comparative Performance Analysis**: Statistical comparison across models
3. **Cost-Benefit Analysis**: Economic evaluation framework
4. **Multi-Criteria Ranking**: Weighted scoring system for model selection

## Setup and Execution

### Prerequisites

-   Python 3.11 or higher
-   Virtual environment capability
-   API credentials for all evaluated services

### Installation

```bash
# Navigate to analysis directory
cd models_analysis

# Install required dependencies
pip install -r requirements.txt
```

### Environment Configuration

Create `.env` file with required API credentials:

```bash
# Core AI Services
OPENAI_API_KEY=your_openai_key
GOOGLE_API_KEY=your_google_key
ANTHROPIC_API_KEY=your_anthropic_key
REPLICATE_API_TOKEN=your_replicate_token

# TTS Services
ELEVENLABS_API_KEY=your_elevenlabs_key
AZURE_SPEECH_KEY=your_azure_key
AZURE_SPEECH_REGION=your_azure_region
```

### Analysis Execution

#### Individual Model Type Analysis

```bash
# Image captioning evaluation
python scripts/01_image_captioning_collect.py

# Story generation evaluation
python scripts/02_story_generation_collect.py

# Text-to-speech evaluation
python scripts/03_tts_collect.py
```

#### Comprehensive Analysis

```bash
# Execute complete analysis pipeline
python run_analysis.py

# Launch analysis notebooks
jupyter lab analysis/notebooks/
```

## Evaluation Criteria

### Primary Assessment Dimensions

**Technical Performance:**

-   Processing speed and efficiency
-   Output quality and accuracy
-   System reliability and consistency
-   Scalability considerations

**Economic Viability:**

-   Cost per request analysis
-   Volume pricing evaluation
-   Total cost of ownership projections
-   Budget constraint compatibility

**Application Suitability:**

-   Child-appropriate content generation
-   Educational value contribution
-   User experience quality
-   Integration complexity assessment

### Secondary Considerations

-   Documentation quality and developer support
-   Community ecosystem and longevity
-   Customization and fine-tuning capabilities
-   Privacy and data handling policies

## Expected Research Outcomes

### Academic Contributions

1. **Systematic Evaluation Framework**: Reproducible methodology for multimodal AI assessment
2. **Comparative Performance Analysis**: Evidence-based model performance documentation
3. **Cost-Effectiveness Modeling**: Economic framework for educational technology deployment
4. **Selection Criteria Development**: Data-driven decision-making guidelines

### Practical Applications

1. **Model Recommendation System**: Clear guidance for optimal model selection
2. **Implementation Best Practices**: Deployment strategies and integration patterns
3. **Performance Benchmarks**: Reference standards for future evaluations
4. **Risk Assessment Framework**: Reliability and fallback planning guidelines

## Research Standards and Reproducibility

### Methodology Documentation

-   Comprehensive parameter logging for all evaluations
-   Standardized testing protocols across model types
-   Statistical validation of findings
-   Transparent limitation acknowledgment

### Data Management

-   Systematic result storage and organization
-   Version control for all analysis scripts
-   Raw data preservation for peer review
-   Privacy-compliant data handling practices

## Analysis Status

**Current Progress:**

-   Image Captioning: Evaluation completed with comprehensive results
-   Story Generation: Data collection in progress
-   Text-to-Speech: Preparation phase, implementation planned

**Analysis Outputs:**

-   Raw performance data available in CSV format
-   Statistical summaries and visualizations
-   Model ranking results with detailed scoring
-   Cost analysis reports with deployment projections

---

**Research Institution**: University of London  
**Academic Year**: 2024/2025  
**Project Type**: Final Research Project  
**Analysis Framework**: Comprehensive AI Model Evaluation
