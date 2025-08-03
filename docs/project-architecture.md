# Mira Storyteller - Project Architecture

## 1. System Architecture Overview

```mermaid
graph TB
    %% Frontend Layer
    subgraph "Frontend Layer"
        FLT[Flutter App<br/>iOS/Android/Web]
        FLT_AUTH[Auth Screens]
        FLT_CHILD[Child Screens]
        FLT_PARENT[Parent Screens]
        FLT_SERVICES[Services Layer]
    end

    %% Backend Layer
    subgraph "Backend API Layer"
        API[FastAPI Backend<br/>Python]
        AGENTS[AI Agents Layer]
        VISION[Vision Agent<br/>Image Analysis]
        STORY[Storyteller Agent<br/>Story Generation]
        VOICE[Voice Agent<br/>TTS/STT]
        BG_TASKS[Background Tasks<br/>Async Processing]
    end

    %% Database Layer
    subgraph "Database & Storage"
        SUPABASE[Supabase<br/>PostgreSQL + Auth]
        STORAGE[Supabase Storage<br/>Audio Files]
        EDGE[Edge Functions<br/>Email Notifications]
    end

    %% External Services
    subgraph "AI Services"
        OPENAI[OpenAI<br/>GPT + Whisper + DALL-E]
        GOOGLE[Google<br/>Gemini]
        ELEVENLABS[ElevenLabs<br/>Voice Synthesis]
    end

    %% Connections
    FLT --> API
    API --> SUPABASE
    API --> STORAGE
    API --> EDGE
    
    AGENTS --> VISION
    AGENTS --> STORY
    AGENTS --> VOICE
    
    VISION --> OPENAI
    VISION --> GOOGLE
    
    STORY --> OPENAI
    STORY --> GOOGLE
    
    VOICE --> ELEVENLABS
    VOICE --> OPENAI
    
    FLT_SERVICES --> FLT_AUTH
    FLT_SERVICES --> FLT_CHILD
    FLT_SERVICES --> FLT_PARENT

    %% Styling
    classDef frontend fill:#E8F4FD,stroke:#1976D2,stroke-width:2px
    classDef backend fill:#FFF8E1,stroke:#F57C00,stroke-width:2px
    classDef database fill:#F3E5F5,stroke:#7B1FA2,stroke-width:2px
    classDef external fill:#E8F5E8,stroke:#388E3C,stroke-width:2px

    class FLT,FLT_AUTH,FLT_CHILD,FLT_PARENT,FLT_SERVICES frontend
    class API,AGENTS,VISION,STORY,VOICE,BG_TASKS backend
    class SUPABASE,STORAGE,EDGE database
    class OPENAI,GOOGLE,ELEVENLABS external
```

## 2. Technology Stack

### Frontend (Flutter)
- **Framework**: Flutter 3.x (iOS/Android/Web)
- **State Management**: Provider/Riverpod patterns
- **Authentication**: Supabase Auth integration
- **Localization**: i18n support (English, Russian, Latvian)
- **Platform Features**: Camera, microphone, biometrics

### Backend (FastAPI)
- **Framework**: FastAPI with Python 3.9+
- **Architecture**: Agent-based AI pipeline
- **Async Processing**: Background tasks for story generation
- **API Design**: RESTful with OpenAPI documentation
- **Middleware**: CORS, security, logging

### Database & Storage
- **Primary DB**: Supabase (PostgreSQL)
- **Authentication**: Supabase Auth with RLS
- **File Storage**: Supabase Storage for audio files
- **Edge Functions**: TypeScript for email notifications

### AI Services Integration
- **Vision**: OpenAI GPT-4V, Google Gemini Vision
- **Story Generation**: OpenAI GPT-4, Google Gemini Pro
- **Text-to-Speech**: ElevenLabs, OpenAI TTS
- **Speech-to-Text**: OpenAI Whisper

## 3. Data Flow Architecture

```mermaid
sequenceDiagram
    participant U as User (Child)
    participant F as Flutter App
    participant A as FastAPI Backend
    participant AI as AI Agents
    participant S as Supabase
    participant E as External AI APIs

    U->>F: Upload Image/Text/Audio
    F->>A: POST /generate-story-*
    A->>S: Create story record (pending)
    A-->>F: Return story_id (processing)
    
    Note over A,E: Background Processing (Async)
    A->>AI: Process input through agents
    AI->>E: Call AI services (Vision/Story/Voice)
    E-->>AI: Return results
    AI-->>A: Complete processing
    A->>S: Update story with content + audio
    A->>S: Store input metadata
    
    Note over F,A: Frontend Polling
    F->>A: Poll GET /story/{id}
    A->>S: Fetch story data
    S-->>A: Return story + audio URL
    A-->>F: Story data with content
    F->>U: Display completed story
```

## 4. Security & Privacy Architecture

```mermaid
graph LR
    subgraph "Security Layers"
        AUTH[Supabase Auth<br/>JWT Tokens]
        RLS[Row Level Security<br/>Family Isolation]
        VALIDATION[Input Validation<br/>API Layer]
        ENCRYPTION[Data Encryption<br/>Transit & Rest]
    end
    
    subgraph "Privacy Controls"
        FAMILY[Family-based Access]
        APPROVAL[Parent Approval<br/>Workflow]
        GDPR[GDPR Compliance<br/>Data Subject Rights]
        ANALYTICS[Privacy-Safe<br/>Analytics]
    end
    
    AUTH --> RLS
    RLS --> FAMILY
    VALIDATION --> ENCRYPTION
    FAMILY --> APPROVAL
    APPROVAL --> GDPR
    GDPR --> ANALYTICS
```

## 5. Deployment Architecture

```mermaid
graph TB
    subgraph "Production Environment"
        CDN[CDN<br/>Flutter Web]
        APP_STORES[App Stores<br/>iOS/Android]
        API_SERVER[API Server<br/>FastAPI]
        SUPABASE_PROD[Supabase<br/>Production]
    end
    
    subgraph "Development"
        DEV_API[Local API<br/>Development]
        DEV_DB[Local DB<br/>SQLite]
    end
    
    subgraph "External Dependencies"
        AI_APIS[AI Service APIs<br/>OpenAI, Anthropic, etc.]
        EMAIL[Email Service<br/>Supabase Functions]
    end
    
    CDN --> API_SERVER
    APP_STORES --> API_SERVER
    API_SERVER --> SUPABASE_PROD
    API_SERVER --> AI_APIS
    SUPABASE_PROD --> EMAIL
    
    DEV_API --> DEV_DB
```

## 6. File Structure Overview

```
uol-fp-mira/
├── app/                          # Flutter Frontend
│   ├── lib/
│   │   ├── screens/             # UI Screens
│   │   │   ├── auth/           # Authentication screens
│   │   │   ├── child/          # Child user interface
│   │   │   └── parent/         # Parent dashboard
│   │   ├── services/           # Business logic
│   │   ├── models/             # Data models
│   │   ├── widgets/            # Reusable components
│   │   └── constants/          # App configuration
│   └── assets/                 # Static resources
├── backend/                     # FastAPI Backend
│   ├── src/
│   │   ├── api/               # API routes & app factory
│   │   ├── agents/            # AI processing agents
│   │   ├── services/          # External service integrations
│   │   ├── core/              # Business logic
│   │   └── utils/             # Utilities & config
│   └── tests/                 # Test suite
├── supabase/                   # Database & functions
│   ├── migrations/            # DB schema changes
│   └── functions/             # Edge functions
└── docs/                       # Project documentation
```

## 7. Key Design Principles

1. **Family-Centric**: All data is organized around family units with proper isolation
2. **Multi-Language**: Built-in internationalization from the ground up
3. **Privacy-by-Design**: COPPA compliant with parental controls
4. **Agent-Based AI**: Modular AI processing with swappable providers
5. **Async Processing**: Non-blocking story generation with real-time updates
6. **Scalable Architecture**: Designed to handle growth with proper caching and optimization

## 8. Current Status & Next Steps

### Completed ✅
- Core story generation pipeline (image/text/audio inputs)
- Multi-language support framework
- Database schema with family-based RLS
- Basic Flutter UI with multiple input methods
- AI agent abstraction layer

### In Progress 🚧
- UI/UX improvements to match design mockups
- Authentication system integration
- Parent approval workflows
- Cost tracking and analytics

### Planned 📋
- Single AI provider migration for cost optimization
- Story image generation (DALL-E integration)
- Enhanced user behavior analytics
- Performance optimization and caching