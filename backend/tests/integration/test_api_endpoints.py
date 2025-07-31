"""Integration tests for API endpoints."""
import pytest
from unittest.mock import AsyncMock, patch
from httpx import AsyncClient
import base64
from src.types.domain import Kid, Story, StoryStatus, Language
from src.types.requests import CreateKidRequest, GenerateStoryRequest


class TestHealthEndpoints:
    """Test health check endpoints."""
    
    @pytest.mark.asyncio
    async def test_basic_health_check(self, test_client):
        """Test basic health check endpoint."""
        response = await test_client.get("/health")
        
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "healthy"
        assert data["version"] == "2.0.0"
        assert "timestamp" in data
    
    @pytest.mark.asyncio
    async def test_detailed_health_check(self, test_client, mock_supabase_service):
        """Test detailed health check endpoint."""
        # Mock successful health check
        mock_supabase_service.health_check.return_value = {
            "status": "healthy",
            "connected": True
        }
        
        with patch("src.api.routes.health.get_supabase_service", return_value=mock_supabase_service):
            response = await test_client.get("/health/detailed")
        
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "healthy"
        assert "services" in data
        assert "supabase" in data["services"]


class TestKidEndpoints:
    """Test kid profile management endpoints."""
    
    @pytest.mark.asyncio
    async def test_create_kid_success(self, test_client, mock_supabase_service, sample_kid_data):
        """Test successful kid profile creation."""
        # Setup mock
        kid = Kid(**sample_kid_data)
        mock_supabase_service.create_kid.return_value = kid
        mock_supabase_service.get_stories_for_kid.return_value = []
        
        request_data = {
            "name": "Alice",
            "age": 6,
            "avatar_type": "profile1",
            "user_id": "user-456"
        }
        
        with patch("src.api.routes.kids.get_supabase_service", return_value=mock_supabase_service):
            response = await test_client.post("/kids/", json=request_data)
        
        assert response.status_code == 200
        data = response.json()
        assert data["name"] == "Alice"
        assert data["age"] == 6
        assert data["stories_count"] == 0
        
        # Verify service was called correctly
        mock_supabase_service.create_kid.assert_called_once()
        call_args = mock_supabase_service.create_kid.call_args[0][0]
        assert isinstance(call_args, CreateKidRequest)
        assert call_args.name == "Alice"
    
    @pytest.mark.asyncio
    async def test_create_kid_validation_error(self, test_client):
        """Test kid creation with validation errors."""
        invalid_request_data = {
            "name": "",  # Empty name
            "age": 0,    # Invalid age
            "user_id": "user-456"
        }
        
        response = await test_client.post("/kids/", json=invalid_request_data)
        assert response.status_code == 400
        assert "error" in response.json()
    
    @pytest.mark.asyncio
    async def test_get_kid_success(self, test_client, mock_supabase_service, sample_kid_data):
        """Test successful kid profile retrieval."""
        # Setup mock
        kid = Kid(**sample_kid_data)
        mock_supabase_service.get_kid.return_value = kid
        mock_supabase_service.get_stories_for_kid.return_value = []
        
        with patch("src.api.routes.kids.get_supabase_service", return_value=mock_supabase_service):
            response = await test_client.get("/kids/kid-123")
        
        assert response.status_code == 200
        data = response.json()
        assert data["id"] == "kid-123"
        assert data["name"] == "Alice"
        
        mock_supabase_service.get_kid.assert_called_once_with("kid-123")
    
    @pytest.mark.asyncio
    async def test_get_kid_not_found(self, test_client, mock_supabase_service):
        """Test kid profile not found."""
        mock_supabase_service.get_kid.return_value = None
        
        with patch("src.api.routes.kids.get_supabase_service", return_value=mock_supabase_service):
            response = await test_client.get("/kids/nonexistent")
        
        assert response.status_code == 404
        assert "not found" in response.json()["detail"]
    
    @pytest.mark.asyncio
    async def test_get_kids_for_user(self, test_client, mock_supabase_service, sample_kid_data):
        """Test getting all kids for a user."""
        # Setup mock
        kid = Kid(**sample_kid_data)
        mock_supabase_service.get_kids_for_user.return_value = [kid]
        mock_supabase_service.get_stories_for_kid.return_value = []
        
        with patch("src.api.routes.kids.get_supabase_service", return_value=mock_supabase_service):
            response = await test_client.get("/kids/user/user-456")
        
        assert response.status_code == 200
        data = response.json()
        assert data["total"] == 1
        assert len(data["kids"]) == 1
        assert data["kids"][0]["name"] == "Alice"
    
    @pytest.mark.asyncio
    async def test_update_kid_success(self, test_client, mock_supabase_service, sample_kid_data):
        """Test successful kid profile update."""
        # Setup mock
        updated_data = sample_kid_data.copy()
        updated_data["name"] = "Bob"
        updated_kid = Kid(**updated_data)
        
        mock_supabase_service.update_kid.return_value = updated_kid
        mock_supabase_service.get_stories_for_kid.return_value = []
        
        update_request = {"name": "Bob", "age": 7}
        
        with patch("src.api.routes.kids.get_supabase_service", return_value=mock_supabase_service):
            response = await test_client.put("/kids/kid-123", json=update_request)
        
        assert response.status_code == 200
        data = response.json()
        assert data["name"] == "Bob"


class TestStoryEndpoints:
    """Test story management endpoints."""
    
    @pytest.mark.asyncio
    async def test_generate_story_success(self, test_client, mock_supabase_service, sample_kid_data, sample_story_data, sample_base64_image):
        """Test successful story generation."""
        # Setup mocks
        kid = Kid(**sample_kid_data)
        story = Story(**sample_story_data)
        
        mock_supabase_service.get_kid.return_value = kid
        mock_supabase_service.create_story.return_value = story
        
        request_data = {
            "image_data": sample_base64_image,
            "kid_id": "kid-123",
            "language": "en"
        }
        
        with patch("src.api.routes.stories.get_supabase_service", return_value=mock_supabase_service):
            with patch("src.api.routes.stories.get_story_processor") as mock_processor:
                response = await test_client.post("/stories/generate", json=request_data)
        
        assert response.status_code == 200
        data = response.json()
        assert data["story_id"] == "story-789"
        assert data["status"] == "processing"
        
        # Verify story creation was called
        mock_supabase_service.create_story.assert_called_once()
    
    @pytest.mark.asyncio
    async def test_generate_story_kid_not_found(self, test_client, mock_supabase_service, sample_base64_image):
        """Test story generation with non-existent kid."""
        mock_supabase_service.get_kid.return_value = None
        
        request_data = {
            "image_data": sample_base64_image,
            "kid_id": "nonexistent",
            "language": "en"
        }
        
        with patch("src.api.routes.stories.get_supabase_service", return_value=mock_supabase_service):
            response = await test_client.post("/stories/generate", json=request_data)
        
        assert response.status_code == 400
        assert "not found" in response.json()["detail"]
    
    @pytest.mark.asyncio
    async def test_generate_story_invalid_image(self, test_client):
        """Test story generation with invalid image data."""
        request_data = {
            "image_data": "invalid_base64",
            "kid_id": "kid-123",
            "language": "en"
        }
        
        response = await test_client.post("/stories/generate", json=request_data)
        assert response.status_code == 400
        assert "error" in response.json()
    
    @pytest.mark.asyncio
    async def test_get_story_success(self, test_client, mock_supabase_service, sample_story_data):
        """Test successful story retrieval."""
        # Setup mock
        story = Story(**sample_story_data)
        mock_supabase_service.get_story.return_value = story
        
        with patch("src.api.routes.stories.get_supabase_service", return_value=mock_supabase_service):
            response = await test_client.get("/stories/story-789")
        
        assert response.status_code == 200
        data = response.json()
        assert data["id"] == "story-789"
        assert data["title"] == "The Magic Garden"
        assert data["status"] == "approved"
    
    @pytest.mark.asyncio
    async def test_get_story_not_found(self, test_client, mock_supabase_service):
        """Test story not found."""
        mock_supabase_service.get_story.return_value = None
        
        with patch("src.api.routes.stories.get_supabase_service", return_value=mock_supabase_service):
            response = await test_client.get("/stories/nonexistent")
        
        assert response.status_code == 404
        assert "not found" in response.json()["detail"]
    
    @pytest.mark.asyncio
    async def test_get_stories_for_kid(self, test_client, mock_supabase_service, sample_story_data):
        """Test getting all stories for a kid."""
        # Setup mock
        story = Story(**sample_story_data)
        mock_supabase_service.get_stories_for_kid.return_value = [story]
        
        with patch("src.api.routes.stories.get_supabase_service", return_value=mock_supabase_service):
            response = await test_client.get("/stories/kid/kid-123")
        
        assert response.status_code == 200
        data = response.json()
        assert data["total"] >= 1
        assert len(data["stories"]) == 1
        assert data["stories"][0]["title"] == "The Magic Garden"
    
    @pytest.mark.asyncio
    async def test_get_stories_pagination(self, test_client, mock_supabase_service, sample_story_data):
        """Test story pagination parameters."""
        # Setup mock
        story = Story(**sample_story_data)
        mock_supabase_service.get_stories_for_kid.return_value = [story]
        
        with patch("src.api.routes.stories.get_supabase_service", return_value=mock_supabase_service):
            response = await test_client.get("/stories/kid/kid-123?page=2&page_size=10")
        
        assert response.status_code == 200
        data = response.json()
        assert data["page"] == 2
        assert data["page_size"] == 10
        
        # Verify pagination was passed to service
        mock_supabase_service.get_stories_for_kid.assert_called_once_with(
            "kid-123", limit=10, offset=10
        )
    
    @pytest.mark.asyncio
    async def test_review_story_success(self, test_client, mock_supabase_service, sample_story_data):
        """Test successful story review/update."""
        # Setup mock
        updated_data = sample_story_data.copy()
        updated_data["title"] = "Updated Title"
        updated_story = Story(**updated_data)
        
        mock_supabase_service.update_story.return_value = updated_story
        
        review_data = {"title": "Updated Title", "status": "approved"}
        
        with patch("src.api.routes.stories.get_supabase_service", return_value=mock_supabase_service):
            response = await test_client.put("/stories/story-789/review", json=review_data)
        
        assert response.status_code == 200
        data = response.json()
        assert data["title"] == "Updated Title"
        
        # Verify update was called
        mock_supabase_service.update_story.assert_called_once()


class TestLegacyEndpoints:
    """Test legacy endpoint compatibility."""
    
    @pytest.mark.asyncio
    async def test_legacy_generate_story_endpoint(self, test_client, mock_supabase_service, sample_kid_data, sample_story_data, sample_base64_image):
        """Test legacy story generation endpoint maintains compatibility."""
        # Setup mocks
        kid = Kid(**sample_kid_data)
        story = Story(**sample_story_data)
        
        mock_supabase_service.get_kid.return_value = kid
        mock_supabase_service.create_story.return_value = story
        
        request_data = {
            "image_data": sample_base64_image,
            "kid_id": "kid-123",
            "language": "en"
        }
        
        with patch("src.api.app.get_supabase_service", return_value=mock_supabase_service):
            with patch("src.api.app.get_story_processor") as mock_processor:
                response = await test_client.post("/generate-story-from-image/", json=request_data)
        
        assert response.status_code == 200
        data = response.json()
        assert data["story_id"] == "story-789"
        assert data["status"] == "processing"
    
    @pytest.mark.asyncio
    async def test_legacy_get_story_endpoint(self, test_client, mock_supabase_service, sample_story_data):
        """Test legacy story retrieval endpoint maintains compatibility."""
        # Setup mock
        story = Story(**sample_story_data)
        mock_supabase_service.get_story.return_value = story
        
        with patch("src.api.app.get_supabase_service", return_value=mock_supabase_service):
            response = await test_client.get("/story/story-789")
        
        assert response.status_code == 200
        data = response.json()
        assert data["id"] == "story-789"
        assert data["title"] == "The Magic Garden"
        # Check legacy format includes ISO timestamps
        assert "created_at" in data
        assert "updated_at" in data
    
    @pytest.mark.asyncio
    async def test_legacy_get_user_kids_endpoint(self, test_client, mock_supabase_service, sample_kid_data):
        """Test legacy user kids endpoint maintains compatibility."""
        # Setup mock
        kid = Kid(**sample_kid_data)
        mock_supabase_service.get_kids_for_user.return_value = [kid]
        
        with patch("src.api.app.get_supabase_service", return_value=mock_supabase_service):
            response = await test_client.get("/users/user-456/kids")
        
        assert response.status_code == 200
        data = response.json()
        assert data["total"] == 1
        assert len(data["kids"]) == 1
        assert data["kids"][0]["name"] == "Alice"
        # Check legacy format includes ISO timestamps
        assert "created_at" in data["kids"][0]