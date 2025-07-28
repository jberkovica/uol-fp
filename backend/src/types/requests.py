"""Request types for API endpoints."""
from typing import Optional
from pydantic import BaseModel, Field, validator
from .domain import InputFormat, Language


class GenerateStoryRequest(BaseModel):
    """Request to generate a story from an image."""
    image_data: str = Field(..., description="Base64 encoded image data")
    kid_id: str = Field(..., description="ID of the kid profile")
    language: Language = Field(default=Language.ENGLISH, description="Story language")
    
    @validator('image_data')
    def validate_base64(cls, v):
        """Validate that image_data is valid base64."""
        import base64
        try:
            # Check if it's valid base64
            base64.b64decode(v)
            return v
        except Exception:
            raise ValueError("Invalid base64 image data")


class CreateKidRequest(BaseModel):
    """Request to create a new kid profile."""
    name: str = Field(..., min_length=1, max_length=50, description="Kid's name")
    age: Optional[int] = Field(None, ge=3, le=12, description="Kid's age (3-12 years)")
    avatar_type: str = Field(default="profile1", description="Avatar selection")
    hair_color: Optional[str] = Field(None, description="Hair color key")
    hair_length: Optional[str] = Field(None, description="Hair length key")
    skin_color: Optional[str] = Field(None, description="Skin color key")
    eye_color: Optional[str] = Field(None, description="Eye color key")
    gender: Optional[str] = Field(None, description="Gender identity")
    favorite_genres: list[str] = Field(default_factory=list, description="Preferred story genres")
    user_id: str = Field(..., description="Parent's Supabase Auth ID")


class UpdateKidRequest(BaseModel):
    """Request to update a kid profile."""
    name: Optional[str] = Field(None, min_length=1, max_length=50)
    age: Optional[int] = Field(None, ge=3, le=12, description="Kid's age (3-12 years)")
    avatar_type: Optional[str] = Field(None)
    hair_color: Optional[str] = Field(None, description="Hair color key")
    hair_length: Optional[str] = Field(None, description="Hair length key")
    skin_color: Optional[str] = Field(None, description="Skin color key")
    eye_color: Optional[str] = Field(None, description="Eye color key")
    gender: Optional[str] = Field(None, description="Gender identity")
    favorite_genres: Optional[list[str]] = Field(None, description="Preferred story genres")


class ReviewStoryRequest(BaseModel):
    """Request to review/update a story."""
    title: Optional[str] = Field(None, min_length=1, max_length=200)
    content: Optional[str] = Field(None, min_length=50, max_length=2000)
    status: Optional[str] = Field(None, description="New status")


class TextToStoryRequest(BaseModel):
    """Future: Generate story from text prompt."""
    prompt: str = Field(..., min_length=10, max_length=500)
    kid_id: str = Field(..., description="ID of the kid profile")
    language: Language = Field(default=Language.ENGLISH)


class VoiceToStoryRequest(BaseModel):
    """Future: Generate story from voice recording."""
    audio_data: str = Field(..., description="Base64 encoded audio data")
    kid_id: str = Field(..., description="ID of the kid profile")
    language: Language = Field(default=Language.ENGLISH)