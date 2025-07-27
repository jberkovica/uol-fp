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
    status: StoryStatus
    language: Language
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
    avatar_type: str
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