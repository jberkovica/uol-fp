"""Domain types for the application."""
from datetime import datetime
from typing import Optional
from enum import Enum
from pydantic import BaseModel, Field


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
    """Kid profile domain model."""
    id: str = Field(..., description="Unique identifier")
    user_id: str = Field(..., description="Parent's Supabase Auth ID")
    name: str = Field(..., min_length=1, max_length=50)
    age: Optional[int] = Field(default=5, ge=3, le=12, description="Child's age (3-12)")
    avatar_type: str = Field(default="profile1")
    hair_color: Optional[str] = Field(None, description="Hair color key")
    hair_length: Optional[str] = Field(None, description="Hair length key")
    skin_color: Optional[str] = Field(None, description="Skin color key")
    eye_color: Optional[str] = Field(None, description="Eye color key")
    gender: Optional[str] = Field(None, description="Gender identity")
    favorite_genres: list[str] = Field(default_factory=list, description="Preferred story genres")
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
    content: str = Field(default="", max_length=2000)  # Can be empty initially
    image_description: Optional[str] = Field(None, description="AI-generated image description")
    audio_filename: Optional[str] = Field(None, description="Generated audio filename/URL")
    audio_url: Optional[str] = Field(default=None, description="Full audio URL (computed)")
    language: Language = Field(default=Language.ENGLISH)
    status: StoryStatus = Field(default=StoryStatus.PENDING)
    created_at: datetime
    updated_at: Optional[datetime] = None
    metadata: Optional[dict] = Field(default_factory=dict)
    
    class Config:
        from_attributes = True