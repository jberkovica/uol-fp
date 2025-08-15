# Mira Storyteller - Story Generation Improvement Plan

## Overview
This document outlines the comprehensive improvements to the story generation system, focusing on better personalization, cleaner architecture, and enhanced user experience.

## Phase 1: Prompt Architecture Refactoring

### 1.1 JSON Response Format Implementation
**Problem**: Random title formatting with `**title**` markers causing parsing issues.

**Solution**: 
- Request structured JSON output from all LLMs
- Expected format:
  ```json
  {
    "title": "The Magical Adventure",
    "content": "Story content here..."
  }
  ```

**Implementation**:
- Add JSON schema validation using Pydantic models
- Include `response_format: "json"` for vendors that support it (OpenAI, Anthropic)
- Add explicit JSON instruction in prompt for other vendors
- Implement fallback parsing for non-JSON responses

### 1.2 Unified Language Handling
**Problem**: Multiple prompt templates (default, with_language, with_theme) create unnecessary complexity.

**Solution**:
- Single unified prompt template with language always as parameter
- Remove conditional logic for language selection
- Template structure:
  ```yaml
  user_prompt: |
    Generate a children's story as JSON with "title" and "content" fields.
    
    Base the story on: {image_description}
    Language: {language}
    Story length: {word_count} words
    Age group: {age_group}
    
    Additional context: {optional_context}
  ```

### 1.3 Vendor-Agnostic Prompts
**Problem**: Different prompts for different vendors (mistral, openai, etc.) without clear benefit.

**Solution**:
- Remove all vendor-specific prompts
- Single prompt works for all modern LLMs
- Remove "You are Mira" persona (doesn't improve output quality)
- Vendor differences handled only through API parameters (temperature, max_tokens)

## Phase 2: Enhanced Kid Profile System

### 2.1 Natural Language Appearance System
**Problem**: Color pickers and dropdowns are too limiting for describing children's unique features.

**Solution**: Natural language description with two input methods:

#### Option A: Photo Upload
1. Parent uploads child's photo (one-time)
2. Vision API extracts description (~$0.01 cost, one-time)
3. Description stored permanently in Supabase
4. Parent can edit/enhance the extracted description

#### Option B: Manual Description
- Free-form text field for appearance description
- Examples: "Curly brown hair in pigtails with pink bows, bright blue eyes, always wears dinosaur hat"
- More expressive than dropdown selections

### 2.2 Updated Data Model

#### Kid Profile Fields:
```python
class KidProfile:
    # Basic Info (Required)
    id: str
    name: str
    age: int  # Now mandatory - critical for age-appropriate content
    
    # Appearance (Optional)
    appearance_method: str  # 'photo', 'manual', or null
    appearance_description: str  # Natural language description
    appearance_extracted_at: datetime  # When features were extracted
    appearance_metadata: dict  # Extraction details, model used, etc.
    
    # Preferences (Optional)
    favorite_genres: List[str]
    parent_notes: str  # "Loves teddy bear Max, new sibling coming"
    preferred_language: str  # From kid profile, not per-story
```

### 2.3 Supabase Database Schema Updates

```sql
-- Update kids table
ALTER TABLE kids ADD COLUMN age INTEGER NOT NULL;
ALTER TABLE kids ADD COLUMN appearance_method VARCHAR(20);  -- 'photo', 'manual', null
ALTER TABLE kids ADD COLUMN appearance_description TEXT;  -- Final description used
ALTER TABLE kids ADD COLUMN appearance_extracted_at TIMESTAMPTZ;
ALTER TABLE kids ADD COLUMN appearance_metadata JSONB;  -- Extraction details
ALTER TABLE kids ADD COLUMN parent_notes TEXT;
ALTER TABLE kids ADD COLUMN preferred_language VARCHAR(5) REFERENCES languages(code);

-- Update stories table for image storage
ALTER TABLE stories ADD COLUMN cover_image_url TEXT;  -- Supabase storage URL
ALTER TABLE stories ADD COLUMN cover_image_thumbnail_url TEXT;  -- Smaller version
ALTER TABLE stories ADD COLUMN cover_image_metadata JSONB;  -- Generation params, prompt used
ALTER TABLE stories ADD COLUMN cover_image_generated_at TIMESTAMPTZ;
```

### 2.4 UI/UX Flow

#### Step 1: Basic Information (Required)
```
┌─────────────────────────────────────────┐
│  Let's create a profile for your child  │
│                                          │
│  Name: [_______________] *               │
│  Age:  [___] *                          │
│                                          │
│  [Continue →]                           │
└─────────────────────────────────────────┘
```

#### Step 2: Appearance (Optional)
```
┌─────────────────────────────────────────┐
│  Personalize Stories (Optional)         │
│                                          │
│  Help us create magical stories with    │
│  your child as the main character!      │
│                                          │
│  [📷 Upload Photo]  OR  [✏️ Describe]    │
│                                          │
│  [Skip for now →]                       │
│                                          │
│  ℹ️ We'll use this to create custom     │
│  illustrations featuring your child     │
└─────────────────────────────────────────┘
```

If manual description chosen:
```
┌─────────────────────────────────────────┐
│  Describe your child's appearance:      │
│  ┌─────────────────────────────────┐    │
│  │ Examples:                       │    │
│  │ "Short black hair with bangs,   │    │
│  │  wears round glasses"           │    │
│  │                                  │    │
│  │ "Curly red hair, freckles,      │    │
│  │  loves her unicorn shirt"       │    │
│  └─────────────────────────────────┘    │
└─────────────────────────────────────────┘
```

#### Step 3: Preferences (Optional)
```
┌─────────────────────────────────────────┐
│  Additional Information (Optional)      │
│                                          │
│  Favorite story types:                  │
│  [Adventure] [Animals] [Magic] [+More]  │
│                                          │
│  Special notes for stories:             │
│  ┌─────────────────────────────────┐    │
│  │ e.g., "Loves her teddy Max",    │    │
│  │ "Big sister to baby Emma"       │    │
│  └─────────────────────────────────┘    │
│                                          │
│  [Complete Profile →]                   │
└─────────────────────────────────────────┘
```

### 2.5 Parent Dashboard Redesign

Replace settings dropdown with 4 clear action buttons:

```
┌─────────────────────────────────────────┐
│  Sarah's Profile                        │
│                                          │
│  [👤 Edit Info]  [🎨 Appearance]        │
│  [⭐ Preferences] [🗑️ Delete]            │
└─────────────────────────────────────────┘
```

## Phase 3: Smart Context Usage System

### 3.1 Context Variation Configuration

Instead of using kid's data in every story, implement smart variation:

```yaml
context_variation:
  kid_appearance:
    story_text_inclusion: 0.3  # 30% chance to mention in story text
    story_text_detail_level: "light"  # Don't over-describe
    
  image_generation:
    include_kid: 0.9  # 90% of images include the kid
    representation_types:
      close_up: 0.2
      full_body: 0.4
      background_presence: 0.3
      not_shown: 0.1
  
  genres:
    selection_strategy: "weighted_random"
    max_per_story: 2  # Don't overwhelm with all genres
  
  parent_notes:
    inclusion_probability: 0.5  # 50% chance to incorporate
    subtlety_level: "natural"  # Weave in naturally, not forced
```

### 3.2 Story Generation Request Structure

```python
class StoryGenerationContext:
    # Main content (always included)
    image_description: str  # From uploaded image/audio/text
    
    # Kid context (intelligently included)
    kid_context: {
        "name": "Sarah",  # Always included
        "age": 5,  # Always included for age-appropriate content
        "appearance": "Curly brown hair in pigtails...",  # Sometimes included
        "include_appearance": 0.3,  # Random weight for this request
        "genres": ["adventure", "animals"],  # Randomly selected subset
        "parent_notes": "loves teddy bear Max",  # Sometimes included
    }
    
    # Instructions
    output_format: "json"
    word_count: "150-200"
    language: "en"  # From kid's profile
```

## Phase 4: Image Generation Implementation

### 4.1 Artist Agent Architecture

Create new agent at `/backend/src/agents/artist/agent.py`:

```python
class ArtistAgent(BaseAgent):
    """Generate story cover images using DALL-E 3."""
    
    async def generate_cover(
        self,
        story_data: dict,
        kid_data: dict,
        style_config: dict
    ) -> dict:
        # Build prompt with consistent style
        prompt = self.build_image_prompt(story_data, kid_data)
        
        # Generate image
        image_url = await self.generate_with_dalle(prompt)
        
        # Store in Supabase
        stored_url = await self.store_in_supabase(image_url)
        
        return {
            "url": stored_url,
            "thumbnail_url": thumbnail_url,
            "metadata": {
                "prompt": prompt,
                "model": "dall-e-3",
                "timestamp": datetime.now(),
                "kid_included": include_kid_decision
            }
        }
```

### 4.2 Image Prompt Strategy

```python
def build_image_prompt(story_data, kid_data, include_kid_random):
    """Build DALL-E prompt with consistent style and optional kid inclusion."""
    
    base_style = """
    Square illustration (1024x1024), children's book style.
    Soft watercolor/pastel aesthetic.
    Warm palette: lavender, peach, cream, soft yellow.
    Dreamy, magical atmosphere with gentle lighting.
    White borders blending into background.
    """
    
    # Extract key story elements
    story_elements = extract_visual_elements(story_data['content'])
    
    # Conditionally include kid
    if include_kid_random > 0.1:  # 90% include kid
        kid_description = format_kid_for_image(
            kid_data['appearance_description'],
            get_representation_type()  # close-up, full-body, etc.
        )
    else:
        kid_description = ""
    
    prompt = f"""
    {base_style}
    
    Scene: {story_data['title']}
    Elements: {story_elements}
    {kid_description}
    
    Composition: Leave space at top for UI overlay.
    No text in image.
    """
    
    return prompt.strip()
```

### 4.3 Supabase Storage Integration

```python
async def store_generated_image(image_url: str, story_id: str) -> dict:
    """Download and store generated image in Supabase Storage."""
    
    # Download image from DALL-E URL
    image_data = await download_image(image_url)
    
    # Upload to Supabase Storage
    bucket = "story-covers"
    path = f"{story_id}/cover.png"
    
    supabase.storage.from_(bucket).upload(path, image_data)
    
    # Generate thumbnail
    thumbnail = generate_thumbnail(image_data)
    thumbnail_path = f"{story_id}/thumbnail.png"
    supabase.storage.from_(bucket).upload(thumbnail_path, thumbnail)
    
    # Get public URLs
    cover_url = supabase.storage.from_(bucket).get_public_url(path)
    thumbnail_url = supabase.storage.from_(bucket).get_public_url(thumbnail_path)
    
    # Update story record
    supabase.table('stories').update({
        'cover_image_url': cover_url,
        'cover_image_thumbnail_url': thumbnail_url,
        'cover_image_generated_at': datetime.now(),
        'cover_image_metadata': {
            'original_url': image_url,
            'prompt_used': prompt,
            'model': 'dall-e-3',
            'generation_params': params
        }
    }).eq('id', story_id).execute()
    
    return {
        'cover_url': cover_url,
        'thumbnail_url': thumbnail_url
    }
```

### 4.4 Parallel Processing

```python
async def process_story_generation(request: StoryRequest):
    """Generate story, TTS, and image in parallel."""
    
    # Start all three processes simultaneously
    story_task = generate_story(request)
    
    # Wait for story to complete first (needed for TTS and image)
    story_result = await story_task
    
    # Now start TTS and image generation in parallel
    tts_task = generate_audio(story_result['content'])
    image_task = generate_image(story_result, kid_data)
    
    # Wait for both to complete
    audio_result, image_result = await asyncio.gather(
        tts_task,
        image_task
    )
    
    return {
        'story': story_result,
        'audio': audio_result,
        'image': image_result
    }
```

## Phase 5: Configuration Restructure

### 5.1 Simplified agents.yaml

```yaml
# Mira Storyteller AI Agents Configuration
agents:
  vision:
    vendor: ${VISION_VENDOR:-google}
    model: ${VISION_MODEL:-gemini-2.0-flash-exp}
    api_key: ${GOOGLE_API_KEY}
    prompt: |
      Describe this image focusing on main visual elements:
      - Main subject/objects (be specific)
      - Colors and atmosphere
      - Setting and mood
      Return a clear, factual description.

  storyteller:
    vendor: ${STORY_VENDOR:-mistral}
    model: ${STORY_MODEL:-mistral-medium-latest}
    api_key: ${MISTRAL_API_KEY}
    params:
      max_tokens: 300
      temperature: 0.7
      response_format: "json"  # For vendors that support it
    
    prompt: |
      Generate a children's story as JSON with "title" and "content" fields.
      
      Base the story on: {image_description}
      Child's name: {kid_name}
      Age group: {age_group}
      Language: {language}
      Word count: {word_count}
      
      Additional context (use naturally if provided): {context}
      
      The story should be imaginative, positive, and age-appropriate.
      Return valid JSON only.

  artist:
    vendor: "openai"
    model: "dall-e-3"
    api_key: ${OPENAI_API_KEY}
    params:
      size: "1024x1024"
      quality: "hd"
      style: "natural"
    
    style_config:
      base_prompt: |
        Children's book illustration, square format.
        Soft watercolor/pastel style.
        Warm colors: lavender, peach, cream, soft yellow.
        Dreamy, magical atmosphere.
        No text in image.
      
      kid_representation:
        include_probability: 0.9
        variation_types:
          close_up: 0.2
          full_body: 0.4
          background: 0.3
          not_shown: 0.1

  voice:
    # Keep existing voice configuration
    languages:
      en:
        vendor: "elevenlabs"
        # ... existing config ...

  speech:
    # Keep existing speech configuration
    vendor: "openai"
    # ... existing config ...
```

### 5.2 Removed/Simplified Elements

- ❌ Remove `with_theme` prompt (never used)
- ❌ Remove vendor-specific system prompts
- ❌ Remove "You are Mira" persona
- ❌ Remove complex conditional prompt selection
- ✅ Single prompt template for all vendors
- ✅ Parameters clearly separated from prompts

## Phase 6: Implementation Timeline

### Week 1: Foundation
- [ ] Implement JSON response format with Pydantic validation
- [ ] Refactor to single unified prompt
- [ ] Remove vendor-specific prompt logic
- [ ] Test with all current vendors (Mistral, OpenAI, Anthropic, Google)

### Week 2: Data Model
- [ ] Update Supabase schema with new fields
- [ ] Modify Kid model to include appearance fields
- [ ] Implement appearance extraction from photo
- [ ] Create natural language appearance UI

### Week 3: Context System
- [ ] Implement context variation logic
- [ ] Add weighted random selection for genres
- [ ] Create smart inclusion logic for kid details
- [ ] Test variation in generated stories

### Week 4: Image Generation
- [ ] Create Artist agent
- [ ] Implement DALL-E 3 integration
- [ ] Set up Supabase storage for images
- [ ] Add parallel processing for TTS + image

### Week 5: UI Updates
- [ ] Redesign kid profile creation flow
- [ ] Update parent dashboard with 4-button layout
- [ ] Add image display in story viewer
- [ ] Implement photo upload flow

### Week 6: Testing & Optimization
- [ ] End-to-end testing of new flow
- [ ] Performance optimization
- [ ] Cost analysis and monitoring
- [ ] A/B testing of context variations

## Success Metrics

1. **Technical**
   - JSON parsing success rate > 95%
   - Image generation success rate > 90%
   - Average total generation time < 15 seconds

2. **User Experience**
   - Parent profile creation completion rate > 80%
   - Stories with personalization used > 60%
   - Kid appearance included in appropriate variety

3. **Cost**
   - Average cost per story < $0.15 (including image)
   - One-time profile setup cost < $0.02

## Risk Mitigation

1. **JSON Parsing Failures**
   - Fallback to regex parsing
   - Store both raw and parsed responses

2. **Image Generation Failures**
   - Retry logic with simplified prompts
   - Default placeholder images

3. **Cost Overruns**
   - Implement daily limits
   - Cache generated content
   - Optional image generation for free tier

## Conclusion

This plan modernizes the story generation system with:
- Cleaner, maintainable architecture
- Better personalization without repetition
- Natural, flexible user input
- Consistent visual style
- Smart use of context for variety

The system becomes more intelligent about when and how to use personalization, creating magical experiences without overwhelming repetition.