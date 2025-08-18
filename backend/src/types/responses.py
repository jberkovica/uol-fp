"""Response types for API endpoints."""
from datetime import datetime
from typing import Optional, List
from pydantic import BaseModel, Field
from .domain import StoryStatus, InputFormat, Language


class StoryResponse(BaseModel):
    """Response for a single story."""
    id: str
    kid_id: str
    child_name: Optional[str] = None
    title: str
    content: str
    audio_url: Optional[str]
    audio_error: Optional[str] = None  # Include audio error info if audio generation failed
    background_music_url: Optional[str]
    cover_image_url: Optional[str] = None
    cover_image_thumbnail_url: Optional[str] = None
    status: StoryStatus
    language: Language
    is_favourite: bool = False
    created_at: datetime
    updated_at: Optional[datetime]
    
    class Config:
        from_attributes = True


class StoryListResponse(BaseModel):
    """Response for a list of stories."""
    stories: List[StoryResponse]
    total: int
    page: int = 1
    page_size: int = 20


class KidResponse(BaseModel):
    """Response for a single kid profile."""
    id: str
    user_id: str
    name: str
    age: int
    gender: Optional[str] = None
    avatar_type: str
    
    # Natural Language Appearance System
    appearance_method: Optional[str] = None
    appearance_description: Optional[str] = None
    appearance_extracted_at: Optional[datetime] = None
    appearance_metadata: Optional[dict] = Field(default_factory=dict)
    
    # Story Preferences
    favorite_genres: List[str] = Field(default_factory=list)
    parent_notes: Optional[str] = None
    preferred_language: str = "en"
    
    # Computed fields
    stories_count: int = 0
    created_at: datetime
    
    class Config:
        from_attributes = True


class KidListResponse(BaseModel):
    """Response for a list of kid profiles."""
    kids: List[KidResponse]
    total: int


class GenerateStoryResponse(BaseModel):
    """Response for story generation request."""
    story_id: str
    status: StoryStatus = StoryStatus.PROCESSING
    message: str = "Story generation started"


class HealthResponse(BaseModel):
    """Health check response."""
    status: str = "healthy"
    version: str
    timestamp: datetime = Field(default_factory=datetime.utcnow)
    services: dict = Field(default_factory=dict)


class ErrorResponse(BaseModel):
    """Error response."""
    error: str
    detail: Optional[str] = None
    code: Optional[str] = None
    timestamp: datetime = Field(default_factory=datetime.utcnow)


class InitiateStoryResponse(BaseModel):
    """Response for story initiation."""
    story_id: str
    status: StoryStatus
    message: str = "Story created in draft state"


class TranscriptionResponse(BaseModel):
    """Response for audio transcription."""
    story_id: str
    transcribed_text: str
    status: StoryStatus = StoryStatus.DRAFT
    message: str = "Audio transcribed successfully"


class ExtractAppearanceResponse(BaseModel):
    """Response for appearance extraction."""
    description: str = Field(..., description="Natural language appearance description")
    extracted_at: datetime = Field(default_factory=datetime.utcnow)
    model_used: str = Field(..., description="AI model used for extraction")
    vendor: str = Field(..., description="AI vendor used")
    confidence: str = Field(default="high", description="Extraction confidence level")
    word_count: int = Field(..., description="Number of words in description")
    extraction_method: str = Field(default="ai_vision", description="Method used for extraction")