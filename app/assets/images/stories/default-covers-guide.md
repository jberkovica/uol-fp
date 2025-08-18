# Default Cover Images Guide

This document describes the default cover images setup for stories.

## Current Implementation (Phase 1)

### Required Default Cover Images

Create these TWO images and upload them to the Supabase `story-covers/default/` bucket:

#### 1. general.png
- **Theme**: Generic children's book illustration
- **Description**: Colorful, whimsical design with books, stars, or rainbow
- **Colors**: Bright, cheerful colors (blues, yellows, pinks)
- **Size**: 1024x1024
- **Purpose**: Default cover for stories when AI generation fails

#### 2. general-thumbnail.png
- **Theme**: Same as above but smaller
- **Size**: 200x200
- **Purpose**: Thumbnail version for story cards

## Future Enhancement (Phase 2)

In the future, you can add category-specific default covers:
- adventure.png & adventure-thumbnail.png
- friendship.png & friendship-thumbnail.png
- family.png & family-thumbnail.png
- fantasy.png & fantasy-thumbnail.png
- animals.png & animals-thumbnail.png
- space.png & space-thumbnail.png
- ocean.png & ocean-thumbnail.png

The backend code has placeholders for category detection that can be enabled later.

## Image Specifications

- **Format**: PNG with transparency support
- **Main images**: 1024x1024 pixels
- **Thumbnails**: 200x200 pixels
- **Style**: Child-friendly, colorful, illustration style
- **Background**: Can be transparent or solid color
- **Text**: No text in images (titles will be separate)

## Upload Instructions

1. Create/design the 16 image files (8 main + 8 thumbnails)
2. Upload to Supabase Storage bucket: `story-covers`
3. Create folder structure:
   ```
   story-covers/
   └── default/
       ├── general.png
       ├── general-thumbnail.png
       ├── adventure.png
       ├── adventure-thumbnail.png
       ├── friendship.png
       ├── friendship-thumbnail.png
       ├── family.png
       ├── family-thumbnail.png
       ├── fantasy.png
       ├── fantasy-thumbnail.png
       ├── animals.png
       ├── animals-thumbnail.png
       ├── space.png
       ├── space-thumbnail.png
       ├── ocean.png
       └── ocean-thumbnail.png
   ```

## Fallback Chain

The system will use this fallback chain:

### For New Stories (Backend):
1. **AI Generated Cover** → `story-covers/generated/[story-id]/cover.png`
2. **If AI fails** → `story-covers/default/[category].png` (automatically assigned by backend)
3. **If category detection fails** → `story-covers/default/general.png`

### For Existing Stories (Frontend):
1. **Generated Cover** → Network image from `coverImageThumbnailUrl`
2. **If empty/null URL** → `story-covers/default/general-thumbnail.png` (Supabase bucket)
3. **If bucket unavailable** → `assets/images/stories/general-thumbnail.png` (local asset)
4. **Final fallback** → Grey placeholder with photo icon

### Local Assets Available:
- `assets/images/stories/general.png` - Full size default cover (542KB)
- `assets/images/stories/general-thumbnail.png` - Thumbnail version (73KB)

This ensures every story always has a cover image to display, prioritizing Supabase bucket images over local assets.