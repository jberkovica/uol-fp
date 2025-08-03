# Mira Storyteller - Database Design Specification

## Overview

This document outlines the PostgreSQL database design for Mira Storyteller, built on Supabase with multi-language support, family subscriptions, and privacy-by-design architecture.

## Core Design Principles

1. **Privacy-by-Design**: Row Level Security (RLS) for family data isolation
2. **Multi-Language First**: International support from day one
3. **Family-Centric**: Subscription and user management around family units
4. **GDPR Compliant**: Built-in support for data subject rights
5. **Scalable**: Designed to handle growth from day one

## Database Schema

### 1. Languages & Internationalization

```sql
-- Supported languages table
CREATE TABLE languages (
    code VARCHAR(5) PRIMARY KEY,           -- ISO codes: 'en', 'ru', 'lv', 'es'
    name VARCHAR(50) NOT NULL,            -- English names: 'English', 'Russian'
    native_name VARCHAR(50) NOT NULL,     -- Native names: 'English', 'Русский', 'Latviešu'
    enabled BOOLEAN DEFAULT true,         -- Can be disabled for maintenance
    ai_model_config JSONB DEFAULT '{}',   -- Language-specific AI model settings
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Initial data
INSERT INTO languages (code, name, native_name, enabled) VALUES
('en', 'English', 'English', true),
('ru', 'Russian', 'Русский', true),
('lv', 'Latvian', 'Latviešu', true),
('es', 'Spanish', 'Español', false); -- Will enable later

-- Localized content for app interface
CREATE TABLE translations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    language_code VARCHAR(5) REFERENCES languages(code),
    translation_key VARCHAR(100) NOT NULL,  -- 'welcome_message', 'story_generated'
    translation_value TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(language_code, translation_key)
);
```

### 2. Family & Subscription Management

```sql
-- Family units (subscription holders)
CREATE TABLE families (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL,
    primary_language VARCHAR(5) REFERENCES languages(code) DEFAULT 'en',
    subscription_tier VARCHAR(20) CHECK (subscription_tier IN ('free', 'family', 'premium')) DEFAULT 'free',
    subscription_status VARCHAR(20) CHECK (subscription_status IN ('active', 'expired', 'cancelled', 'trial')) DEFAULT 'trial',
    subscription_expires_at TIMESTAMP WITH TIME ZONE,
    billing_email VARCHAR(255),
    timezone VARCHAR(50) DEFAULT 'UTC',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Subscription plans configuration
CREATE TABLE subscription_plans (
    tier VARCHAR(20) PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    stories_per_month INTEGER NOT NULL,
    languages_included INTEGER NOT NULL,    -- Number of languages allowed
    price_monthly DECIMAL(10,2),
    price_yearly DECIMAL(10,2),
    features JSONB DEFAULT '{}',            -- Additional features as JSON
    active BOOLEAN DEFAULT true
);

-- Initial plans
INSERT INTO subscription_plans (tier, name, stories_per_month, languages_included, price_monthly, price_yearly) VALUES
('free', 'Free Plan', 5, 1, 0.00, 0.00),
('family', 'Family Plan', 50, 3, 9.99, 99.99),
('premium', 'Premium Plan', -1, -1, 19.99, 199.99); -- -1 = unlimited

-- Monthly usage tracking
CREATE TABLE family_usage (
    family_id UUID REFERENCES families(id),
    month_year VARCHAR(7) NOT NULL,        -- '2025-06'
    stories_generated INTEGER DEFAULT 0,
    languages_used VARCHAR(5)[] DEFAULT ARRAY[]::VARCHAR[],
    last_updated TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    PRIMARY KEY (family_id, month_year)
);
```

### 3. User Profiles & Roles

```sql
-- User profiles (extends Supabase auth.users)
CREATE TABLE user_profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    family_id UUID REFERENCES families(id) ON DELETE CASCADE,
    role VARCHAR(20) CHECK (role IN ('parent', 'child')) NOT NULL,
    display_name VARCHAR(100) NOT NULL,
    preferred_language VARCHAR(5) REFERENCES languages(code) DEFAULT 'en',
    age INTEGER CHECK (age > 0 AND age < 150),
    age_group VARCHAR(10) GENERATED ALWAYS AS (
        CASE 
            WHEN age <= 3 THEN '0-3'
            WHEN age <= 6 THEN '4-6'
            WHEN age <= 9 THEN '7-9'
            WHEN age <= 12 THEN '10-12'
            ELSE '13+'
        END
    ) STORED,
    avatar_emoji VARCHAR(10),              -- Simple emoji avatar
    preferences JSONB DEFAULT '{}',        -- Story preferences, voice settings
    parental_consent_given BOOLEAN DEFAULT false,
    last_active TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Family invitations for adding new members
CREATE TABLE family_invitations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    family_id UUID REFERENCES families(id),
    invited_email VARCHAR(255) NOT NULL,
    invited_by UUID REFERENCES user_profiles(id),
    role VARCHAR(20) CHECK (role IN ('parent', 'child')) NOT NULL,
    token VARCHAR(100) UNIQUE NOT NULL,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    accepted_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### 4. Stories & Content

```sql
-- Generated stories
CREATE TABLE stories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    family_id UUID REFERENCES families(id),
    child_id UUID REFERENCES user_profiles(id),        -- Who the story is for
    created_by UUID REFERENCES user_profiles(id),      -- Who created it (usually parent)
    title VARCHAR(200) NOT NULL,
    content TEXT NOT NULL,
    language VARCHAR(5) REFERENCES languages(code) NOT NULL,
    image_caption TEXT,                                 -- Generated by AI
    image_description TEXT,                             -- User-provided description (optional)
    audio_filename VARCHAR(255),                        -- Reference to audio file
    audio_url TEXT,                                     -- Temporary download URL
    status VARCHAR(20) CHECK (status IN ('processing', 'pending', 'approved', 'rejected', 'archived')) DEFAULT 'processing',
    ai_models_used JSONB DEFAULT '{}',                  -- Track which models were used
    generation_metadata JSONB DEFAULT '{}',            -- Model parameters, processing time, etc.
    approval_notes TEXT,                                -- Parent's notes when approving/rejecting
    approved_at TIMESTAMP WITH TIME ZONE,
    approved_by UUID REFERENCES user_profiles(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT story_child_in_family CHECK (
        child_id IN (SELECT id FROM user_profiles WHERE family_id = stories.family_id)
    ),
    CONSTRAINT story_creator_in_family CHECK (
        created_by IN (SELECT id FROM user_profiles WHERE family_id = stories.family_id)
    )
);

-- Story interactions and engagement
CREATE TABLE story_interactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    story_id UUID REFERENCES stories(id) ON DELETE CASCADE,
    user_id UUID REFERENCES user_profiles(id),
    interaction_type VARCHAR(20) CHECK (interaction_type IN ('listen', 'favorite', 'share', 'download')) NOT NULL,
    interaction_data JSONB DEFAULT '{}',                -- Additional data (e.g., listen duration)
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(story_id, user_id, interaction_type, created_at::date) -- One per day per type
);

-- Story tags and categories (for future features)
CREATE TABLE story_tags (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(50) NOT NULL,
    color VARCHAR(7),                                   -- Hex color code
    language VARCHAR(5) REFERENCES languages(code),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(name, language)
);

CREATE TABLE story_tag_assignments (
    story_id UUID REFERENCES stories(id) ON DELETE CASCADE,
    tag_id UUID REFERENCES story_tags(id) ON DELETE CASCADE,
    PRIMARY KEY (story_id, tag_id)
);
```

### 5. Analytics & Monitoring

```sql
-- Privacy-compliant analytics (no PII)
CREATE TABLE app_analytics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_type VARCHAR(50) NOT NULL,               -- 'story_generated', 'language_changed'
    language VARCHAR(5) REFERENCES languages(code),
    age_group VARCHAR(10),                          -- Anonymized age groups
    subscription_tier VARCHAR(20),
    event_data JSONB DEFAULT '{}',                  -- Non-identifying metadata
    session_id UUID,                                -- Anonymous session tracking
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- System performance monitoring
CREATE TABLE system_metrics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    metric_name VARCHAR(50) NOT NULL,              -- 'story_generation_time', 'ai_api_latency'
    metric_value DECIMAL(10,2) NOT NULL,
    metric_unit VARCHAR(20),                        -- 'seconds', 'count', 'percentage'
    service_name VARCHAR(50),                       -- 'mistral', 'gemini', 'elevenlabs'
    recorded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### 6. GDPR & Compliance

```sql
-- Data subject requests (GDPR compliance)
CREATE TABLE data_subject_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES user_profiles(id),
    request_type VARCHAR(20) CHECK (request_type IN ('access', 'rectification', 'erasure', 'portability', 'objection')) NOT NULL,
    status VARCHAR(20) CHECK (status IN ('submitted', 'in_progress', 'completed', 'rejected')) DEFAULT 'submitted',
    request_details TEXT,
    response_data TEXT,
    completed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Audit log for security and compliance
CREATE TABLE audit_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    table_name VARCHAR(50) NOT NULL,
    record_id UUID,
    action VARCHAR(20) NOT NULL,                    -- 'INSERT', 'UPDATE', 'DELETE'
    old_values JSONB,
    new_values JSONB,
    user_id UUID REFERENCES auth.users(id),
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

## Row Level Security Policies

```sql
-- Enable RLS on all tables
ALTER TABLE families ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE stories ENABLE ROW LEVEL SECURITY;
ALTER TABLE story_interactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE family_usage ENABLE ROW LEVEL SECURITY;

-- Families: Users can only access their own family
CREATE POLICY family_access ON families
    FOR ALL USING (
        id IN (SELECT family_id FROM user_profiles WHERE id = auth.uid())
    );

-- User profiles: Users can see family members only
CREATE POLICY family_members_only ON user_profiles
    FOR ALL USING (
        family_id IN (SELECT family_id FROM user_profiles WHERE id = auth.uid())
    );

-- Stories: Family members can see family stories
CREATE POLICY family_stories_only ON stories
    FOR ALL USING (
        family_id IN (SELECT family_id FROM user_profiles WHERE id = auth.uid())
    );

-- Parents can approve/reject stories
CREATE POLICY parent_story_approval ON stories
    FOR UPDATE USING (
        auth.uid() IN (
            SELECT id FROM user_profiles 
            WHERE family_id = stories.family_id 
            AND role = 'parent'
        )
    );

-- Story interactions: Users can only see their own interactions
CREATE POLICY own_interactions_only ON story_interactions
    FOR ALL USING (user_id = auth.uid());

-- Family usage: Family members can view usage
CREATE POLICY family_usage_access ON family_usage
    FOR SELECT USING (
        family_id IN (SELECT family_id FROM user_profiles WHERE id = auth.uid())
    );
```

## Database Functions & Triggers

```sql
-- Function to check subscription limits
CREATE OR REPLACE FUNCTION check_story_generation_limit(p_family_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
    current_usage INTEGER;
    monthly_limit INTEGER;
    current_month VARCHAR(7);
BEGIN
    current_month := TO_CHAR(NOW(), 'YYYY-MM');
    
    -- Get current month's usage
    SELECT COALESCE(stories_generated, 0) INTO current_usage
    FROM family_usage 
    WHERE family_id = p_family_id AND month_year = current_month;
    
    -- Get subscription limit
    SELECT sp.stories_per_month INTO monthly_limit
    FROM families f
    JOIN subscription_plans sp ON f.subscription_tier = sp.tier
    WHERE f.id = p_family_id;
    
    -- Unlimited plan (-1) always allows
    IF monthly_limit = -1 THEN
        RETURN true;
    END IF;
    
    -- Check if under limit
    RETURN current_usage < monthly_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to increment story usage
CREATE OR REPLACE FUNCTION increment_story_usage(p_family_id UUID, p_language VARCHAR(5))
RETURNS VOID AS $$
DECLARE
    current_month VARCHAR(7);
BEGIN
    current_month := TO_CHAR(NOW(), 'YYYY-MM');
    
    INSERT INTO family_usage (family_id, month_year, stories_generated, languages_used)
    VALUES (p_family_id, current_month, 1, ARRAY[p_language])
    ON CONFLICT (family_id, month_year)
    DO UPDATE SET
        stories_generated = family_usage.stories_generated + 1,
        languages_used = array_append(family_usage.languages_used, p_language),
        last_updated = NOW();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to automatically update timestamps
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply to relevant tables
CREATE TRIGGER update_families_updated_at
    BEFORE UPDATE ON families
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_profiles_updated_at
    BEFORE UPDATE ON user_profiles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_stories_updated_at
    BEFORE UPDATE ON stories
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
```

## Indexes for Performance

```sql
-- Core performance indexes
CREATE INDEX idx_stories_family_language ON stories(family_id, language);
CREATE INDEX idx_stories_child_status ON stories(child_id, status);
CREATE INDEX idx_stories_created_at ON stories(created_at DESC);
CREATE INDEX idx_user_profiles_family_role ON user_profiles(family_id, role);
CREATE INDEX idx_story_interactions_story_user ON story_interactions(story_id, user_id);
CREATE INDEX idx_family_usage_month ON family_usage(month_year);
CREATE INDEX idx_analytics_event_date ON app_analytics(event_type, created_at);

-- Language-specific indexes
CREATE INDEX idx_stories_language_created ON stories(language, created_at DESC);
CREATE INDEX idx_user_profiles_language ON user_profiles(preferred_language);

-- Full-text search for stories (future feature)
CREATE INDEX idx_stories_fts ON stories USING gin(to_tsvector('english', title || ' ' || content));
```

## Migration Strategy

### Phase 1: Core Tables
1. Create languages and families tables
2. Set up user_profiles with basic fields
3. Implement basic RLS policies

### Phase 2: Story System
1. Create stories table with multi-language support
2. Add story_interactions for engagement tracking
3. Implement subscription checking functions

### Phase 3: Advanced Features
1. Add analytics tables (privacy-compliant)
2. Implement GDPR compliance tables
3. Add full-text search capabilities

### Phase 4: Optimization
1. Add performance indexes
2. Implement database monitoring
3. Set up automated backups and point-in-time recovery

## Data Volume Estimates

| Table | Year 1 | Year 3 | Year 5 |
|-------|--------|--------|--------|
| families | 1,000 | 10,000 | 50,000 |
| user_profiles | 4,000 | 40,000 | 200,000 |
| stories | 50,000 | 500,000 | 2,500,000 |
| story_interactions | 200,000 | 2,000,000 | 10,000,000 |
| app_analytics | 500,000 | 5,000,000 | 25,000,000 |

**Storage Estimate**: ~10GB by Year 5 (excluding audio files)

---

**Document Version**: 1.0  
**Last Updated**: 2025-06-27  
**Database Version**: PostgreSQL 15+ (Supabase)  
**Next Review**: 2025-09-27