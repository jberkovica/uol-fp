# Mira - Smart Visual Storyteller for Children

## University of London Final Project

### Project Overview

Mira is an interactive Smart Visual Storyteller system that transforms children's drawings and photos into engaging, narrated bedtime stories. This project combines comprehensive AI model research with practical application development, creating an educational tool that fosters creativity, imagination, and literacy in children.

The project is structured as an academic research initiative with systematic AI model evaluation followed by complete application implementation.

### System Architecture

Mira employs a three-stage AI pipeline integrated into a full-stack application:

1. **Image Analysis**: Convert children's drawings/photos into descriptive captions using computer vision
2. **Story Generation**: Transform image descriptions into creative, age-appropriate stories
3. **Text-to-Speech**: Generate child-friendly narrated audio with synchronized playback

### Repository Structure

```
uol-fp-mira/
├── models_analysis/          # Comprehensive AI model evaluation (COMPLETED)
│   ├── scripts/              # Data collection scripts for all 3 model types
│   ├── data/                 # Test datasets and evaluation materials
│   ├── results/              # Analysis outputs and performance metrics
│   └── analysis/             # Research notebooks and comprehensive reports
├── app/                      # Full application implementation (IN PROGRESS)
│   ├── mira_storyteller/     # Main Flutter mobile application
│   ├── flutter_app/          # Additional Flutter development
│   ├── backend/              # Python FastAPI backend service
│   ├── README.md             # Application-specific documentation
│   └── PROGRESS.md           # Detailed development log
├── venv/                     # Python virtual environment
└── README.md                 # This overview document
```

### Project Status & Phases

#### Phase 1: Model Analysis and Evaluation (COMPLETED)

**Location**: `models_analysis/`

Comprehensive evaluation of contemporary AI models across all three pipeline stages:

**Image Captioning Models Evaluated**:

-   **Premium Vision**: GPT-4o Vision, Gemini 2.5/2.0 Flash, Claude 3.5 Sonnet Vision
-   **Specialized Models**: LLaVA variants, BLIP-2, InstructBLIP (via Replicate)

**Story Generation Models Evaluated**:

-   **Premium Models**: GPT-4o, Claude 3.5 Sonnet, Gemini Pro/Flash, Mistral Large, DeepSeek-V3
-   **Open Source Models**: Llama 3.1/3.2 variants (via Replicate)

**Text-to-Speech Models Evaluated**:

-   **Premium TTS**: OpenAI TTS-1/HD, ElevenLabs v3, Google Cloud Neural2

**Key Research Findings**:

-   Optimal model selection for cost-effectiveness and quality
-   Performance benchmarking across model categories
-   Evidence-based recommendations for production deployment
-   Comprehensive cost analysis for sustainable operation

#### Phase 2: Application Development (IN PROGRESS)

**Location**: `app/`

**Completed Features**:

-   Flutter mobile application with child-friendly UI
-   Parent dashboard for story review and approval
-   Complete user workflow from image upload to story playback
-   FastAPI backend with AI service integration
-   Mock data services for development and testing
-   Story generation, review, and approval workflows

**Current Implementation**:

-   **Frontend**: Flutter cross-platform mobile app
-   **Backend**: Python FastAPI with AI model integration
-   **Services**: Image analysis, story generation, text-to-speech
-   **Features**: User profiles, parental controls, story library

**In Development**:

-   Backend API integration (replacing mock services)
-   Audio playback with synchronized text highlighting
-   Enhanced story personalization features
-   Production deployment configuration

### Features

#### For Children

-   **Intuitive Image Upload**: Kid-friendly interface for uploading drawings or photos
-   **Interactive Story Experience**: Engaging narrated stories with visual elements
-   **Personal Story Library**: Collection of their own generated stories
-   **Safe Environment**: Child-appropriate content with parental oversight

#### For Parents

-   **Story Review Dashboard**: Approve or modify generated stories before children access them
-   **Content Control**: Ensure all stories meet family standards and values
-   **Progress Tracking**: Monitor child's creative development and engagement
-   **Notification System**: Alerts for new stories requiring review

### Technical Stack

#### Frontend

-   **Flutter**: Cross-platform UI framework for iOS and Android
-   **Dart**: Programming language with modern reactive patterns

#### Backend

-   **Python 3.11+**: Server-side development
-   **FastAPI**: High-performance API framework
-   **Google Cloud Services**: Storage and AI model integration

#### AI/ML Integration

-   **Image Analysis**: Optimized vision models for child artwork recognition
-   **Story Generation**: Creative language models fine-tuned for children's content
-   **Text-to-Speech**: Child-friendly voice synthesis with natural intonation

### Setup Instructions

#### Prerequisites

-   Python 3.11+
-   Flutter SDK (version 3.0+)
-   Dart (version 2.17+)
-   API credentials for AI services

#### Models Analysis Setup

```bash
# Clone repository
git clone [repository-url]
cd uol-fp-mira

# Set up Python environment
python3 -m venv venv
source venv/bin/activate  # macOS/Linux

# Install analysis dependencies
pip install -r models_analysis/requirements.txt

# Configure API credentials
# Create models_analysis/.env with required API keys
```

#### Application Setup

**Flutter Frontend**:

```bash
# Navigate to Flutter app
cd app/mira_storyteller

# Get dependencies
flutter pub get

# Run the app
flutter run
```

**Python Backend**:

```bash
# Navigate to backend
cd app/backend

# Install dependencies
pip install -r requirements.txt

# Start development server
python main.py
```

### Academic Contributions

This project serves as a University of London final project with significant academic and practical contributions:

**Research Contributions**:

-   Systematic evaluation methodology for multimodal AI pipelines
-   Cost-effectiveness analysis framework for AI model deployment
-   Performance benchmarking across contemporary AI models
-   Evidence-based model selection for educational applications

**Practical Applications**:

-   Educational technology platform for creative development
-   Parent-child engagement tool with safety controls
-   Accessibility enhancement for diverse learning styles
-   Scalable framework for AI-powered educational content

### Documentation

-   **Application Details**: See `app/README.md` for implementation specifics
-   **Development Progress**: Detailed log in `app/PROGRESS.md`
-   **Model Analysis**: Comprehensive evaluation in `models_analysis/`
-   **Research Results**: Academic findings in `models_analysis/analysis/`

### Academic Context

**Institution**: University of London  
**Project Type**: Final Research Project  
**Academic Year**: 2024/2025  
**Focus Areas**: AI Model Evaluation, Educational Technology, Multimodal Systems, Child-Computer Interaction

### Future Development

**Immediate Roadmap**:

-   Complete backend API integration
-   Enhanced audio playback features
-   Production deployment and testing
-   User experience optimization

**Long-term Vision**:

-   Multi-language support for diverse communities
-   Advanced personalization based on child preferences
-   Integration with educational curricula
-   Community features for story sharing (with privacy controls)

---

**Project Status**: Active development with substantial progress in both research and implementation phases. The comprehensive model evaluation provides a strong foundation for the production-ready application currently under development.

This project demonstrates the successful intersection of academic research and practical application development, contributing both scholarly insights to AI model evaluation and a functional educational tool for children and families.

## License

This project is proprietary academic work developed as part of a University of London final project. All rights reserved.

**Copyright**: © 2024-2025 Jekaterina Berkovich & University of London

**Restrictions**:

-   This code is not open source and may not be redistributed
-   Commercial use is prohibited without explicit permission
-   Academic use requires prior authorization from the author and University of London
-   All AI model evaluation data and methodologies are proprietary research assets

For licensing inquiries or permissions, please contact the author.
