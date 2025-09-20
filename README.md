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
│   ├── analysis/             # Research notebooks and comprehensive reports
│   └── requirements.txt      # Python dependencies for model analysis
├── app/                      # Flutter mobile application
│   ├── lib/                  # Dart/Flutter source code
│   ├── assets/               # Images, icons, and static resources
│   ├── pubspec.yaml          # Flutter dependencies and configuration
│   └── android/ios/          # Platform-specific configurations
├── backend/                  # Python FastAPI backend service
│   ├── src/                  # Backend source code
│   ├── tests/                # Unit and integration tests
│   ├── requirements.txt      # Python backend dependencies
│   └── main.py               # FastAPI application entry point
├── analytics-dashboard/      # Analytics and monitoring dashboard
├── supabase/                 # Database configuration and migrations
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

#### Phase 2: Application Development (COMPLETED)

**Location**: `app/` and `backend/`

**Completed Features**:

-   **Full-Stack Implementation**: Complete Flutter mobile app with Python FastAPI backend
-   **AI Pipeline Integration**: Image analysis, story generation, and text-to-speech services
-   **User Experience**: Child-friendly UI with complete user workflow from image upload to story playback
-   **Parent Dashboard**: Story review and approval system with comprehensive analytics
-   **Authentication System**: Multi-provider authentication (Google, Apple, Facebook) via Supabase
-   **Database Integration**: Supabase PostgreSQL with real-time capabilities
-   **Comprehensive Testing**: Unit tests and integration tests for backend services
-   **Production Architecture**: Clean architecture with dependency injection and error handling
-   **Internationalization**: Multi-language support with proper localization
-   **Analytics Integration**: User behavior tracking and performance monitoring

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
-   **FastAPI**: High-performance API framework with async support
-   **Supabase**: PostgreSQL database with real-time capabilities
-   **AI Services**: OpenAI, Anthropic, Google, ElevenLabs, Azure integrations

#### AI/ML Integration

-   **Image Analysis**: Optimized vision models for child artwork recognition
-   **Story Generation**: Creative language models fine-tuned for children's content
-   **Text-to-Speech**: Child-friendly voice synthesis with natural intonation

### Setup Instructions

#### Prerequisites

-   Python 3.11+
-   Flutter SDK (version 3.6.0+)
-   Dart SDK (included with Flutter)
-   API credentials for AI services (OpenAI, Anthropic, Google, ElevenLabs)
-   Supabase account for database services

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
cp .env.example .env
# Edit .env with your API keys
```

#### Application Setup

**Flutter Frontend**:

```bash
# Navigate to Flutter app
cd app

# Get dependencies
flutter pub get

# Run the app
flutter run
```

**Python Backend**:

```bash
# Navigate to backend
cd backend

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

-   **Model Analysis**: Comprehensive evaluation in `models_analysis/`
-   **Research Results**: Academic findings in `models_analysis/analysis/`
-   **Backend API**: FastAPI documentation available when server is running
-   **Flutter Documentation**: Generated docs in `app/` directory

### Academic Context

**Institution**: University of London  
**Project Type**: Final Research Project  
**Academic Year**: 2024/2025
**Submission Date**: September 2025
**Focus Areas**: AI Model Evaluation, Educational Technology, Multimodal Systems, Child-Computer Interaction

### Project Deliverables

**Research Phase (Completed)**:
-   Comprehensive AI model evaluation across 15+ models
-   Performance benchmarking and cost analysis
-   Evidence-based model selection methodology
-   Academic research documentation

**Implementation Phase (Completed)**:
-   Production-ready Flutter mobile application
-   Scalable FastAPI backend with AI integration
-   Complete user workflows and parental controls
-   Comprehensive testing suite
-   Database integration and real-time capabilities

---

**Project Status**: **COMPLETED AND READY FOR SUBMISSION**. Both research and implementation phases have been successfully completed, delivering a comprehensive academic study with a fully functional production application.

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
