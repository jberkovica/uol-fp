"""
Unit tests for validation utilities
"""

import pytest
from app.utils.validation import (
    validate_base64_image,
    validate_child_name,
    validate_story_request,
    sanitize_filename,
    ValidationError
)
from fastapi import HTTPException


class TestChildNameValidation:
    """Test child name validation"""
    
    def test_valid_child_names(self):
        """Test that valid child names pass validation"""
        valid_names = ["Emma", "John-Paul", "Mary O'Connor", "Ana Maria"]
        
        for name in valid_names:
            valid, error = validate_child_name(name)
            assert valid is True
            assert error is None
    
    def test_invalid_child_names(self):
        """Test that invalid child names are rejected"""
        invalid_names = [
            "",  # Empty
            "   ",  # Whitespace only
            "a" * 51,  # Too long
            "<script>alert('xss')</script>",  # XSS attempt
            "test@email.com",  # Invalid characters
            "javascript:alert(1)",  # Script injection
            "onload=alert(1)",  # Event handler
        ]
        
        for name in invalid_names:
            valid, error = validate_child_name(name)
            assert valid is False
            assert error is not None
            assert isinstance(error, str)
    
    def test_child_name_trimming(self):
        """Test that child names are properly trimmed"""
        valid, error = validate_child_name("  Emma  ")
        assert valid is True
        assert error is None


class TestBase64ImageValidation:
    """Test base64 image validation"""
    
    def test_valid_small_image(self, sample_base64_image):
        """Test validation with valid small image"""
        # Note: This will fail because our test image is too small
        # This is expected behavior - images must be at least 32x32px
        valid, error = validate_base64_image(sample_base64_image, "image/png")
        assert valid is False  # Should fail due to size
        assert "too small" in error.lower()
    
    def test_invalid_base64(self):
        """Test validation with invalid base64 data"""
        valid, error = validate_base64_image("invalid_base64", "image/png")
        assert valid is False
        assert "base64" in error.lower()
    
    def test_invalid_mime_type(self, sample_base64_image):
        """Test validation with invalid MIME type"""
        valid, error = validate_base64_image(sample_base64_image, "application/pdf")
        assert valid is False
        assert "mime type" in error.lower()
    
    def test_empty_image_data(self):
        """Test validation with empty image data"""
        valid, error = validate_base64_image("", "image/png")
        assert valid is False
        assert "empty" in error.lower()
    
    def test_data_url_prefix_removal(self):
        """Test that data URL prefixes are properly removed"""
        data_url = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChAHAkb+xOQAAAABJRU5ErkJggg=="
        valid, error = validate_base64_image(data_url, "image/png")
        # Will still fail due to size, but should not fail due to data URL prefix
        assert "base64" not in error.lower()


class TestStoryRequestValidation:
    """Test story request validation"""
    
    def test_valid_story_request(self, valid_story_request, mock_api_keys):
        """Test validation with valid story request"""
        # This will fail due to image size, but we can test the structure
        with pytest.raises(HTTPException) as exc_info:
            validate_story_request(type('StoryRequest', (), valid_story_request)())
        
        # Should fail on image validation, not on structure
        assert exc_info.value.status_code == 400
        assert "image" in str(exc_info.value.detail).lower()
    
    def test_invalid_child_name_in_request(self, invalid_story_request, mock_api_keys):
        """Test validation rejects malicious child names"""
        with pytest.raises(HTTPException) as exc_info:
            validate_story_request(type('StoryRequest', (), invalid_story_request)())
        
        assert exc_info.value.status_code == 400
        assert "child name" in str(exc_info.value.detail).lower()
    
    def test_invalid_preferences_type(self, valid_story_request, mock_api_keys):
        """Test validation rejects invalid preferences type"""
        request_data = valid_story_request.copy()
        request_data["preferences"] = "invalid_string"  # Should be dict
        
        with pytest.raises(HTTPException) as exc_info:
            validate_story_request(type('StoryRequest', (), request_data)())
        
        assert exc_info.value.status_code == 400
        assert "preferences" in str(exc_info.value.detail).lower()


class TestFilenamesanitization:
    """Test filename sanitization"""
    
    def test_valid_filename(self):
        """Test that valid filenames are preserved"""
        clean_name = sanitize_filename("story_123.mp3")
        assert clean_name == "story_123.mp3"
    
    def test_invalid_characters_removed(self):
        """Test that invalid characters are removed"""
        dirty_name = "story<>:\"/\\|?*.mp3"
        clean_name = sanitize_filename(dirty_name)
        assert clean_name == "story.mp3"
    
    def test_long_filename_truncated(self):
        """Test that long filenames are truncated"""
        long_name = "a" * 200 + ".mp3"
        clean_name = sanitize_filename(long_name)
        assert len(clean_name) <= 100
    
    def test_empty_filename_handled(self):
        """Test that empty filenames get a default name"""
        clean_name = sanitize_filename("")
        assert clean_name == "unnamed_file"
        
        clean_name = sanitize_filename("!@#$%^&*()")
        assert clean_name == "unnamed_file"