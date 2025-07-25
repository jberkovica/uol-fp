"""Unit tests for input validators."""
import pytest
import base64
from PIL import Image
import io
from src.core.validators import (
    validate_base64_image,
    validate_kid_name,
    validate_age,
    validate_uuid,
    validate_story_content,
    sanitize_filename
)
from src.core.exceptions import ValidationError


class TestImageValidation:
    """Test image validation functions."""
    
    def test_valid_base64_image(self, sample_base64_image):
        """Test validation of valid base64 image."""
        # Should not raise any exception
        validate_base64_image(sample_base64_image)
    
    def test_invalid_base64_data(self):
        """Test validation of invalid base64 data."""
        with pytest.raises(ValidationError, match="Invalid image data"):
            validate_base64_image("not_base64_data")
    
    def test_oversized_image(self):
        """Test validation of oversized image."""
        # Create a fake large image data (simulate by checking length)
        large_data = "a" * (15 * 1024 * 1024)  # 15MB of data
        encoded = base64.b64encode(large_data.encode()).decode()
        
        with pytest.raises(ValidationError, match="Image size.*exceeds maximum"):
            validate_base64_image(encoded, max_size_mb=10.0)
    
    def test_data_url_prefix_removal(self):
        """Test that data URL prefixes are properly removed."""
        # Create valid image with data URL prefix
        valid_b64 = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg=="
        data_url = f"data:image/png;base64,{valid_b64}"
        
        # Should not raise exception
        validate_base64_image(data_url)
    
    def test_image_format_validation(self):
        """Test validation of different image formats."""
        # Create a small test image in memory
        img = Image.new('RGB', (10, 10), color='red')
        
        # Test PNG (should pass)
        png_buffer = io.BytesIO()
        img.save(png_buffer, format='PNG')
        png_b64 = base64.b64encode(png_buffer.getvalue()).decode()
        validate_base64_image(png_b64)
        
        # Test JPEG (should pass)
        jpeg_buffer = io.BytesIO()
        img.save(jpeg_buffer, format='JPEG')
        jpeg_b64 = base64.b64encode(jpeg_buffer.getvalue()).decode()
        validate_base64_image(jpeg_b64)
    
    def test_image_dimensions_validation(self):
        """Test validation of image dimensions."""
        # Create an image that's too large
        img = Image.new('RGB', (5000, 5000), color='red')
        buffer = io.BytesIO()
        img.save(buffer, format='PNG')
        large_img_b64 = base64.b64encode(buffer.getvalue()).decode()
        
        with pytest.raises(ValidationError, match="Image dimensions.*exceed maximum"):
            validate_base64_image(large_img_b64)


class TestKidValidation:
    """Test kid profile validation functions."""
    
    def test_valid_kid_name(self):
        """Test validation of valid kid names."""
        valid_names = ["Alice", "Bob Smith", "Mary-Jane", "O'Connor", "Jean-Luc"]
        for name in valid_names:
            validate_kid_name(name)  # Should not raise
    
    def test_invalid_kid_names(self):
        """Test validation of invalid kid names."""
        invalid_cases = [
            ("", "Name cannot be empty"),
            ("   ", "Name cannot be empty"),
            ("A" * 51, "Name cannot exceed 50 characters"),
            ("Alice123", "Name can only contain letters"),
            ("Alice@Home", "Name can only contain letters"),
            ("<script>", "Name can only contain letters")
        ]
        
        for invalid_name, expected_error in invalid_cases:
            with pytest.raises(ValidationError, match=expected_error):
                validate_kid_name(invalid_name)
    
    def test_valid_ages(self):
        """Test validation of valid ages."""
        valid_ages = [1, 5, 10, 15, 18]
        for age in valid_ages:
            validate_age(age)  # Should not raise
    
    def test_invalid_ages(self):
        """Test validation of invalid ages."""
        invalid_cases = [
            (0, "Age must be between 1 and 18"),
            (-1, "Age must be between 1 and 18"),
            (19, "Age must be between 1 and 18"),
            (100, "Age must be between 1 and 18"),
            ("5", "Age must be a number"),
            (5.5, "Age must be a number")
        ]
        
        for invalid_age, expected_error in invalid_cases:
            with pytest.raises(ValidationError, match=expected_error):
                validate_age(invalid_age)


class TestUUIDValidation:
    """Test UUID validation functions."""
    
    def test_valid_uuids(self):
        """Test validation of valid UUIDs."""
        valid_uuids = [
            "123e4567-e89b-12d3-a456-426614174000",
            "550e8400-e29b-41d4-a716-446655440000",
            "6ba7b810-9dad-11d1-80b4-00c04fd430c8"
        ]
        
        for uuid_str in valid_uuids:
            validate_uuid(uuid_str)  # Should not raise
    
    def test_invalid_uuids(self):
        """Test validation of invalid UUIDs."""
        invalid_uuids = [
            "not-a-uuid",
            "123e4567-e89b-12d3-a456",  # Too short
            "123e4567-e89b-12d3-a456-426614174000-extra",  # Too long
            "123e4567-e89b-12d3-a456-42661417400g",  # Invalid character
            "",
            "123e4567_e89b_12d3_a456_426614174000"  # Wrong separators
        ]
        
        for invalid_uuid in invalid_uuids:
            with pytest.raises(ValidationError, match="Invalid.*format"):
                validate_uuid(invalid_uuid)


class TestStoryContentValidation:
    """Test story content validation functions."""
    
    def test_valid_story_content(self):
        """Test validation of valid story content."""
        valid_content = "Once upon a time, there was a brave little mouse who lived in a cozy burrow under the old oak tree. Every day, the mouse would venture out to explore the wonderful world around him, meeting new friends and discovering amazing adventures that filled his heart with joy and wonder."
        
        validate_story_content(valid_content)  # Should not raise
    
    def test_empty_story_content(self):
        """Test validation of empty story content."""
        empty_cases = ["", "   ", "\n\n", "\t\t"]
        
        for empty_content in empty_cases:
            with pytest.raises(ValidationError, match="Story content cannot be empty"):
                validate_story_content(empty_content)
    
    def test_too_short_story(self):
        """Test validation of too short story content."""
        short_story = "A cat sat on a mat."  # Less than 50 words
        
        with pytest.raises(ValidationError, match="Story too short.*Minimum 50 words"):
            validate_story_content(short_story)
    
    def test_too_long_story(self):
        """Test validation of too long story content."""
        # Create a story with more than 500 words
        long_story = " ".join(["word"] * 501)
        
        with pytest.raises(ValidationError, match="Story too long.*Maximum 500 words"):
            validate_story_content(long_story)


class TestFilenameValidation:
    """Test filename sanitization functions."""
    
    def test_safe_filename_sanitization(self):
        """Test sanitization of safe filenames."""
        safe_cases = [
            ("story123.mp3", "story123.mp3"),
            ("my-story.mp3", "my-story.mp3"),
            ("story_v2.mp3", "story_v2.mp3")
        ]
        
        for input_name, expected in safe_cases:
            result = sanitize_filename(input_name)
            assert result == expected
    
    def test_unsafe_filename_sanitization(self):
        """Test sanitization of unsafe filenames."""
        unsafe_cases = [
            ("story with spaces.mp3", "story_with_spaces.mp3"),
            ("story/with/path.mp3", "story_with_path.mp3"),
            ("story\\with\\backslash.mp3", "story_with_backslash.mp3"),
            ("story@#$%.mp3", "story____.mp3"),
            ("story", "story.mp3"),  # No extension
            ("../../../etc/passwd", "________etc_passwd.mp3")  # Path traversal attempt
        ]
        
        for input_name, expected in unsafe_cases:
            result = sanitize_filename(input_name)
            assert result == expected
    
    def test_filename_extension_handling(self):
        """Test filename extension handling."""
        no_extension_cases = [
            ("story", "story.mp3"),
            ("my_story_final", "my_story_final.mp3")
        ]
        
        for input_name, expected in no_extension_cases:
            result = sanitize_filename(input_name)
            assert result == expected