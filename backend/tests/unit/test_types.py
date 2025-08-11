"""Unit tests for Pydantic type models."""
import pytest
from datetime import datetime
from pydantic import ValidationError
from src.types.domain import Kid, Story, StoryStatus, InputFormat, Language
from src.types.requests import GenerateStoryRequest, CreateKidRequest, UpdateKidRequest
from src.types.responses import StoryResponse, KidResponse, HealthResponse


class TestDomainTypes:
    """Test domain model types."""
    
    def test_kid_model_valid_data(self):
        """Test Kid model with valid data."""
        kid_data = {
            "id": "kid-123",
            "user_id": "user-456",
            "name": "Alice",
            "age": 6,
            "gender": "girl",
            "avatar_type": "profile1",
            "created_at": datetime.now()
        }
        
        kid = Kid(**kid_data)
        assert kid.id == "kid-123"
        assert kid.name == "Alice"
        assert kid.age == 6
        assert kid.gender == "girl"
        assert kid.avatar_type == "profile1"
    
    def test_kid_model_validation_errors(self):
        """Test Kid model validation errors."""
        # Test name too long
        with pytest.raises(ValidationError):
            Kid(
                id="kid-123",
                user_id="user-456",
                name="A" * 51,  # Too long
                age=6,
                created_at=datetime.now()
            )
        
        # Test invalid age
        with pytest.raises(ValidationError):
            Kid(
                id="kid-123",
                user_id="user-456",
                name="Alice",
                age=0,  # Too young
                created_at=datetime.now()
            )
        
        with pytest.raises(ValidationError):
            Kid(
                id="kid-123",
                user_id="user-456",
                name="Alice",
                age=19,  # Too old
                created_at=datetime.now()
            )
    
    def test_kid_model_with_appearance_system(self):
        """Test Kid model with natural language appearance system."""
        kid_data = {
            "id": "kid-123",
            "user_id": "user-456",
            "name": "Alice",
            "age": 6,
            "gender": "girl",
            "avatar_type": "profile1",
            "appearance_method": "photo",
            "appearance_description": "Brown curly hair, green eyes, loves wearing princess dresses",
            "appearance_extracted_at": datetime.now(),
            "appearance_metadata": {"ai_model": "vision-pro", "confidence": 0.95},
            "favorite_genres": ["fantasy", "adventure"],
            "parent_notes": "Loves stories about brave princesses",
            "preferred_language": "en",
            "created_at": datetime.now()
        }
        
        kid = Kid(**kid_data)
        assert kid.appearance_method == "photo"
        assert kid.appearance_description == "Brown curly hair, green eyes, loves wearing princess dresses"
        assert kid.favorite_genres == ["fantasy", "adventure"]
        assert kid.parent_notes == "Loves stories about brave princesses"
        assert kid.preferred_language == "en"
        
    def test_kid_model_gender_validation(self):
        """Test Kid model gender field validation."""
        # Test valid gender values
        for gender in ["boy", "girl", "other"]:
            kid_data = {
                "id": "kid-123",
                "user_id": "user-456",
                "name": "Alice",
                "age": 6,
                "gender": gender,
                "avatar_type": "profile1",
                "created_at": datetime.now()
            }
            kid = Kid(**kid_data)
            assert kid.gender == gender
        
        # Test optional gender (None)
        kid_data = {
            "id": "kid-123",
            "user_id": "user-456",
            "name": "Alice",
            "age": 6,
            "avatar_type": "profile1",
            "created_at": datetime.now()
        }
        kid = Kid(**kid_data)
        assert kid.gender is None
    
    def test_story_model_valid_data(self):
        """Test Story model with valid data."""
        story_data = {
            "id": "story-789",
            "kid_id": "kid-123",
            "title": "The Magic Garden",
            "content": "Once upon a time, there was a magical garden filled with wonder and joy. " * 10,  # Make it long enough
            "image_description": "A beautiful garden",
            "audio_url": "https://example.com/audio.mp3",
            "status": StoryStatus.APPROVED,
            "language": Language.ENGLISH,
            "created_at": datetime.now()
        }
        
        story = Story(**story_data)
        assert story.id == "story-789"
        assert story.title == "The Magic Garden"
        assert story.status == StoryStatus.APPROVED
        assert story.language == Language.ENGLISH
    
    def test_story_model_validation_errors(self):
        """Test Story model validation errors."""
        base_data = {
            "id": "story-789",
            "kid_id": "kid-123",
            "created_at": datetime.now()
        }
        
        # Test title too long
        with pytest.raises(ValidationError):
            Story(
                **base_data,
                title="A" * 201,  # Too long
                content="Once upon a time" * 10
            )
        
        # Test content too long (over 2000 characters)
        with pytest.raises(ValidationError):
            Story(
                **base_data,
                title="Long Story",
                content="A" * 2001  # Over max length
            )
        
        # Test content too long
        with pytest.raises(ValidationError):
            Story(
                **base_data,
                title="Long Story",
                content="A" * 2001  # Too long
            )
    
    def test_enum_values(self):
        """Test enum value definitions."""
        # Test StoryStatus enum
        assert StoryStatus.PENDING == "pending"
        assert StoryStatus.PROCESSING == "processing"
        assert StoryStatus.APPROVED == "approved"
        assert StoryStatus.REJECTED == "rejected"
        assert StoryStatus.ERROR == "error"
        
        # Test Language enum
        assert Language.ENGLISH == "en"
        assert Language.RUSSIAN == "ru"
        assert Language.LATVIAN == "lv"
        assert Language.SPANISH == "es"
        
        # Test InputFormat enum
        assert InputFormat.IMAGE == "image"
        assert InputFormat.TEXT == "text"
        assert InputFormat.VOICE == "voice"


class TestRequestTypes:
    """Test request model types."""
    
    def test_generate_story_request_valid(self, sample_base64_image):
        """Test valid story generation request."""
        request_data = {
            "image_data": sample_base64_image,
            "kid_id": "kid-123",
            "language": Language.ENGLISH
        }
        
        request = GenerateStoryRequest(**request_data)
        assert request.kid_id == "kid-123"
        assert request.language == Language.ENGLISH
        assert request.image_data == sample_base64_image
    
    def test_generate_story_request_validation(self):
        """Test story generation request validation."""
        # Test invalid base64
        with pytest.raises(ValidationError, match="Invalid base64 image data"):
            GenerateStoryRequest(
                image_data="not_base64",
                kid_id="kid-123"
            )
    
    def test_create_kid_request_valid(self):
        """Test valid kid creation request."""
        request_data = {
            "name": "Alice",
            "age": 6,
            "gender": "girl",
            "avatar_type": "profile1",
            "user_id": "user-456",
            "appearance_method": "manual",
            "appearance_description": "Brown hair, green eyes",
            "favorite_genres": ["fantasy", "adventure"],
            "parent_notes": "Loves princess stories",
            "preferred_language": "en"
        }
        
        request = CreateKidRequest(**request_data)
        assert request.name == "Alice"
        assert request.age == 6
        assert request.gender == "girl"
        assert request.avatar_type == "profile1"
        assert request.appearance_method == "manual"
        assert request.appearance_description == "Brown hair, green eyes"
        assert request.favorite_genres == ["fantasy", "adventure"]
        assert request.parent_notes == "Loves princess stories"
        assert request.preferred_language == "en"
    
    def test_create_kid_request_validation(self):
        """Test kid creation request validation."""
        # Test name validation
        with pytest.raises(ValidationError):
            CreateKidRequest(
                name="",  # Empty name
                age=6,
                user_id="user-456"
            )
        
        # Test age validation
        with pytest.raises(ValidationError):
            CreateKidRequest(
                name="Alice",
                age=0,  # Invalid age
                user_id="user-456"
            )
    
    def test_update_kid_request_optional_fields(self):
        """Test update kid request with optional fields."""
        # All fields optional
        request = UpdateKidRequest()
        assert request.name is None
        assert request.age is None
        assert request.gender is None
        assert request.avatar_type is None
        
        # Partial update with gender
        request = UpdateKidRequest(name="Bob", age=7, gender="boy")
        assert request.name == "Bob"
        assert request.age == 7
        assert request.gender == "boy"
        assert request.avatar_type is None
        
        # Test appearance system fields
        request = UpdateKidRequest(
            appearance_method="photo",
            appearance_description="Updated appearance",
            favorite_genres=["adventure", "mystery"],
            parent_notes="Updated notes"
        )
        assert request.appearance_method == "photo"
        assert request.appearance_description == "Updated appearance"
        assert request.favorite_genres == ["adventure", "mystery"]
        assert request.parent_notes == "Updated notes"


class TestResponseTypes:
    """Test response model types."""
    
    def test_story_response_creation(self):
        """Test story response creation."""
        response_data = {
            "id": "story-789",
            "kid_id": "kid-123",
            "title": "The Magic Garden",
            "content": "Once upon a time...",
            "audio_url": "https://example.com/audio.mp3",
            "background_music_url": "https://example.com/music.mp3",
            "status": StoryStatus.APPROVED,
            "language": Language.ENGLISH,
            "created_at": datetime.now(),
            "updated_at": datetime.now()
        }
        
        response = StoryResponse(**response_data)
        assert response.id == "story-789"
        assert response.title == "The Magic Garden"
        assert response.status == StoryStatus.APPROVED
    
    def test_kid_response_creation(self):
        """Test kid response creation."""
        response_data = {
            "id": "kid-123",
            "user_id": "user-456",
            "name": "Alice",
            "age": 6,
            "gender": "girl",
            "avatar_type": "profile1",
            "appearance_method": "manual",
            "appearance_description": "Brown hair, green eyes",
            "favorite_genres": ["fantasy", "adventure"],
            "parent_notes": "Loves princess stories",
            "preferred_language": "en",
            "stories_count": 5,
            "created_at": datetime.now()
        }
        
        response = KidResponse(**response_data)
        assert response.id == "kid-123"
        assert response.name == "Alice"
        assert response.gender == "girl"
        assert response.appearance_description == "Brown hair, green eyes"
        assert response.stories_count == 5
    
    def test_health_response_creation(self):
        """Test health response creation."""
        # Test with defaults
        response = HealthResponse(version="2.0.0")
        assert response.status == "healthy"
        assert response.version == "2.0.0"
        assert isinstance(response.timestamp, datetime)
        assert response.services == {}
        
        # Test with custom data
        services = {"database": "connected", "ai": "ready"}
        response = HealthResponse(
            status="degraded",
            version="2.0.0",
            services=services
        )
        assert response.status == "degraded"
        assert response.services == services
    
    def test_response_serialization(self):
        """Test response model serialization."""
        response = StoryResponse(
            id="story-789",
            kid_id="kid-123",
            title="Test Story",
            content="Test content",
            audio_url=None,
            background_music_url=None,
            status=StoryStatus.PENDING,
            language=Language.ENGLISH,
            created_at=datetime(2024, 1, 1, 12, 0),
            updated_at=None
        )
        
        # Test model can be serialized to dict
        data = response.model_dump()
        assert data["id"] == "story-789"
        assert data["status"] == "pending"  # Enum value
        assert data["language"] == "en"  # Enum value
        
        # Test model can be serialized to JSON
        json_str = response.model_dump_json()
        assert "story-789" in json_str
        assert "pending" in json_str