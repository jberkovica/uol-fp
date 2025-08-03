# Mira Storyteller - Advanced AI Architecture Plan

## Overview
Complete architectural overhaul to create a robust, scalable, and cost-controlled AI-powered storytelling system with comprehensive analytics, monitoring, and vendor management.

## Core Principles
- **Vendor Agnostic**: Easy switching between AI providers
- **Cost Controlled**: Real-time tracking and abuse prevention
- **Maintainable**: Prompt management and version control
- **Observable**: Comprehensive analytics and monitoring
- **Scalable**: Built for growth and optimization

---

## 1. Architecture Components

### Data Flow Pipeline
```
User Input → AI Processing → Cost Tracking → Storage → Feature Delivery
     ↓
Analytics & Monitoring ← Vendor Dashboards ← User Metadata
```

### Core Services
- **AI Service Abstraction Layer** (vendor-agnostic)
- **Prompt Management System** (file-based, versioned)
- **Cost & Time Tracking System** (real-time monitoring)
- **Usage Monitoring & Abuse Detection**
- **Configuration Management** (dynamic switching)
- **Analytics Integration** (vendor dashboards)

---

## 2. AI Processing Pipeline

### Input Processing
- **Image Upload** → Image Recognition Model → Scene Analysis
- **Audio Input** → OpenAI Whisper → Text Transcription
- **Text Input** → Content Safety → Story Context

### Story Generation Pipeline
1. **Content Analysis** (image/audio/text)
2. **Context Building** (kid profile + parent preferences)
3. **Story Generation** (LLM with dynamic prompts)
4. **Content Safety Check** (inappropriate content filtering)
5. **TTS Audio Generation** (OpenAI TTS)
6. **Timestamp Generation** (Whisper analysis)
7. **Image Generation** (story cover/illustrations)
8. **Storage & Delivery** (database + CDN)

### Supported AI Operations
| Operation | Primary Provider | Fallback | Cost Tracking | User Analytics |
|-----------|------------------|----------|---------------|----------------|
| Image Recognition | OpenAI GPT-4V | Google Vision | ✅ | ✅ |
| Story Generation | OpenAI GPT-4 | Anthropic Claude | ✅ | ✅ |
| Text-to-Speech | OpenAI TTS | Google Cloud TTS | ✅ | ✅ |
| Timestamp Generation | OpenAI Whisper | Azure Speech | ✅ | ✅ |
| Image Generation | OpenAI DALL-E 3 | Midjourney API | ✅ | ✅ |
| Content Safety | OpenAI Moderation | Custom Filter | ✅ | ✅ |

---

## 3. Database Schema Design

### New Tables

#### AI Operations Tracking
```sql
CREATE TABLE ai_operations (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL,
    operation_type VARCHAR(50) NOT NULL, -- 'image_recognition', 'story_generation', 'tts', 'whisper', 'image_generation'
    vendor VARCHAR(50) NOT NULL, -- 'openai', 'google', 'anthropic', 'azure'
    model_used VARCHAR(100), -- 'gpt-4', 'dall-e-3', 'tts-1'
    input_size INT, -- tokens, characters, seconds, pixels
    output_size INT, -- tokens, characters, seconds
    cost_usd DECIMAL(10,6) NOT NULL,
    processing_time_ms INT NOT NULL,
    success BOOLEAN DEFAULT TRUE,
    error_message TEXT,
    prompt_version VARCHAR(20),
    session_id UUID,
    metadata JSONB, -- request params, user context, vendor response metadata
    created_at TIMESTAMP DEFAULT NOW(),
    
    INDEX idx_user_operations (user_id, created_at),
    INDEX idx_cost_tracking (created_at, cost_usd),
    INDEX idx_vendor_performance (vendor, operation_type, success)
);
```

#### User Usage & Limits
```sql
CREATE TABLE user_usage_tracking (
    user_id UUID PRIMARY KEY,
    current_tier VARCHAR(20) DEFAULT 'free', -- 'free', 'premium', 'enterprise'
    
    -- Daily tracking (resets daily)
    daily_cost_usd DECIMAL(10,2) DEFAULT 0.00,
    daily_operations INT DEFAULT 0,
    daily_reset_date DATE DEFAULT CURRENT_DATE,
    
    -- Monthly tracking (resets monthly)
    monthly_cost_usd DECIMAL(10,2) DEFAULT 0.00,
    monthly_operations INT DEFAULT 0,
    monthly_reset_date DATE DEFAULT DATE_TRUNC('month', CURRENT_DATE),
    
    -- Limits and controls
    daily_cost_limit DECIMAL(10,2) DEFAULT 5.00,
    monthly_cost_limit DECIMAL(10,2) DEFAULT 20.00,
    daily_operations_limit INT DEFAULT 50,
    monthly_operations_limit INT DEFAULT 500,
    
    -- Abuse prevention
    is_blocked BOOLEAN DEFAULT FALSE,
    block_reason TEXT,
    warning_count INT DEFAULT 0,
    last_warning_date TIMESTAMP,
    
    -- Analytics
    total_lifetime_cost DECIMAL(12,2) DEFAULT 0.00,
    total_lifetime_operations INT DEFAULT 0,
    first_operation_date TIMESTAMP,
    last_operation_date TIMESTAMP,
    
    updated_at TIMESTAMP DEFAULT NOW(),
    created_at TIMESTAMP DEFAULT NOW()
);
```

#### Enhanced Stories Table
```sql
ALTER TABLE stories ADD COLUMN (
    -- AI Processing metadata
    word_timestamps JSONB, -- [{"word": "Once", "start": 0.0, "end": 0.5}, ...]
    generation_metadata JSONB, -- models used, processing times, costs breakdown
    prompt_version VARCHAR(20),
    
    -- Cost tracking
    total_cost_usd DECIMAL(8,4),
    cost_breakdown JSONB, -- {"story_gen": 0.12, "tts": 0.05, "whisper": 0.02, "image": 0.08}
    
    -- Performance tracking
    total_processing_time_ms INT,
    processing_breakdown JSONB, -- {"story_gen": 5000, "tts": 15000, "whisper": 8000}
    
    -- Quality metrics
    user_rating INT, -- 1-5 stars
    parent_approved BOOLEAN,
    content_warnings JSONB,
    
    -- Analytics
    listening_time_seconds INT DEFAULT 0,
    replay_count INT DEFAULT 0,
    highlighting_used BOOLEAN DEFAULT FALSE
);
```

#### Prompt Analytics & A/B Testing
```sql
CREATE TABLE prompt_analytics (
    id UUID PRIMARY KEY,
    prompt_type VARCHAR(50) NOT NULL, -- 'story_generation', 'image_analysis', 'content_safety'
    prompt_version VARCHAR(20) NOT NULL,
    user_id UUID NOT NULL,
    operation_id UUID REFERENCES ai_operations(id),
    
    -- Performance metrics
    user_rating INT, -- 1-5 stars from user feedback
    completion_rate DECIMAL(5,2), -- % of story actually listened to
    processing_time_ms INT,
    cost_usd DECIMAL(10,6),
    success BOOLEAN,
    
    -- A/B testing
    experiment_id UUID,
    experiment_group VARCHAR(20), -- 'control', 'variant_a', 'variant_b'
    
    -- Context
    user_age_group VARCHAR(10), -- '2-3', '4-6', '7-9'
    story_type VARCHAR(30), -- 'adventure', 'bedtime', 'educational'
    
    created_at TIMESTAMP DEFAULT NOW(),
    
    INDEX idx_prompt_performance (prompt_type, prompt_version, created_at),
    INDEX idx_ab_testing (experiment_id, experiment_group)
);

CREATE TABLE prompt_experiments (
    id UUID PRIMARY KEY,
    experiment_name VARCHAR(100) NOT NULL,
    prompt_type VARCHAR(50) NOT NULL,
    
    -- Experiment configuration
    control_version VARCHAR(20),
    variant_versions JSONB, -- ["v1.2", "v1.3"]
    traffic_split JSONB, -- {"control": 50, "variant_a": 25, "variant_b": 25}
    
    -- Success criteria
    primary_metric VARCHAR(50), -- 'user_rating', 'completion_rate', 'cost_efficiency'
    success_threshold DECIMAL(5,2),
    minimum_sample_size INT DEFAULT 100,
    
    -- Experiment state
    is_active BOOLEAN DEFAULT TRUE,
    start_date TIMESTAMP DEFAULT NOW(),
    end_date TIMESTAMP,
    results JSONB,
    winner_version VARCHAR(20),
    
    created_by VARCHAR(100),
    created_at TIMESTAMP DEFAULT NOW()
);
```

---

## 4. Prompt Management System

### File Structure
```
app/prompts/
├── system/
│   ├── story_generation.yaml        # Core story creation prompts
│   ├── image_recognition.yaml       # Image analysis prompts
│   ├── content_safety.yaml          # Safety and moderation prompts
│   └── audio_transcription.yaml     # Whisper transcription prompts
├── user_context/
│   ├── kid_profiles.yaml           # Age-specific context templates
│   ├── parent_preferences.yaml     # Content filtering preferences
│   └── accessibility.yaml          # Special needs accommodations
├── story_types/
│   ├── adventure.yaml              # Adventure story templates
│   ├── bedtime.yaml               # Calming bedtime stories
│   ├── educational.yaml           # Learning-focused stories
│   ├── fantasy.yaml               # Magical and fantasy themes
│   └── real_world.yaml            # Realistic scenarios
├── versions/
│   ├── v1.0/                      # Archived prompt versions
│   ├── v1.1/
│   ├── v1.2/
│   └── current -> v1.2/           # Symlink to current version
└── experiments/
    ├── ab_test_story_length.yaml  # A/B test configurations
    └── prompt_variants.yaml       # Experimental prompt variations
```

### Prompt Configuration Format
```yaml
# prompts/system/story_generation.yaml
version: "1.2"
created_by: "content_team"
last_modified: "2025-07-20"
description: "Main story generation prompts with kid personalization"

prompts:
  story_generation:
    system: |
      You are Mira, a magical storyteller who creates personalized stories for children.
      
      CHILD CONTEXT:
      - Name: {{kid_name}}
      - Age: {{kid_age}} years old
      - Interests: {{kid_interests}}
      - Reading level: {{reading_level}}
      - Special needs: {{accessibility_needs}}
      
      PARENT GUIDELINES:
      - Content preferences: {{content_preferences}}
      - Educational goals: {{educational_focus}}
      - Language: {{language}}
      - Avoid topics: {{avoid_topics}}
      
      STORY REQUIREMENTS:
      - Create an engaging {{story_type}} story
      - Include educational elements appropriate for age {{kid_age}}
      - Use vocabulary suitable for {{reading_level}} level
      - Length: {{story_length}} (short=150-300 words, medium=300-600 words, long=600-1000 words)
      - Include the child as the main character or companion
      - Incorporate elements from the provided image
      - End with a positive, encouraging message
      
      SAFETY GUIDELINES:
      - No scary or violent content
      - No inappropriate themes
      - Promote positive values and kindness
      - Be inclusive and respectful
      
    user_template: |
      IMAGE ANALYSIS: {{image_description}}
      
      STORY REQUEST:
      - Type: {{story_type}}
      - Length: {{story_length}}
      - Special focus: {{special_requests}}
      
      Create a wonderful story for {{kid_name}} based on their drawing!

  image_analysis:
    system: |
      Analyze this child's drawing with encouraging and positive language.
      
      ANALYSIS REQUIREMENTS:
      1. Main subjects/characters (describe what the child drew)
      2. Setting/environment (where does the story take place?)
      3. Colors and artistic elements (appreciate the child's creativity)
      4. Mood and emotion (what feeling does the drawing convey?)
      5. Story potential (what adventures could happen here?)
      
      TONE:
      - Be encouraging about the child's artwork
      - Use positive, exciting language
      - Focus on creative possibilities
      - Identify story themes that would engage the child
      
    user_template: |
      Child's age: {{kid_age}}
      Child's interests: {{kid_interests}}
      
      Please analyze this drawing and suggest story themes:

parameters:
  openai:
    model: "gpt-4"
    max_tokens: 1500
    temperature: 0.8
    top_p: 1.0
    frequency_penalty: 0.0
    presence_penalty: 0.0
  
  anthropic:
    model: "claude-3-sonnet"
    max_tokens: 1500
    temperature: 0.8
  
  fallback_strategy:
    - provider: "openai"
      model: "gpt-4"
    - provider: "openai" 
      model: "gpt-3.5-turbo"
    - provider: "anthropic"
      model: "claude-3-haiku"

quality_checks:
  min_word_count: 100
  max_word_count: 1200
  required_elements:
    - child_name_mentioned
    - positive_ending
    - age_appropriate_content
  
  content_filters:
    - no_violence
    - no_scary_themes
    - no_inappropriate_content
    - family_friendly
```

### Story Type Templates
```yaml
# prompts/story_types/adventure.yaml
version: "1.0"
description: "Adventure story prompts with excitement and exploration"

story_elements:
  themes:
    - exploration and discovery
    - courage and bravery
    - friendship and teamwork
    - problem-solving
    - nature and animals
  
  settings:
    - magical forests
    - treasure islands
    - space adventures
    - underwater worlds
    - mountain expeditions
  
  characters:
    - brave explorers
    - friendly animals
    - magical creatures
    - helpful guides
    - wise mentors

structure:
  opening: |
    Start with {{kid_name}} discovering something exciting or mysterious
    that leads to an adventure
  
  middle: |
    Include challenges that {{kid_name}} overcomes using creativity,
    kindness, or help from friends
  
  ending: |
    Celebrate {{kid_name}}'s success and what they learned from the adventure

age_adaptations:
  "2-3":
    complexity: simple
    vocabulary: basic
    themes: ["gentle exploration", "friendly animals", "colorful discoveries"]
  
  "4-6": 
    complexity: moderate
    vocabulary: expanded
    themes: ["treasure hunts", "magical friends", "solving puzzles"]
  
  "7-9":
    complexity: advanced
    vocabulary: rich
    themes: ["epic quests", "complex problems", "character development"]
```

---

## 5. AI Service Architecture

### Service Factory Pattern
```python
# services/ai/factory.py
class AIServiceFactory:
    def __init__(self, config_manager, cost_tracker, prompt_manager):
        self.config = config_manager
        self.cost_tracker = cost_tracker
        self.prompts = prompt_manager
        self.providers = self._initialize_providers()
    
    def get_service(self, operation_type: str, user_context: dict = None):
        """Get best AI service for operation based on config and user context"""
        provider_config = self._select_provider(operation_type, user_context)
        
        service_map = {
            'story_generation': StoryGenerationService,
            'image_recognition': ImageRecognitionService,
            'text_to_speech': TextToSpeechService,
            'whisper_timestamps': WhisperTimestampService,
            'image_generation': ImageGenerationService,
            'content_safety': ContentSafetyService
        }
        
        service_class = service_map.get(operation_type)
        if not service_class:
            raise ValueError(f"Unknown operation type: {operation_type}")
        
        return service_class(
            provider=provider_config,
            cost_tracker=self.cost_tracker,
            prompt_manager=self.prompts
        )
    
    def _select_provider(self, operation_type: str, user_context: dict):
        """Smart provider selection based on cost, performance, and user tier"""
        user_tier = user_context.get('user_tier', 'free') if user_context else 'free'
        current_cost = self._get_user_daily_cost(user_context.get('user_id'))
        
        # Get available providers for this operation
        providers = self.config.get_providers(operation_type)
        
        # Apply selection strategy
        if user_tier == 'free' and current_cost > self.config.free_tier_threshold:
            return self._get_cheapest_provider(providers)
        elif user_tier == 'premium':
            return self._get_highest_quality_provider(providers)
        else:
            return self._get_balanced_provider(providers)
```

### Base AI Service
```python
# services/ai/base_service.py
class BaseAIService:
    def __init__(self, provider_config, cost_tracker, prompt_manager):
        self.provider = provider_config
        self.cost_tracker = cost_tracker
        self.prompts = prompt_manager
        self.client = self._initialize_client()
    
    async def execute(self, operation_type: str, user_context: dict, **kwargs):
        """Execute AI operation with full tracking and error handling"""
        
        # Validate user limits
        await self._check_user_limits(user_context)
        
        # Start operation tracking
        operation_id = await self.cost_tracker.start_operation(
            user_id=user_context['user_id'],
            operation_type=operation_type,
            vendor=self.provider.vendor,
            model=self.provider.model,
            session_id=user_context.get('session_id')
        )
        
        try:
            # Get dynamic prompt
            prompt = self.prompts.get_prompt(operation_type, user_context)
            
            # Build vendor metadata for analytics
            metadata = self._build_vendor_metadata(user_context, operation_type)
            
            # Execute AI operation
            result = await self._execute_operation(prompt, metadata, **kwargs)
            
            # Calculate cost and track success
            cost = self._calculate_cost(result)
            await self.cost_tracker.complete_operation(
                operation_id=operation_id,
                cost=cost,
                processing_time=result.processing_time,
                input_size=result.input_size,
                output_size=result.output_size,
                success=True,
                metadata=result.metadata
            )
            
            # Update user usage
            await self._update_user_usage(user_context['user_id'], cost)
            
            return result
            
        except Exception as e:
            # Track failure
            await self.cost_tracker.fail_operation(operation_id, str(e))
            
            # Check if we should try fallback provider
            if self._should_retry_with_fallback(e):
                return await self._retry_with_fallback(operation_type, user_context, **kwargs)
            
            raise AIServiceError(f"Operation failed: {str(e)}")
    
    def _build_vendor_metadata(self, user_context: dict, operation_type: str):
        """Build metadata for vendor analytics"""
        return {
            'user': f"user_{self._hash_user_id(user_context['user_id'])}",
            'metadata': {
                'user_tier': user_context.get('user_tier', 'free'),
                'app_version': user_context.get('app_version', '1.0.0'),
                'feature': operation_type,
                'session_id': user_context.get('session_id'),
                'kid_age_group': user_context.get('kid_age_group'),
                'story_type': user_context.get('story_type'),
                'language': user_context.get('language', 'en'),
                'platform': user_context.get('platform', 'mobile')
            }
        }
```

### Specific Service Examples
```python
# services/ai/story_generation_service.py
class StoryGenerationService(BaseAIService):
    async def generate_story(self, user_context: dict, image_description: str, story_type: str = 'adventure'):
        """Generate personalized story based on image and user context"""
        
        # Build enhanced context
        enhanced_context = {
            **user_context,
            'image_description': image_description,
            'story_type': story_type,
            'timestamp': datetime.utcnow().isoformat()
        }
        
        result = await self.execute(
            operation_type='story_generation',
            user_context=enhanced_context,
            image_description=image_description,
            story_type=story_type
        )
        
        # Validate story quality
        await self._validate_story_content(result.content, user_context)
        
        return result
    
    async def _execute_operation(self, prompt, metadata, **kwargs):
        """Execute OpenAI story generation"""
        response = await self.client.chat.completions.create(
            model=self.provider.model,
            messages=[
                {"role": "system", "content": prompt.system},
                {"role": "user", "content": prompt.user}
            ],
            user=metadata['user'],
            temperature=prompt.parameters.temperature,
            max_tokens=prompt.parameters.max_tokens,
            **metadata['metadata']  # Pass metadata to OpenAI for analytics
        )
        
        return AIResult(
            content=response.choices[0].message.content,
            processing_time=response.response_time,
            input_size=len(prompt.system + prompt.user),
            output_size=len(response.choices[0].message.content),
            metadata={
                'model': response.model,
                'tokens_used': response.usage.total_tokens,
                'finish_reason': response.choices[0].finish_reason
            }
        )

# services/ai/whisper_timestamp_service.py
class WhisperTimestampService(BaseAIService):
    async def generate_timestamps(self, user_context: dict, audio_file_path: str):
        """Generate word-level timestamps using Whisper"""
        
        result = await self.execute(
            operation_type='whisper_timestamps',
            user_context=user_context,
            audio_file=audio_file_path
        )
        
        # Process and format timestamps
        formatted_timestamps = self._format_timestamps(result.segments)
        
        return formatted_timestamps
    
    async def _execute_operation(self, prompt, metadata, audio_file, **kwargs):
        """Execute OpenAI Whisper with timestamp generation"""
        
        with open(audio_file, 'rb') as audio:
            response = await self.client.audio.transcriptions.create(
                model="whisper-1",
                file=audio,
                response_format="verbose_json",
                timestamp_granularities=["word"],
                user=metadata['user']
            )
        
        return AIResult(
            content=response.text,
            segments=response.words,  # Word-level timestamps
            processing_time=response.processing_time,
            input_size=os.path.getsize(audio_file),
            output_size=len(response.text),
            metadata={
                'model': 'whisper-1',
                'language': response.language,
                'duration': response.duration
            }
        )
    
    def _format_timestamps(self, whisper_words):
        """Convert Whisper format to our timestamp format"""
        return [
            {
                'word': word['word'].strip(),
                'start': word['start'],
                'end': word['end'],
                'confidence': word.get('probability', 1.0)
            }
            for word in whisper_words
        ]
```

---

## 6. Configuration Management

### Remote Configuration System
**Goal**: Change app behavior, rate limits, feature flags, and AI settings without rebuilding or redeploying the application.

#### Remote Config Benefits:
- **Instant Updates**: Change settings without app store approval
- **A/B Testing**: Enable/disable features for user segments
- **Emergency Controls**: Quickly disable expensive features or block abuse
- **Cost Management**: Adjust rate limits and pricing tiers in real-time
- **Feature Rollouts**: Gradual feature releases to user groups
- **Maintenance Mode**: Disable AI services during maintenance

#### Implementation Options:

**Option 1: Firebase Remote Config (Recommended)**
```typescript
// Remote config structure
{
  "ai_providers": {
    "openai": {
      "enabled": true,
      "rate_limit_rpm": 500,
      "cost_per_token": 0.00003,
      "models": {
        "gpt4": { "enabled": true, "priority": 1 },
        "gpt3.5": { "enabled": true, "priority": 2 }
      }
    }
  },
  "usage_limits": {
    "free_tier": {
      "daily_cost_limit": 5.00,
      "monthly_operations": 50
    },
    "premium_tier": {
      "daily_cost_limit": 50.00,
      "monthly_operations": 500
    }
  },
  "feature_flags": {
    "word_highlighting": true,
    "background_music": true,
    "image_generation": false,
    "story_genres": true
  },
  "emergency_controls": {
    "maintenance_mode": false,
    "ai_services_enabled": true,
    "max_concurrent_requests": 100
  }
}
```

**Option 2: Custom API Endpoint**
```typescript
// GET /api/v1/config
{
  "version": "1.2.0",
  "last_updated": "2025-07-20T10:30:00Z",
  "config": {
    // Same structure as above
  }
}
```

**Option 3: Supabase Edge Functions + Storage**
```sql
-- Remote config table
CREATE TABLE app_configurations (
    id UUID PRIMARY KEY,
    config_key VARCHAR(100) UNIQUE,
    config_value JSONB,
    environment VARCHAR(20), -- 'development', 'staging', 'production'
    version VARCHAR(20),
    is_active BOOLEAN DEFAULT TRUE,
    created_by VARCHAR(100),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);
```

### Main Configuration
```yaml
# config/ai_providers.yaml
version: "1.0"
environment: "production"  # development, staging, production

providers:
  openai:
    api_key: "${OPENAI_API_KEY}"
    organization: "${OPENAI_ORG_ID}"
    base_url: "https://api.openai.com/v1"
    
    models:
      text_generation:
        primary: "gpt-4"
        fallback: "gpt-3.5-turbo"
        cost_per_token_input: 0.00003
        cost_per_token_output: 0.00006
      
      text_to_speech:
        primary: "tts-1-hd"
        fallback: "tts-1"
        cost_per_character: 0.000015
      
      whisper:
        model: "whisper-1"
        cost_per_minute: 0.006
      
      image_generation:
        model: "dall-e-3"
        cost_per_image: 0.040
        sizes: ["1024x1024", "1792x1024", "1024x1792"]
      
      moderation:
        model: "text-moderation-latest"
        cost_per_request: 0.0001
    
    rate_limits:
      requests_per_minute: 500
      tokens_per_minute: 150000
    
    analytics_tracking: true
    user_metadata_enabled: true
  
  anthropic:
    api_key: "${ANTHROPIC_API_KEY}"
    base_url: "https://api.anthropic.com"
    
    models:
      text_generation:
        primary: "claude-3-sonnet-20240229"
        fallback: "claude-3-haiku-20240307"
        cost_per_token_input: 0.000003
        cost_per_token_output: 0.000015
    
    rate_limits:
      requests_per_minute: 300
      tokens_per_minute: 100000
  
  google:
    project_id: "${GOOGLE_PROJECT_ID}"
    credentials_path: "${GOOGLE_CREDENTIALS_PATH}"
    
    models:
      text_to_speech:
        model: "Neural2"
        cost_per_character: 0.000016
      
      vision:
        model: "vision-v1"
        cost_per_image: 0.0015

# Usage tiers and limits
usage_tiers:
  free:
    daily_cost_limit: 5.00
    monthly_cost_limit: 20.00
    daily_operations_limit: 50
    monthly_operations_limit: 500
    
    allowed_operations:
      - story_generation
      - image_recognition
      - text_to_speech
      - whisper_timestamps
    
    restrictions:
      max_story_length: "medium"
      image_generation_enabled: false
      premium_voices: false
  
  premium:
    daily_cost_limit: 50.00
    monthly_cost_limit: 200.00
    daily_operations_limit: 500
    monthly_operations_limit: 5000
    
    allowed_operations:
      - story_generation
      - image_recognition
      - text_to_speech
      - whisper_timestamps
      - image_generation
      - content_customization
    
    restrictions:
      max_story_length: "long"
      image_generation_enabled: true
      premium_voices: true
      priority_processing: true
  
  enterprise:
    daily_cost_limit: 500.00
    monthly_cost_limit: 2000.00
    daily_operations_limit: 5000
    monthly_operations_limit: 50000
    
    allowed_operations: "all"
    restrictions: {}
    features:
      - dedicated_support
      - custom_prompts
      - white_label_options
      - advanced_analytics

# Cost optimization
cost_optimization:
  auto_provider_switching: true
  cost_threshold_switching: true
  performance_based_routing: true
  
  strategies:
    - name: "cost_efficient"
      description: "Prioritize lowest cost providers"
      rules:
        - if: "user_tier == 'free' and daily_cost > 3.00"
          then: "use_cheapest_provider"
    
    - name: "quality_first"
      description: "Prioritize highest quality providers"
      rules:
        - if: "user_tier == 'premium'"
          then: "use_best_quality_provider"
    
    - name: "balanced"
      description: "Balance cost and quality"
      rules:
        - if: "user_tier == 'free'"
          then: "use_balanced_provider"

# Monitoring and alerts
monitoring:
  cost_alerts:
    daily_threshold: 1000.00
    user_threshold_multiplier: 2.0  # Alert if user exceeds 2x their limit
    vendor_budget_alert: 5000.00
  
  performance_alerts:
    error_rate_threshold: 0.05  # 5% error rate
    latency_threshold_ms: 30000
    success_rate_threshold: 0.95
  
  analytics:
    vendor_dashboard_sync: true
    cost_attribution: true
    performance_tracking: true
    user_behavior_analytics: true

# Feature flags
features:
  word_highlighting: true
  background_music: true
  image_generation: true
  multi_language: false  # Coming soon
  voice_cloning: false   # Future feature
  interactive_stories: false  # Future feature

# Security
security:
  content_filtering: "strict"
  pii_detection: true
  abuse_detection: true
  
  abuse_thresholds:
    rapid_requests: 10  # requests in 1 minute
    unusual_patterns: true
    cost_spike_detection: true
    geographic_anomalies: true

# Remote configuration settings
remote_config:
  enabled: true
  provider: "firebase"  # 'firebase', 'custom_api', 'supabase'
  sync_interval_minutes: 5
  fallback_to_local: true
  cache_duration_hours: 24
  
  endpoints:
    firebase_project_id: "${FIREBASE_PROJECT_ID}"
    custom_api_url: "${REMOTE_CONFIG_API_URL}"
    supabase_function_url: "${SUPABASE_EDGE_FUNCTION_URL}"
```

### Remote Configuration Implementation

#### Service Architecture
```python
# services/remote_config_service.py
class RemoteConfigService:
    def __init__(self, provider='firebase'):
        self.provider = provider
        self.cache = {}
        self.last_sync = None
        self.sync_interval = timedelta(minutes=5)
        
    async def get_config(self, key: str, default_value=None):
        """Get configuration value with fallback to local config"""
        
        # Check if sync is needed
        if self._should_sync():
            await self._sync_remote_config()
        
        # Return cached value or default
        return self.cache.get(key, default_value)
    
    async def _sync_remote_config(self):
        """Sync configuration from remote source"""
        try:
            if self.provider == 'firebase':
                config = await self._fetch_firebase_config()
            elif self.provider == 'supabase':
                config = await self._fetch_supabase_config()
            else:
                config = await self._fetch_custom_api_config()
            
            # Update cache
            self.cache.update(config)
            self.last_sync = datetime.utcnow()
            
            # Log successful sync
            logger.info(f"Remote config synced: {len(config)} keys updated")
            
        except Exception as e:
            logger.warning(f"Remote config sync failed: {e}")
            # Continue with cached values
    
    def _should_sync(self):
        """Check if configuration should be synced"""
        if not self.last_sync:
            return True
        return datetime.utcnow() - self.last_sync > self.sync_interval
    
    async def _fetch_firebase_config(self):
        """Fetch from Firebase Remote Config"""
        # Implementation for Firebase
        pass
    
    async def _fetch_supabase_config(self):
        """Fetch from Supabase database"""
        query = """
        SELECT config_key, config_value 
        FROM app_configurations 
        WHERE is_active = true 
        AND environment = %s
        """
        results = await self.db.fetch_all(query, [self.environment])
        
        config = {}
        for row in results:
            config[row['config_key']] = row['config_value']
        
        return config

# Integration with AI services
class AIServiceWithRemoteConfig(BaseAIService):
    def __init__(self, provider_config, cost_tracker, prompt_manager, remote_config):
        super().__init__(provider_config, cost_tracker, prompt_manager)
        self.remote_config = remote_config
    
    async def execute(self, operation_type: str, user_context: dict, **kwargs):
        # Check if AI services are enabled
        ai_enabled = await self.remote_config.get_config('ai_services_enabled', True)
        if not ai_enabled:
            raise AIServiceDisabledError("AI services temporarily disabled")
        
        # Get dynamic rate limits
        rate_limit = await self.remote_config.get_config(
            f'rate_limits.{operation_type}', 
            self.provider.default_rate_limit
        )
        
        # Check maintenance mode
        maintenance_mode = await self.remote_config.get_config('maintenance_mode', False)
        if maintenance_mode:
            raise MaintenanceModeError("System is under maintenance")
        
        # Get dynamic cost limits
        user_tier = user_context.get('user_tier', 'free')
        cost_limit = await self.remote_config.get_config(
            f'usage_limits.{user_tier}.daily_cost_limit',
            5.00
        )
        
        # Apply dynamic limits before execution
        await self._check_dynamic_limits(user_context, rate_limit, cost_limit)
        
        return await super().execute(operation_type, user_context, **kwargs)
```

#### Admin Dashboard for Remote Config
```typescript
// Admin interface for managing remote configuration
interface RemoteConfigManager {
  // Real-time configuration updates
  updateConfig(key: string, value: any): Promise<void>;
  
  // Feature flag management
  enableFeature(feature: string, userSegment?: string): Promise<void>;
  disableFeature(feature: string): Promise<void>;
  
  // Emergency controls
  enableMaintenanceMode(): Promise<void>;
  disableAIServices(): Promise<void>;
  updateRateLimits(limits: RateLimits): Promise<void>;
  
  // A/B testing
  createExperiment(experiment: Experiment): Promise<void>;
  updateTrafficSplit(experimentId: string, split: TrafficSplit): Promise<void>;
}
```

#### Use Cases for Remote Configuration

**1. Emergency Cost Control**
```json
{
  "emergency_controls": {
    "max_daily_cost_per_user": 2.00,
    "disable_expensive_features": true,
    "force_cheapest_providers": true
  }
}
```

**2. Feature Rollout**
```json
{
  "feature_flags": {
    "word_highlighting": {
      "enabled": true,
      "rollout_percentage": 50,
      "user_segments": ["premium", "beta_testers"]
    }
  }
}
```

**3. Provider Switching**
```json
{
  "ai_providers": {
    "openai": {
      "enabled": false,
      "reason": "Rate limit exceeded"
    },
    "anthropic": {
      "enabled": true,
      "priority": 1
    }
  }
}
```

**4. Dynamic Pricing**
```json
{
  "usage_limits": {
    "free_tier": {
      "daily_cost_limit": 3.00,
      "monthly_operations": 30
    },
    "premium_tier": {
      "daily_cost_limit": 75.00,
      "monthly_operations": 750
    }
  }
}
```

---

## 7. Implementation Phases

### Phase 1: Foundation & Infrastructure (Week 1-2)
**Goal**: Build the core architecture and database foundation

#### Backend Tasks:
- [ ] **Database Schema Migration**
  - Create `ai_operations` table
  - Create `user_usage_tracking` table  
  - Create `prompt_analytics` table
  - Create `prompt_experiments` table
  - Modify `stories` table with new columns
  - Add proper indexes and constraints

- [ ] **Configuration Management System**
  - Create `config/` directory structure
  - Implement YAML configuration loading
  - Environment variable integration
  - Configuration validation and schema
  - Hot-reload capability for development

- [ ] **Prompt Management System**
  - Create `prompts/` directory structure
  - Implement YAML prompt loading
  - Template rendering with Jinja2/similar
  - Version control integration
  - Prompt validation and testing

- [ ] **Cost Tracking Infrastructure**
  - `CostTracker` service implementation
  - Real-time cost calculation
  - Usage limits enforcement
  - Database integration for tracking
  - Alert system for cost overruns

- [ ] **AI Service Factory Foundation**
  - Base `AIService` class
  - Provider abstraction layer
  - Error handling and retry logic
  - Logging and monitoring integration
  - Service discovery and registration

#### Testing & Documentation:
- [ ] Unit tests for core services
- [ ] Configuration validation tests
- [ ] Database migration scripts
- [ ] API documentation updates
- [ ] Developer setup guide

**Deliverables**: 
- Working configuration system
- Database schema ready for AI operations
- Basic cost tracking operational
- Prompt management system functional

---

### Phase 2: AI Services Integration (Week 3-4)
**Goal**: Implement all AI operations with full tracking and provider switching

#### AI Service Implementation:
- [ ] **Story Generation Service**
  - OpenAI GPT-4 integration
  - Anthropic Claude fallback
  - Dynamic prompt loading
  - Content safety validation
  - Quality checks and scoring

- [ ] **Image Recognition Service**
  - OpenAI GPT-4V integration
  - Google Vision API fallback
  - Image preprocessing and optimization
  - Scene analysis and description generation
  - Child-friendly interpretation

- [ ] **Text-to-Speech Service**
  - OpenAI TTS integration
  - Google Cloud TTS fallback
  - Voice selection and customization
  - Audio quality optimization
  - File storage and CDN integration

- [ ] **Whisper Timestamp Service**
  - OpenAI Whisper integration
  - Word-level timestamp extraction
  - Audio preprocessing
  - Timestamp formatting and validation
  - Integration with story display

- [ ] **Image Generation Service** (if in scope)
  - OpenAI DALL-E 3 integration
  - Prompt engineering for kid-friendly images
  - Style consistency and safety
  - Image optimization and storage

- [ ] **Content Safety Service**
  - OpenAI Moderation API
  - Custom content filtering
  - Age-appropriate content validation
  - Parent preference enforcement

#### Provider Management:
- [ ] **Smart Provider Selection**
  - Cost-based routing
  - Performance-based routing
  - User tier consideration
  - Automatic failover logic

- [ ] **Usage Monitoring**
  - Real-time usage tracking
  - Limit enforcement
  - Abuse detection algorithms
  - User notification system

#### Integration & Testing:
- [ ] End-to-end story generation pipeline
- [ ] Provider switching testing
- [ ] Cost calculation validation
- [ ] Performance benchmarking
- [ ] Error handling verification

**Deliverables**:
- All AI services operational
- Provider switching working
- Cost tracking accurate
- Usage limits enforced

---

### Phase 3: Advanced Features & Analytics (Week 5-6)
**Goal**: Implement advanced features, analytics, and optimization

#### Advanced Analytics:
- [ ] **Vendor Analytics Integration**
  - User metadata in API requests
  - Vendor dashboard synchronization
  - Cross-platform analytics correlation
  - Performance metrics collection

- [ ] **A/B Testing Framework**
  - Prompt experiment management
  - Traffic splitting logic
  - Statistical significance testing
  - Automated winner selection
  - Results reporting dashboard

- [ ] **Performance Optimization**
  - Caching strategies implementation
  - Request batching where possible
  - Async processing optimization
  - Database query optimization
  - CDN integration for assets

#### Monitoring & Alerting:
- [ ] **Real-time Dashboards**
  - Cost monitoring dashboard
  - Performance metrics visualization
  - User behavior analytics
  - Vendor performance comparison
  - System health monitoring

- [ ] **Alert System**
  - Cost threshold alerts
  - Performance degradation alerts
  - Abuse detection notifications
  - System error alerts
  - Capacity planning alerts

#### User Experience Features:
- [ ] **Word Highlighting Implementation**
  - Frontend timestamp synchronization
  - Visual highlighting effects
  - Reading progress tracking
  - Educational analytics

- [ ] **Quality Improvements**
  - Story quality scoring
  - User feedback integration
  - Continuous prompt optimization
  - Content personalization enhancement

#### Admin & Management:
- [ ] **Admin Dashboard**
  - User management interface
  - Cost monitoring and controls
  - Prompt management UI
  - Analytics and reporting
  - System configuration management

- [ ] **API Documentation**
  - Complete API reference
  - Integration guides
  - SDK development (if needed)
  - Third-party integration docs

**Deliverables**:
- Complete analytics system
- A/B testing operational
- Admin dashboard functional
- Word highlighting working
- Full monitoring and alerting

---

### Phase 4: Production Readiness & Optimization (Week 7-8)
**Goal**: Prepare system for production deployment with full monitoring

#### Production Deployment:
- [ ] **Environment Configuration**
  - Production configuration setup
  - Secrets management
  - Environment-specific settings
  - Deployment automation
  - Rollback procedures

- [ ] **Security Hardening**
  - API security audit
  - Data encryption verification
  - Access control implementation
  - Vulnerability assessment
  - Compliance verification

- [ ] **Performance Optimization**
  - Load testing and optimization
  - Database performance tuning
  - Caching strategy refinement
  - CDN optimization
  - API rate limiting

#### Monitoring & Maintenance:
- [ ] **Production Monitoring**
  - Application performance monitoring
  - Infrastructure monitoring
  - Log aggregation and analysis
  - Error tracking and alerting
  - Capacity monitoring

- [ ] **Backup & Recovery**
  - Database backup strategy
  - Configuration backup
  - Disaster recovery plan
  - Data retention policies
  - Recovery testing

#### Documentation & Training:
- [ ] **Operations Documentation**
  - Deployment procedures
  - Monitoring guides
  - Troubleshooting runbooks
  - Configuration management
  - Incident response procedures

- [ ] **User Documentation**
  - Feature documentation
  - API usage guides
  - Integration examples
  - FAQ and troubleshooting
  - Release notes

**Deliverables**:
- Production-ready deployment
- Complete monitoring system
- Security hardening complete
- Documentation finished
- Team training completed

---

## 8. Success Metrics & KPIs

### Technical Metrics
- **Cost Efficiency**: Average cost per story generation < $0.50
- **Performance**: 95th percentile response time < 30 seconds
- **Reliability**: 99.5% uptime and success rate
- **Scalability**: Handle 1000+ concurrent story generations

### Business Metrics  
- **User Engagement**: Average stories per user per month
- **Cost Control**: Stay within budget thresholds
- **Quality**: User satisfaction rating > 4.5/5
- **Growth**: Support 10x user growth without major changes

### Analytics & Insights
- **Provider Performance**: Compare cost/quality across vendors
- **Feature Usage**: Track most popular features and story types
- **User Behavior**: Understand usage patterns and preferences
- **Optimization Opportunities**: Identify areas for improvement

---

## 9. Risk Management

### Technical Risks
- **Vendor API Changes**: Mitigated by abstraction layer and multiple providers
- **Cost Overruns**: Mitigated by real-time tracking and automatic limits
- **Performance Issues**: Mitigated by monitoring and optimization
- **Data Security**: Mitigated by encryption and access controls

### Business Risks
- **User Abuse**: Mitigated by usage limits and abuse detection
- **Compliance Issues**: Mitigated by content filtering and safety measures
- **Vendor Lock-in**: Mitigated by multi-provider architecture
- **Quality Degradation**: Mitigated by quality monitoring and A/B testing

### Operational Risks
- **Team Knowledge**: Documented procedures and cross-training
- **Deployment Issues**: Automated testing and rollback procedures
- **Monitoring Gaps**: Comprehensive monitoring and alerting
- **Configuration Errors**: Validation and testing procedures

---

## 10. Future Enhancements

### Short-term (3-6 months)
- **Multi-language Support**: Stories in different languages
- **Voice Customization**: Custom voice training for families
- **Interactive Stories**: User choice-driven narratives
- **Advanced Analytics**: Predictive analytics and recommendations

### Medium-term (6-12 months)
- **Real-time Collaboration**: Multiple kids creating stories together
- **AR/VR Integration**: Immersive storytelling experiences
- **Educational Curriculum**: Structured learning paths
- **Teacher/School Integration**: Classroom management features

### Long-term (12+ months)
- **AI Character Development**: Persistent characters that grow with kids
- **Social Features**: Story sharing and community
- **White-label Solutions**: Platform for other organizations
- **Advanced Personalization**: Deep learning from user behavior

---

This architecture plan provides a comprehensive roadmap for building a robust, scalable, and cost-controlled AI storytelling platform. The modular design allows for incremental implementation while maintaining flexibility for future enhancements.