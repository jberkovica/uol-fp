"""
Integration tests for API endpoints
"""

import pytest
from fastapi.testclient import TestClient
from app.main import app


@pytest.fixture
def client():
    """Create test client for FastAPI app"""
    return TestClient(app)


class TestRootEndpoint:
    """Test root API endpoint"""
    
    def test_root_endpoint_returns_info(self, client):
        """Test that root endpoint returns application info"""
        response = client.get("/")
        
        assert response.status_code == 200
        data = response.json()
        
        # Check required fields
        assert "message" in data
        assert "status" in data
        assert "version" in data
        assert "ai_services" in data
        assert "features" in data
        
        # Check AI services are listed
        ai_services = data["ai_services"]
        assert "image_analysis" in ai_services
        assert "story_generation" in ai_services
        assert "text_to_speech" in ai_services
        
        # Check version format
        assert isinstance(data["version"], str)
        assert data["status"] == "active"


class TestStoryGenerationEndpoint:
    """Test story generation API endpoint"""
    
    def test_story_generation_requires_valid_input(self, client, mock_api_keys):
        """Test that story generation validates input"""
        # Test with missing fields
        response = client.post("/generate-story-from-image/", json={})
        assert response.status_code == 422  # Validation error
        
        # Test with invalid child name
        invalid_request = {
            "child_name": "<script>alert('xss')</script>",
            "image_data": "invalid_base64",
            "mime_type": "image/jpeg"
        }
        response = client.post("/generate-story-from-image/", json=invalid_request)
        assert response.status_code == 400  # Our validation should catch this
    
    def test_story_generation_with_valid_input_structure(self, client, valid_story_request, mock_api_keys):
        """Test story generation endpoint accepts properly structured input"""
        # Note: This will fail due to image size validation or missing AI APIs
        # but we can test that the endpoint accepts the request structure
        response = client.post("/generate-story-from-image/", json=valid_story_request)
        
        # Should either succeed (200) or fail due to validation/AI issues (400/500)
        # but not due to malformed request (422)
        assert response.status_code in [200, 400, 500]
        
        if response.status_code == 400:
            # If it's a validation error, should be about image size
            error_detail = response.json().get("detail", "")
            assert "image" in error_detail.lower() or "validation" in error_detail.lower()


class TestLegacyEndpoints:
    """Test legacy API endpoints for backward compatibility"""
    
    def test_upload_image_endpoint_exists(self, client):
        """Test that legacy upload-image endpoint exists"""
        # This endpoint requires form data, so we expect a 422 for JSON
        response = client.post("/upload-image/", json={})
        
        # Should return validation error for wrong content type, not 404
        assert response.status_code != 404
    
    def test_story_endpoints_exist(self, client):
        """Test that story retrieval endpoints exist"""
        # Test story detail endpoint (should return 404 for non-existent story)
        response = client.get("/story/nonexistent-id")
        assert response.status_code in [404, 422]  # Not found or validation error
        
        # Test stories list endpoint
        response = client.get("/stories/")
        assert response.status_code in [200, 422]  # Should exist


class TestCORSHeaders:
    """Test CORS configuration"""
    
    def test_cors_headers_present(self, client):
        """Test that CORS headers are present in responses"""
        response = client.get("/")
        
        # Should have CORS headers (currently configured to allow all)
        assert "access-control-allow-origin" in response.headers
        
        # For development, should allow all origins
        assert response.headers["access-control-allow-origin"] == "*"
    
    def test_options_request_handled(self, client):
        """Test that OPTIONS requests are handled for CORS preflight"""
        response = client.options("/generate-story-from-image/")
        
        # Should handle OPTIONS request
        assert response.status_code in [200, 204]


class TestErrorHandling:
    """Test API error handling"""
    
    def test_404_for_nonexistent_endpoint(self, client):
        """Test that nonexistent endpoints return 404"""
        response = client.get("/nonexistent-endpoint")
        assert response.status_code == 404
    
    def test_405_for_wrong_method(self, client):
        """Test that wrong HTTP methods return 405"""
        # Try to POST to GET-only endpoint
        response = client.post("/")
        assert response.status_code == 405
    
    def test_error_response_format(self, client):
        """Test that error responses have consistent format"""
        response = client.get("/nonexistent-endpoint")
        
        assert response.status_code == 404
        error_data = response.json()
        
        # FastAPI should return standard error format
        assert "detail" in error_data