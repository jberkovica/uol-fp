"""Domain types for the application."""
from datetime import datetime
from typing import Optional
from enum import Enum
from pydantic import BaseModel, Field, validator


class StoryStatus(str, Enum):
    """Story processing status."""
    PENDING = "pending"
    PROCESSING = "processing"
    APPROVED = "approved"
    REJECTED = "rejected"
    ERROR = "error"
    TRANSCRIBING = "transcribing"  # Audio being transcribed
    DRAFT = "draft"  # Transcription complete, user editing
    ABANDONED = "abandoned"  # User left without submitting


class InputFormat(str, Enum):
    """Input format for story generation."""
    IMAGE = "image"
    TEXT = "text"
    VOICE = "voice"  # Future


class Language(str, Enum):
    """Supported languages."""
    ENGLISH = "en"
    RUSSIAN = "ru"
    LATVIAN = "lv"
    SPANISH = "es"


class Kid(BaseModel):
    """Kid profile domain model with natural language appearance system."""
    # Basic Info (Required)
    id: str = Field(..., description="Unique identifier")
    user_id: str = Field(..., description="Parent's Supabase Auth ID")
    name: str = Field(..., min_length=1, max_length=50)
    age: int = Field(..., ge=3, le=12, description="Child's age (3-12) - mandatory for age-appropriate content")
    gender: Optional[str] = Field(None, description="Child's gender: 'boy', 'girl', or 'other'")
    avatar_type: str = Field(default="profile1", description="UI avatar selection")
    
    # Natural Language Appearance System
    appearance_method: Optional[str] = Field(None, description="How appearance was set: 'photo', 'manual', or null")
    appearance_description: Optional[str] = Field(
        None,
        max_length=500,
        description="Natural language description of child's appearance"
    )
    appearance_extracted_at: Optional[datetime] = Field(None, description="When features were extracted from photo")
    appearance_metadata: Optional[dict] = Field(
        default_factory=dict,
        description="Extraction details, AI model used, confidence scores, etc."
    )
    
    # Story Preferences
    favorite_genres: list[str] = Field(default_factory=list, description="Preferred story genres")
    parent_notes: Optional[str] = Field(
        None,
        max_length=300,
        description="Special context for stories: hobbies, pets, siblings, etc."
    )
    preferred_language: str = Field(default="en", description="Child's preferred story language")
    
    # Timestamps
    created_at: datetime
    updated_at: Optional[datetime] = None
    
    class Config:
        from_attributes = True


class Story(BaseModel):
    """Story domain model."""
    id: str = Field(..., description="Unique identifier")
    kid_id: str = Field(..., description="Associated kid profile ID")
    child_name: Optional[str] = Field(default=None, description="Child's name (optional, joined from kids table)")
    title: str = Field(..., min_length=1, max_length=200)
    content: str = Field(default="", max_length=5000)  # Can be empty initially - matches story_models.py
    image_description: Optional[str] = Field(None, description="AI-generated image description")
    audio_filename: Optional[str] = Field(None, description="Generated audio filename/URL")
    audio_url: Optional[str] = Field(default=None, description="Full audio URL (computed)")
    background_music_filename: Optional[str] = Field(None, description="Background music filename")
    background_music_url: Optional[str] = Field(default=None, description="Full background music URL (computed)")
    
    # Cover image fields
    cover_image_url: Optional[str] = Field(None, description="URL to the generated cover image in Supabase Storage")
    cover_image_thumbnail_url: Optional[str] = Field(None, description="URL to the thumbnail version of the cover image")
    cover_image_metadata: Optional[dict] = Field(default_factory=dict, description="Image generation metadata (prompt, model, etc.)")
    cover_image_generated_at: Optional[datetime] = Field(None, description="When the cover image was generated")
    
    language: Language = Field(default=Language.ENGLISH)
    status: StoryStatus = Field(default=StoryStatus.PENDING)
    is_favourite: bool = Field(default=False, description="Whether story is marked as favourite")
    created_at: datetime
    updated_at: Optional[datetime] = None
    metadata: Optional[dict] = Field(default_factory=dict)
    
    @validator('cover_image_metadata', pre=True)
    def parse_cover_image_metadata(cls, v):
        """Parse JSON string to dict if needed."""
        if v is None:
            return {}
        if isinstance(v, str):
            try:
                import json
                return json.loads(v)
            except (json.JSONDecodeError, TypeError):
                return {}
        return v if isinstance(v, dict) else {}
    
    class Config:
        from_attributes = True