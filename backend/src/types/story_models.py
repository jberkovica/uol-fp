"""Pydantic models for story generation with JSON validation."""
from typing import Optional
from pydantic import BaseModel, Field, validator


class LLMStoryResponse(BaseModel):
    """Expected JSON response format from LLMs for story generation."""
    
    title: str = Field(
        ..., 
        min_length=1, 
        max_length=200,
        description="The story title"
    )
    content: str = Field(
        ..., 
        min_length=50,
        max_length=5000,  # Increased from 2000 to allow for longer stories
        description="The main story content"
    )
    cover_description: Optional[str] = Field(
        None,
        description="Concise visual description for story cover illustration (20-30 words)"
    )
    
    @validator('title')
    def clean_title(cls, v):
        """Remove any markdown formatting from title."""
        # Remove common markdown patterns
        v = v.strip()
        v = v.replace('**', '')
        v = v.replace('*', '')
        v = v.replace('#', '')
        v = v.strip('"').strip("'")
        return v
    
    @validator('content')
    def validate_content_length(cls, v):
        """Ensure story is appropriate length (flexible for testing)."""
        word_count = len(v.split())
        if word_count < 20:  # More lenient for testing
            raise ValueError(f"Story too short: {word_count} words (minimum 20)")
        if word_count > 500:  # More lenient for long stories
            raise ValueError(f"Story too long: {word_count} words (maximum 500)")
        return v
    
    @validator('cover_description')
    def validate_cover_description_length(cls, v):
        """Ensure cover description is concise (20-30 words)."""
        if v:
            word_count = len(v.split())
            if word_count > 30:  # Truncate if too many words
                words = v.split()[:30]
                return ' '.join(words)
            elif len(v) > 200:  # Truncate if too many characters
                return v[:197] + '...'
        return v
    
    class Config:
        """Pydantic configuration."""
        json_schema_extra = {
            "example": {
                "title": "The Magical Garden Adventure",
                "content": "Once upon a time, in a garden filled with rainbow flowers...",
                "cover_description": "A child standing in a magical garden surrounded by glowing rainbow flowers under a starry sky"
            }
        }


class StoryGenerationContext(BaseModel):
    """Context data for story generation."""
    
    # Required fields
    image_description: str = Field(..., description="Description of uploaded image/input")
    kid_name: str = Field(..., min_length=1, max_length=50)
    age: int = Field(..., ge=1, le=18)
    language: str = Field(default="en", pattern="^[a-z]{2}$")
    
    # Optional fields
    appearance_description: Optional[str] = Field(
        None, 
        description="Natural language description of child's appearance"
    )
    genres: Optional[list[str]] = Field(
        default_factory=list,
        description="Selected story genres"
    )
    parent_notes: Optional[str] = Field(
        None,
        description="Additional context from parent"
    )
    
    # Control parameters
    include_appearance: float = Field(
        default=0.3,
        ge=0.0,
        le=1.0,
        description="Probability of including appearance in this story"
    )
    word_count: str = Field(
        default="150-200",
        description="Target word count for story"
    )
    
    def build_context_string(self) -> str:
        """Build the context string for the prompt."""
        context_parts = []
        
        # Add genres if specified and not empty
        if self.genres and any(self.genres):
            # Filter out empty strings and take first 2 genres
            valid_genres = [g for g in self.genres if g and g.strip()][:2]
            if valid_genres:
                context_parts.append(f"Genres: {', '.join(valid_genres)}")
        
        # Add appearance based on probability (this will be randomized per request)
        if self.appearance_description and self.appearance_description.strip() and self.include_appearance > 0.5:
            context_parts.append(f"Child appearance: {self.appearance_description.strip()}")
        
        # Add parent notes if provided and not empty
        if self.parent_notes and self.parent_notes.strip():
            context_parts.append(f"Additional context: {self.parent_notes.strip()}")
        
        return " | ".join(context_parts) if context_parts else ""
    
    def get_age_group(self) -> str:
        """Return age-appropriate content descriptor."""
        if self.age <= 3:
            return "toddler (very simple language)"
        elif self.age <= 6:
            return "preschool (simple sentences)"
        elif self.age <= 9:
            return "early elementary (engaging narrative)"
        elif self.age <= 12:
            return "elementary (more complex stories)"
        else:
            return "young reader (sophisticated vocabulary)"


class StoryGenerationRequest(BaseModel):
    """Internal request model for story generation."""
    
    context: StoryGenerationContext
    vendor: Optional[str] = Field(None, description="Override default vendor")
    temperature: Optional[float] = Field(None, ge=0.0, le=2.0)
    max_tokens: Optional[int] = Field(None, ge=100, le=1000)