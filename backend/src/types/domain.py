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
    avatar_type: str = Field(default="profile1")
    created_at: datetime
    updated_at: Optional[datetime] = None
    
    # Virtual field for backward compatibility
    @property
    def age(self) -> int:
        """Return a default age for backward compatibility."""
        return 5
    
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
    input_format: InputFormat = Field(default=InputFormat.IMAGE)
    language: Language = Field(default=Language.ENGLISH)
    status: StoryStatus = Field(default=StoryStatus.PENDING)
    created_at: datetime
    updated_at: Optional[datetime] = None
    metadata: Optional[dict] = Field(default_factory=dict)
    
    class Config:
        from_attributes = True