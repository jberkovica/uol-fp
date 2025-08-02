# Mira Storyteller - AI Pipeline Architecture

## 1. AI Agent Architecture Overview

```mermaid
graph TB
    subgraph "Input Layer"
        IMG[Image Input<br/>Base64 PNG/JPEG]
        TXT[Text Input<br/>10-500 characters]
        AUD[Audio Input<br/>Base64 M4A/WAV]
    end

    subgraph "Agent Orchestration Layer"
        ROUTER[Agent Router<br/>Route based on input type]
        CONFIG[Agent Config<br/>providers.yaml]
        FACTORY[Agent Factory<br/>Create agents dynamically]
    end

    subgraph "Processing Agents"
        VISION[Vision Agent<br/>Image → Description]
        STORY[Storyteller Agent<br/>Text → Story]
        VOICE[Voice Agent<br/>Text → Audio]
        SPEECH[Speech Agent<br/>Audio → Text]
    end

    subgraph "AI Service Providers"
        subgraph "Vision APIs"
            GPT4V[OpenAI<br/>GPT-4 Vision]
            GEMINI_V[Google<br/>Gemini Vision]
        end
        
        subgraph "Text Generation APIs"
            GPT4[OpenAI<br/>GPT-4]
            GEMINI[Google<br/>Gemini Pro]
        end
        
        subgraph "Voice APIs"
            ELEVEN[ElevenLabs<br/>TTS]
            OPENAI_TTS[OpenAI<br/>TTS]
            WHISPER[OpenAI<br/>Whisper STT]
        end
    end

    subgraph "Output Layer"
        STORY_OUT[Story Content<br/>Title + Text]
        AUDIO_OUT[Audio File<br/>MP3 format]
        META[Metadata<br/>Processing info]
    end

    %% Input routing
    IMG --> ROUTER
    TXT --> ROUTER
    AUD --> ROUTER

    %% Agent creation
    ROUTER --> FACTORY
    CONFIG --> FACTORY
    FACTORY --> VISION
    FACTORY --> STORY
    FACTORY --> VOICE
    FACTORY --> SPEECH

    %% Agent to API connections
    VISION --> GPT4V
    VISION --> GEMINI_V

    STORY --> GPT4
    STORY --> GEMINI

    VOICE --> ELEVEN
    VOICE --> OPENAI_TTS

    SPEECH --> WHISPER

    %% Output generation
    VISION --> STORY
    STORY --> STORY_OUT
    STORY --> VOICE
    VOICE --> AUDIO_OUT
    SPEECH --> STORY

    %% Metadata collection
    VISION --> META
    STORY --> META
    VOICE --> META
    SPEECH --> META

    %% Styling
    classDef input fill:#E3F2FD,stroke:#1976D2,stroke-width:2px
    classDef orchestration fill:#FFF3E0,stroke:#F57C00,stroke-width:2px
    classDef agents fill:#F3E5F5,stroke:#7B1FA2,stroke-width:2px
    classDef apis fill:#E8F5E8,stroke:#388E3C,stroke-width:2px
    classDef output fill:#FCE4EC,stroke:#C2185B,stroke-width:2px

    class IMG,TXT,AUD input
    class ROUTER,CONFIG,FACTORY orchestration
    class VISION,STORY,VOICE,SPEECH agents
    class GPT4V,GEMINI_V,GPT4,GEMINI,ELEVEN,OPENAI_TTS,WHISPER apis
    class STORY_OUT,AUDIO_OUT,META output
```

## 2. Detailed Processing Pipeline

### 2.1 Image Processing Pipeline

```mermaid
sequenceDiagram
    participant U as User Input
    participant V as Vision Agent
    participant API as AI Vision API
    participant S as Story Agent
    participant TTS as Voice Agent

    Note over U,TTS: Image → Story → Audio Pipeline

    U->>V: Base64 image data
    V->>V: Validate image format
    V->>V: Load provider config
    
    alt OpenAI GPT-4V
        V->>API: Send image + prompt
        Note over API: "Describe this image for a children's story"
        API-->>V: Scene description
    else Google Gemini Vision
        V->>API: Image + instruction
        API-->>V: Creative description
    end

    V->>S: Pass description to storyteller
    S->>S: Generate story from description
    S-->>TTS: Send story text
    TTS-->>U: Return audio file
```

### 2.2 Text Processing Pipeline

```mermaid
sequenceDiagram
    participant U as User Input
    participant S as Story Agent
    participant API as LLM API
    participant TTS as Voice Agent

    Note over U,TTS: Text → Story → Audio Pipeline

    U->>S: Text input (10-500 chars)
    S->>S: Validate text input
    S->>S: Load storyteller config
    S->>S: Prepare prompt template

    alt OpenAI GPT-4
        S->>API: Prompt + user text
        Note over API: Generate age-appropriate story
        API-->>S: Story content
    else Google Gemini Pro
        S->>API: Instructions + input
        API-->>S: Story response
    end

    S->>S: Parse title and content
    S-->>TTS: Send story text
    TTS-->>U: Return audio file
```

### 2.3 Audio Processing Pipeline

```mermaid
sequenceDiagram
    participant U as User Input
    participant STT as Speech Agent
    participant WHISPER as OpenAI Whisper
    participant S as Story Agent
    participant TTS as Voice Agent

    Note over U,TTS: Audio → Text → Story → Audio Pipeline

    U->>STT: Base64 audio data
    STT->>STT: Decode to temp file
    STT->>STT: Validate audio format
    
    STT->>WHISPER: Upload audio file
    Note over WHISPER: Transcribe with language hint
    WHISPER-->>STT: Transcribed text
    
    STT->>STT: Cleanup temp file
    STT->>S: Pass transcription
    
    S->>S: Generate story from text
    S-->>TTS: Send story content
    TTS-->>U: Return audio file
```

## 3. Agent Configuration System

```mermaid
graph LR
    subgraph "Configuration Management"
        YAML[agents.yaml<br/>Provider configs]
        ENV[Environment<br/>API Keys]
        RUNTIME[Runtime Config<br/>Dynamic selection]
    end

    subgraph "Agent Factories"
        VISION_F[Vision Factory<br/>create_vision_agent()]
        STORY_F[Story Factory<br/>create_storyteller_agent()]
        VOICE_F[Voice Factory<br/>create_voice_agent()]
        SPEECH_F[Speech Factory<br/>create_speech_agent()]
    end

    subgraph "Provider Selection"
        VISION_PROVIDER[Vision Provider<br/>openai/google]
        STORY_PROVIDER[Story Provider<br/>openai/google]
        VOICE_PROVIDER[Voice Provider<br/>elevenlabs/openai]
        SPEECH_PROVIDER[Speech Provider<br/>openai]
    end

    YAML --> VISION_F
    YAML --> STORY_F
    YAML --> VOICE_F
    YAML --> SPEECH_F

    ENV --> VISION_F
    ENV --> STORY_F
    ENV --> VOICE_F
    ENV --> SPEECH_F

    VISION_F --> VISION_PROVIDER
    STORY_F --> STORY_PROVIDER
    VOICE_F --> VOICE_PROVIDER
    SPEECH_F --> SPEECH_PROVIDER

    %% Styling
    classDef config fill:#E8F4FD,stroke:#1976D2,stroke-width:2px
    classDef factory fill:#FFF3E0,stroke:#F57C00,stroke-width:2px
    classDef provider fill:#F3E5F5,stroke:#7B1FA2,stroke-width:2px

    class YAML,ENV,RUNTIME config
    class VISION_F,STORY_F,VOICE_F,SPEECH_F factory
    class VISION_PROVIDER,STORY_PROVIDER,VOICE_PROVIDER,SPEECH_PROVIDER provider
```

## 4. Error Handling & Fallback Strategy

```mermaid
flowchart TD
    START[Agent Process Request] --> VALIDATE[Validate Input]
    VALIDATE --> VALID{Input Valid?}
    VALID -->|No| INPUT_ERROR[Return Input Error]
    VALID -->|Yes| PRIMARY[Try Primary Provider]
    
    PRIMARY --> SUCCESS{Request<br/>Successful?}
    SUCCESS -->|Yes| PROCESS[Process Response]
    SUCCESS -->|No| RETRY_COUNT{Retry<br/>< Max?}
    
    RETRY_COUNT -->|Yes| RETRY[Retry Primary<br/>With Backoff]
    RETRY --> PRIMARY
    RETRY_COUNT -->|No| FALLBACK{Fallback<br/>Available?}
    
    FALLBACK -->|Yes| SECONDARY[Try Secondary Provider]
    SECONDARY --> SEC_SUCCESS{Secondary<br/>Successful?}
    SEC_SUCCESS -->|Yes| PROCESS
    SEC_SUCCESS -->|No| TERTIARY{Tertiary<br/>Available?}
    
    TERTIARY -->|Yes| THIRD[Try Tertiary Provider]
    THIRD --> THIRD_SUCCESS{Tertiary<br/>Successful?}
    THIRD_SUCCESS -->|Yes| PROCESS
    THIRD_SUCCESS -->|No| FINAL_ERROR[All Providers Failed]
    
    FALLBACK -->|No| PROVIDER_ERROR[Provider Error]
    TERTIARY -->|No| PROVIDER_ERROR
    
    PROCESS --> VALIDATE_OUTPUT[Validate Output]
    VALIDATE_OUTPUT --> OUTPUT_VALID{Output Valid?}
    OUTPUT_VALID -->|Yes| RETURN[Return Success]
    OUTPUT_VALID -->|No| OUTPUT_ERROR[Return Output Error]

    %% Styling
    classDef process fill:#E8F4FD,stroke:#1976D2,stroke-width:2px
    classDef decision fill:#FFEBEE,stroke:#D32F2F,stroke-width:2px
    classDef error fill:#FFCDD2,stroke:#F44336,stroke-width:2px
    classDef success fill:#E8F5E8,stroke:#388E3C,stroke-width:2px

    class START,VALIDATE,PRIMARY,RETRY,SECONDARY,THIRD,PROCESS,VALIDATE_OUTPUT process
    class VALID,SUCCESS,RETRY_COUNT,FALLBACK,SEC_SUCCESS,TERTIARY,THIRD_SUCCESS,OUTPUT_VALID decision
    class INPUT_ERROR,PROVIDER_ERROR,FINAL_ERROR,OUTPUT_ERROR error
    class RETURN success
```

## 5. Cost Tracking & Analytics Integration

```mermaid
graph TB
    subgraph "Request Tracking"
        REQ[AI Request] --> LOG[Log Request<br/>User, Type, Model]
        LOG --> COST[Calculate Cost<br/>Token/API pricing]
        COST --> STORE[Store in Database<br/>ai_requests table]
    end

    subgraph "Analytics Dashboard"
        STORE --> METRICS[Generate Metrics<br/>Usage by provider]
        METRICS --> ALERTS[Cost Alerts<br/>Budget monitoring]
        ALERTS --> OPTIMIZE[Optimization<br/>Recommendations]
    end

    subgraph "Provider Performance"
        PERF[Performance Metrics<br/>Latency, Success Rate]
        QUALITY[Quality Metrics<br/>Story ratings]
        COST_EFF[Cost Effectiveness<br/>Price per quality]
    end

    STORE --> PERF
    STORE --> QUALITY
    PERF --> COST_EFF
    QUALITY --> COST_EFF
    COST_EFF --> OPTIMIZE

    %% Styling
    classDef tracking fill:#E3F2FD,stroke:#1976D2,stroke-width:2px
    classDef analytics fill:#F3E5F5,stroke:#7B1FA2,stroke-width:2px
    classDef performance fill:#E8F5E8,stroke:#388E3C,stroke-width:2px

    class REQ,LOG,COST,STORE tracking
    class METRICS,ALERTS,OPTIMIZE analytics
    class PERF,QUALITY,COST_EFF performance
```

## 6. Language Support Matrix

```mermaid
graph LR
    subgraph "Supported Languages"
        EN[English<br/>Primary]
        RU[Russian<br/>Full Support]
        LV[Latvian<br/>Full Support]
        ES[Spanish<br/>Planned]
    end

    subgraph "AI Provider Support"
        subgraph "Vision"
            V_ALL[All Providers<br/>Universal]
        end
        subgraph "Story Generation"
            S_MULTI[Multi-language<br/>GPT/Gemini]
        end
        subgraph "Voice Synthesis"
            ELEVEN_LANG[ElevenLabs<br/>Multiple voices]
            OPENAI_LANG[OpenAI TTS<br/>Language support]
        end
        subgraph "Speech Recognition"
            WHISPER_LANG[Whisper<br/>100+ languages]
        end
    end

    EN --> V_ALL
    RU --> V_ALL
    LV --> V_ALL
    ES --> V_ALL

    EN --> S_MULTI
    RU --> S_MULTI
    LV --> S_MULTI
    ES --> S_MULTI

    EN --> ELEVEN_LANG
    RU --> ELEVEN_LANG
    LV --> ELEVEN_LANG

    EN --> OPENAI_LANG
    RU --> OPENAI_LANG
    LV --> OPENAI_LANG

    EN --> WHISPER_LANG
    RU --> WHISPER_LANG
    LV --> WHISPER_LANG
    ES --> WHISPER_LANG

    %% Styling
    classDef language fill:#E8F4FD,stroke:#1976D2,stroke-width:2px
    classDef provider fill:#F3E5F5,stroke:#7B1FA2,stroke-width:2px

    class EN,RU,LV,ES language
    class V_ALL,S_MULTI,ELEVEN_LANG,OPENAI_LANG,WHISPER_LANG provider
```

## 7. Future AI Enhancements

### Planned AI Features
1. **Story Image Generation**: DALL-E 3 integration for story cover art
2. **Content Moderation**: AI-powered content filtering for safety
3. **Personalization**: ML-based story customization per child
4. **Interactive Elements**: Voice-controlled story navigation
5. **Multi-modal Stories**: Combined text, audio, and visual storytelling

### Performance Optimizations
1. **Response Caching**: Cache similar requests to reduce API calls
2. **Request Batching**: Combine multiple API calls where possible
3. **Smart Fallbacks**: Dynamic provider selection based on performance
4. **Edge Computing**: Move processing closer to users
5. **Model Fine-tuning**: Custom models for specific story types

This AI pipeline is designed to be modular, scalable, and cost-effective while maintaining high quality story generation across multiple languages and input modalities.