# Smart Visual Storyteller for Children

## University of London Final Project

### Project Overview

This repository contains the complete implementation of a Smart Visual Storyteller system that transforms children's drawings and photos into engaging, narrated bedtime stories. The project is structured as an academic research initiative with systematic AI model evaluation followed by practical application development.

### System Architecture

The Smart Visual Storyteller employs a three-stage AI pipeline:

1. **Image-to-Text**: Convert children's drawings/photos into descriptive captions
2. **Text Generation**: Transform captions into creative, age-appropriate stories
3. **Text-to-Speech**: Generate child-friendly narrated audio

### Repository Structure

```
uol-fp-mira/
├── models_analysis/          # Comprehensive AI model evaluation (Current Phase)
│   ├── scripts/              # Data collection for all 3 model types
│   │   ├── 01_image_captioning_collect.py
│   │   ├── 02_story_generation_collect.py
│   │   └── 03_tts_collect.py
│   ├── data/                 # Test datasets for evaluation
│   ├── results/              # Analysis outputs for all model types
│   └── analysis/             # Research notebooks and reports
├── app/                      # Application implementation (Future Phase)
│   └── [Future application code]
├── venv/                     # Python virtual environment
└── README.md                 # This overview document
```

### Project Phases

#### Phase 1: Model Analysis and Evaluation (Current)

**Location**: `models_analysis/`

Systematic evaluation of contemporary AI models across all three pipeline stages:

-   **Image Captioning Models**: GPT-4o Vision, Gemini 2.5/2.0 Flash, LLaVA, BLIP variants
-   **Story Generation Models**: GPT-4o, Claude Sonnet, Gemini models, Llama variants
-   **Text-to-Speech Models**: ElevenLabs, OpenAI TTS, Google TTS variants

**Evaluation Criteria**:

-   Performance quality and accuracy
-   Computational efficiency
-   Cost-effectiveness
-   Reliability and consistency

#### Phase 2: Application Development (Planned)

**Location**: `app/`

Implementation of the complete storytelling system:

-   User interface for image upload
-   AI pipeline integration
-   Story generation and audio output
-   Child-friendly design and experience

### Academic Objectives

This project serves as a University of London final project with dual academic and practical goals:

**Research Contributions**:

-   Systematic evaluation methodology for multimodal AI pipelines
-   Cost-effectiveness analysis for AI model deployment
-   Evidence-based model selection framework
-   Performance benchmarking across model categories

**Practical Applications**:

-   Educational technology for children
-   Creative storytelling enhancement
-   Accessibility tool development
-   Parent-child engagement platform

### Setup Instructions

#### Prerequisites

-   Python 3.11+
-   Virtual environment capability
-   API credentials for evaluated models

#### Quick Start

```bash
# Clone repository
git clone [repository-url]
cd uol-fp-mira

# Set up virtual environment
python3 -m venv venv
source venv/bin/activate  # macOS/Linux

# Install dependencies
pip install -r models_analysis/requirements.txt

# Configure API credentials
# Create models_analysis/.env with required API keys
```

### Current Status

**Models Analysis**: Active research and evaluation phase

-   ✅ Image captioning evaluation completed
-   🔄 Story generation evaluation in progress
-   📅 Text-to-speech evaluation planned

**Application Development**: Future implementation phase

-   📅 Planned following model analysis completion
-   Focus on child-friendly interface design
-   Integration of optimal model selection

### Documentation

-   **Models Analysis**: See `models_analysis/README.md` for detailed evaluation methodology
-   **Results**: Comprehensive analysis outputs in `models_analysis/results/`
-   **Research**: Academic notebooks and reports in `models_analysis/analysis/`

### Academic Context

**Institution**: University of London  
**Project Type**: Final Research Project  
**Academic Year**: 2024/2025  
**Focus Areas**: AI Model Evaluation, Educational Technology, Multimodal Systems

### Future Development

The project roadmap includes:

-   Completion of comprehensive model evaluation
-   Evidence-based optimal model selection
-   Full application development and deployment
-   User experience testing and refinement
-   Academic publication of research findings

---

This project represents the intersection of academic research and practical application development, providing both scholarly contribution to AI model evaluation and a functional educational tool for children and families.
