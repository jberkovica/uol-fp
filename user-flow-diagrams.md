# Mira Storyteller - User Flow Diagrams

## 1. Authentication & Onboarding Flow

```mermaid
graph TD
    START([App Launch]) --> SPLASH[Splash Screen<br/>Mira Character Animation]
    SPLASH --> AUTH_CHECK{User<br/>Authenticated?}
    
    AUTH_CHECK -->|No| LOGIN[Login Screen<br/>Email/Phone + OTP]
    AUTH_CHECK -->|Yes| PROFILE_CHECK{Has Kid<br/>Profiles?}
    
    LOGIN --> OTP[OTP Verification<br/>Supabase Auth]
    OTP --> SUCCESS{OTP<br/>Valid?}
    SUCCESS -->|No| LOGIN
    SUCCESS -->|Yes| FIRST_TIME{First Time<br/>User?}
    
    FIRST_TIME -->|Yes| ONBOARDING[Welcome Onboarding<br/>App Introduction]
    FIRST_TIME -->|No| PROFILE_CHECK
    
    ONBOARDING --> CREATE_KID[Create First Kid Profile<br/>Name, Age, Avatar]
    CREATE_KID --> PIN_SETUP[Parent PIN Setup<br/>4-digit security PIN]
    PIN_SETUP --> APPROVAL_MODE[Choose Approval Mode<br/>Auto/Manual/Email]
    APPROVAL_MODE --> CHILD_HOME
    
    PROFILE_CHECK -->|No| CREATE_KID
    PROFILE_CHECK -->|Yes| SELECT_PROFILE[Profile Selection<br/>Choose Child Profile]
    SELECT_PROFILE --> CHILD_HOME[Child Home Screen<br/>Story Creation Interface]

    %% Styling
    classDef start fill:#E8F4FD,stroke:#1976D2,stroke-width:3px
    classDef auth fill:#FFF8E1,stroke:#F57C00,stroke-width:2px
    classDef profile fill:#F3E5F5,stroke:#7B1FA2,stroke-width:2px
    classDef decision fill:#FFEBEE,stroke:#D32F2F,stroke-width:2px
    classDef end fill:#E8F5E8,stroke:#388E3C,stroke-width:3px

    class START start
    class LOGIN,OTP,ONBOARDING auth
    class CREATE_KID,SELECT_PROFILE,PIN_SETUP,APPROVAL_MODE profile
    class AUTH_CHECK,SUCCESS,FIRST_TIME,PROFILE_CHECK decision
    class CHILD_HOME end
```

## 2. Story Creation Flow (Multiple Input Methods)

```mermaid
graph TD
    HOME[Child Home Screen] --> INPUT_CHOICE{Choose Input Method}
    
    %% Image Input Path
    INPUT_CHOICE -->|Camera/Gallery| IMG_CAPTURE[Image Capture<br/>Camera or Gallery]
    IMG_CAPTURE --> IMG_PREVIEW[Image Preview<br/>Confirm Selection]
    IMG_PREVIEW --> IMG_SUBMIT[Submit Image<br/>Start Processing]
    
    %% Text Input Path
    INPUT_CHOICE -->|Text| TEXT_INPUT[Text Input Screen<br/>Type Story Idea]
    TEXT_INPUT --> TEXT_VALIDATE{Text Valid?<br/>10-500 chars}
    TEXT_VALIDATE -->|No| TEXT_INPUT
    TEXT_VALIDATE -->|Yes| TEXT_SUBMIT[Submit Text<br/>Start Processing]
    
    %% Audio Input Path
    INPUT_CHOICE -->|Microphone| AUDIO_RECORD[Audio Recording<br/>Real-time Waveform]
    AUDIO_RECORD --> AUDIO_PLAYBACK[Audio Playback<br/>Review Recording]
    AUDIO_PLAYBACK --> AUDIO_CHOICE{Keep Recording?}
    AUDIO_CHOICE -->|No| AUDIO_RECORD
    AUDIO_CHOICE -->|Yes| AUDIO_SUBMIT[Submit Audio<br/>Start Processing]
    
    %% Processing Convergence
    IMG_SUBMIT --> PROCESSING[Processing Screen<br/>Animated Mira Character]
    TEXT_SUBMIT --> PROCESSING
    AUDIO_SUBMIT --> PROCESSING
    
    PROCESSING --> AI_PIPELINE[AI Processing Pipeline<br/>Background Tasks]
    AI_PIPELINE --> POLL_STATUS[Poll Story Status<br/>Every 2 seconds]
    POLL_STATUS --> STATUS_CHECK{Story<br/>Complete?}
    STATUS_CHECK -->|No| POLL_STATUS
    STATUS_CHECK -->|Yes| APPROVAL_CHECK{Requires<br/>Approval?}
    
    APPROVAL_CHECK -->|No| STORY_READY[Story Ready Screen<br/>Play Audio & Read]
    APPROVAL_CHECK -->|Yes| PENDING[Pending Approval<br/>Notify Parent]
    PENDING --> PARENT_REVIEW[Parent Review<br/>Approve/Reject]
    PARENT_REVIEW --> APPROVED{Approved?}
    APPROVED -->|Yes| STORY_READY
    APPROVED -->|No| REJECTED[Story Rejected<br/>Try Again]
    REJECTED --> HOME

    %% Styling
    classDef input fill:#E3F2FD,stroke:#1976D2,stroke-width:2px
    classDef processing fill:#FFF3E0,stroke:#F57C00,stroke-width:2px
    classDef approval fill:#FCE4EC,stroke:#C2185B,stroke-width:2px
    classDef decision fill:#FFEBEE,stroke:#D32F2F,stroke-width:2px
    classDef success fill:#E8F5E8,stroke:#388E3C,stroke-width:3px

    class IMG_CAPTURE,IMG_PREVIEW,TEXT_INPUT,AUDIO_RECORD,AUDIO_PLAYBACK input
    class PROCESSING,AI_PIPELINE,POLL_STATUS processing
    class PENDING,PARENT_REVIEW,APPROVED approval
    class INPUT_CHOICE,TEXT_VALIDATE,AUDIO_CHOICE,STATUS_CHECK,APPROVAL_CHECK decision
    class STORY_READY success
```

## 3. Parent Dashboard & Management Flow

```mermaid
graph TD
    PARENT_ACCESS[Parent Access Request] --> PIN_ENTRY[Enter Parent PIN<br/>4-digit security]
    PIN_ENTRY --> PIN_VALID{PIN<br/>Correct?}
    PIN_VALID -->|No| PIN_RETRY[PIN Retry<br/>Max 3 attempts]
    PIN_RETRY --> PIN_LOCKOUT{Max Attempts<br/>Reached?}
    PIN_LOCKOUT -->|Yes| BIOMETRIC_FALLBACK[Biometric Authentication<br/>Fingerprint/Face ID]
    PIN_LOCKOUT -->|No| PIN_ENTRY
    PIN_VALID -->|Yes| PARENT_DASHBOARD
    BIOMETRIC_FALLBACK --> PARENT_DASHBOARD[Parent Dashboard<br/>Management Interface]
    
    PARENT_DASHBOARD --> DASHBOARD_CHOICE{Choose Action}
    
    %% Story Management Path
    DASHBOARD_CHOICE -->|Story Review| PENDING_STORIES[Pending Stories<br/>Awaiting Approval]
    PENDING_STORIES --> STORY_DETAIL[Story Detail View<br/>Read Content + Listen]
    STORY_DETAIL --> APPROVAL_DECISION{Approve<br/>Story?}
    APPROVAL_DECISION -->|Yes| APPROVE_STORY[Approve Story<br/>Make Available to Child]
    APPROVAL_DECISION -->|No| REJECT_STORY[Reject Story<br/>Add Rejection Reason]
    APPROVE_STORY --> NOTIFICATION[Send Notification<br/>Story Ready for Child]
    REJECT_STORY --> NOTIFICATION
    
    %% Kid Profile Management
    DASHBOARD_CHOICE -->|Manage Kids| KID_LIST[Kid Profiles List<br/>All Family Children]
    KID_LIST --> KID_ACTION{Choose Action}
    KID_ACTION -->|Edit| EDIT_KID[Edit Kid Profile<br/>Name, Age, Avatar, Preferences]
    KID_ACTION -->|Add| ADD_KID[Add New Kid<br/>Create Profile]
    KID_ACTION -->|Stories| KID_STORIES[Kid's Story History<br/>All Created Stories]
    
    %% Settings Management
    DASHBOARD_CHOICE -->|Settings| SETTINGS[Parent Settings<br/>Configuration]
    SETTINGS --> SETTINGS_CHOICE{Choose Setting}
    SETTINGS_CHOICE -->|PIN| CHANGE_PIN[Change Parent PIN<br/>Security Update]
    SETTINGS_CHOICE -->|Approval| APPROVAL_MODE[Change Approval Mode<br/>Auto/Manual/Email]
    SETTINGS_CHOICE -->|Language| LANGUAGE_PREF[Language Preferences<br/>App & Story Language]
    SETTINGS_CHOICE -->|Analytics| ANALYTICS_VIEW[Usage Analytics<br/>Story Generation Stats]
    
    %% Return paths
    NOTIFICATION --> PARENT_DASHBOARD
    EDIT_KID --> PARENT_DASHBOARD
    ADD_KID --> PARENT_DASHBOARD
    KID_STORIES --> PARENT_DASHBOARD
    CHANGE_PIN --> PARENT_DASHBOARD
    APPROVAL_MODE --> PARENT_DASHBOARD
    LANGUAGE_PREF --> PARENT_DASHBOARD
    ANALYTICS_VIEW --> PARENT_DASHBOARD

    %% Styling
    classDef auth fill:#FFEBEE,stroke:#D32F2F,stroke-width:2px
    classDef dashboard fill:#E8F4FD,stroke:#1976D2,stroke-width:2px
    classDef story fill:#F3E5F5,stroke:#7B1FA2,stroke-width:2px
    classDef management fill:#FFF8E1,stroke:#F57C00,stroke-width:2px
    classDef decision fill:#FFCDD2,stroke:#D32F2F,stroke-width:2px

    class PIN_ENTRY,PIN_RETRY,BIOMETRIC_FALLBACK auth
    class PARENT_DASHBOARD,NOTIFICATION dashboard
    class PENDING_STORIES,STORY_DETAIL,APPROVE_STORY,REJECT_STORY story
    class KID_LIST,EDIT_KID,ADD_KID,SETTINGS,CHANGE_PIN,APPROVAL_MODE management
    class PIN_VALID,PIN_LOCKOUT,DASHBOARD_CHOICE,APPROVAL_DECISION,KID_ACTION,SETTINGS_CHOICE decision
```

## 4. Story Processing & AI Pipeline Flow

```mermaid
graph TD
    INPUT[User Input<br/>Image/Text/Audio] --> VALIDATE[Input Validation<br/>Size, Format, Content]
    VALIDATE --> VALID{Input<br/>Valid?}
    VALID -->|No| ERROR[Show Error<br/>Return to Input]
    VALID -->|Yes| CREATE_RECORD[Create Story Record<br/>Status: Pending]
    
    CREATE_RECORD --> BG_TASK[Start Background Task<br/>Async Processing]
    BG_TASK --> UPDATE_STATUS[Update Status<br/>Processing]
    
    %% AI Processing Pipeline
    UPDATE_STATUS --> DETERMINE_PATH{Input<br/>Type?}
    
    %% Image Path
    DETERMINE_PATH -->|Image| VISION_AGENT[Vision Agent<br/>Image Analysis]
    VISION_AGENT --> VISION_API[AI Vision API<br/>OpenAI/Google]
    VISION_API --> DESCRIPTION[Extract Description<br/>Scene, Characters, Objects]
    
    %% Text Path (Direct)
    DETERMINE_PATH -->|Text| DESCRIPTION
    
    %% Audio Path
    DETERMINE_PATH -->|Audio| SPEECH_TO_TEXT[Speech-to-Text<br/>OpenAI Whisper]
    SPEECH_TO_TEXT --> TRANSCRIPTION[Audio Transcription<br/>Convert to Text]
    TRANSCRIPTION --> DESCRIPTION
    
    %% Story Generation
    DESCRIPTION --> STORY_AGENT[Storyteller Agent<br/>Content Generation]
    STORY_AGENT --> STORY_API[Story Generation API<br/>LLM Providers]
    STORY_API --> STORY_CONTENT[Generated Story<br/>Title + Content]
    
    %% Voice Synthesis
    STORY_CONTENT --> VOICE_AGENT[Voice Agent<br/>Text-to-Speech]
    VOICE_AGENT --> TTS_API[TTS API<br/>ElevenLabs/OpenAI]
    TTS_API --> AUDIO_FILE[Generated Audio<br/>MP3 File]
    
    %% Storage & Completion
    AUDIO_FILE --> UPLOAD_AUDIO[Upload Audio<br/>Supabase Storage]
    UPLOAD_AUDIO --> UPDATE_RECORD[Update Story Record<br/>Content + Audio URL]
    UPDATE_RECORD --> CHECK_APPROVAL{Approval<br/>Required?}
    
    CHECK_APPROVAL -->|Auto| APPROVE_AUTO[Auto-Approve<br/>Status: Approved]
    CHECK_APPROVAL -->|Manual| PENDING_APPROVAL[Set Pending<br/>Notify Parent]
    CHECK_APPROVAL -->|Email| EMAIL_NOTIFY[Send Email<br/>Edge Function]
    
    APPROVE_AUTO --> COMPLETE[Story Complete<br/>Available to Child]
    PENDING_APPROVAL --> COMPLETE
    EMAIL_NOTIFY --> COMPLETE
    
    %% Error Handling
    VISION_API -.->|Error| HANDLE_ERROR[Handle Error<br/>Update Status: Error]
    STORY_API -.->|Error| HANDLE_ERROR
    TTS_API -.->|Error| HANDLE_ERROR
    HANDLE_ERROR --> ERROR_NOTIFY[Notify User<br/>Processing Failed]

    %% Styling
    classDef input fill:#E3F2FD,stroke:#1976D2,stroke-width:2px
    classDef validation fill:#FFF3E0,stroke:#F57C00,stroke-width:2px
    classDef ai fill:#F3E5F5,stroke:#7B1FA2,stroke-width:2px
    classDef storage fill:#E8F5E8,stroke:#388E3C,stroke-width:2px
    classDef decision fill:#FFEBEE,stroke:#D32F2F,stroke-width:2px
    classDef error fill:#FFCDD2,stroke:#F44336,stroke-width:2px

    class INPUT,DESCRIPTION,STORY_CONTENT,AUDIO_FILE input
    class VALIDATE,CREATE_RECORD,BG_TASK,UPDATE_STATUS validation
    class VISION_AGENT,VISION_API,STORY_AGENT,STORY_API,VOICE_AGENT,TTS_API,SPEECH_TO_TEXT ai
    class UPLOAD_AUDIO,UPDATE_RECORD,COMPLETE storage
    class VALID,DETERMINE_PATH,CHECK_APPROVAL decision
    class ERROR,HANDLE_ERROR,ERROR_NOTIFY error
```

## 5. Real-time Communication & Updates

```mermaid
sequenceDiagram
    participant C as Child App
    participant A as API Backend
    participant AI as AI Agents
    participant S as Supabase
    participant P as Parent App
    participant E as Email Service

    Note over C,E: Story Generation with Real-time Updates

    C->>A: Submit story request
    A->>S: Create story record (pending)
    A-->>C: Return story_id

    Note over A,AI: Background Processing
    A->>AI: Process through agents
    Note over AI: Vision → Story → Voice
    AI->>S: Update story progress
    
    Note over C,A: Real-time Polling
    loop Every 2 seconds
        C->>A: GET /story/{id}
        A->>S: Fetch story status
        S-->>A: Return current status
        A-->>C: Status update
    end

    AI->>S: Complete story processing
    
    alt Auto Approval
        S->>S: Set status: approved
        C->>A: Final poll
        A-->>C: Story ready!
    else Manual Approval
        S->>S: Set status: pending
        S->>P: Push notification (future)
        P->>A: Review story
        P->>S: Approve/Reject
        S-->>C: Status change
    else Email Approval
        A->>E: Send notification email
        E-->>P: Email with approval link
        P->>A: Click approval link
        A->>S: Update status
        S-->>C: Story approved
    end

    C->>A: Play approved story
    A->>S: Log interaction
```

## 6. Key User Experience Flows

### Child Experience Flow
1. **Simple Input**: Choose between camera, text, or microphone
2. **Visual Feedback**: Real-time waveforms, loading animations
3. **Immediate Engagement**: Processing screen with Mira character
4. **Story Consumption**: Audio playback with text display

### Parent Experience Flow
1. **Secure Access**: PIN + biometric authentication
2. **Review Control**: Approve/reject stories before child access
3. **Family Management**: Multiple child profiles, preferences
4. **Usage Insights**: Analytics and story history

### Privacy & Safety Flow
1. **Family Isolation**: RLS ensures family data separation
2. **Parental Controls**: Multiple approval modes (auto/manual/email)
3. **Content Moderation**: AI content filtering (future enhancement)
4. **Data Rights**: GDPR-compliant data management

This user flow design ensures a safe, engaging experience for children while providing parents with appropriate oversight and control mechanisms.