"""Input validation utilities."""
import base64
import re
from typing import Optional
from PIL import Image
import io

from .exceptions import ValidationError


def validate_base64_image(image_data: str, max_size_mb: float = 10.0) -> None:
    """
    Validate base64 encoded image data.
    
    Args:
        image_data: Base64 encoded image string
        max_size_mb: Maximum allowed file size in MB
        
    Raises:
        ValidationError: If validation fails
    """
    try:
        # Remove data URL prefix if present
        if "," in image_data:
            image_data = image_data.split(",")[1]
            
        # Decode base64
        image_bytes = base64.b64decode(image_data)
        
        # Check size
        size_mb = len(image_bytes) / (1024 * 1024)
        if size_mb > max_size_mb:
            raise ValidationError(f"Image size {size_mb:.1f}MB exceeds maximum {max_size_mb}MB")
        
        # Validate it's a valid image
        image = Image.open(io.BytesIO(image_bytes))
        
        # Check image format
        allowed_formats = ["JPEG", "PNG", "GIF", "WEBP"]
        if image.format not in allowed_formats:
            raise ValidationError(f"Image format {image.format} not allowed. Use: {', '.join(allowed_formats)}")
        
        # Check dimensions
        max_dimension = 4096
        if image.width > max_dimension or image.height > max_dimension:
            raise ValidationError(f"Image dimensions {image.width}x{image.height} exceed maximum {max_dimension}x{max_dimension}")
            
    except Exception as e:
        if isinstance(e, ValidationError):
            raise
        raise ValidationError(f"Invalid image data: {str(e)}")


def validate_kid_name(name: str) -> None:
    """
    Validate kid profile name.
    
    Args:
        name: Kid's name
        
    Raises:
        ValidationError: If validation fails
    """
    if not name or not name.strip():
        raise ValidationError("Name cannot be empty")
        
    if len(name) > 50:
        raise ValidationError("Name cannot exceed 50 characters")
        
    # Allow letters, spaces, hyphens, and apostrophes
    if not re.match(r"^[a-zA-Z\s\-']+$", name):
        raise ValidationError("Name can only contain letters, spaces, hyphens, and apostrophes")


def validate_age(age: int) -> None:
    """
    Validate kid's age.
    
    Args:
        age: Kid's age
        
    Raises:
        ValidationError: If validation fails
    """
    if not isinstance(age, int):
        raise ValidationError("Age must be a number")
        
    if age < 1 or age > 18:
        raise ValidationError("Age must be between 1 and 18")


def validate_uuid(uuid_string: str, field_name: str = "ID") -> None:
    """
    Validate UUID format.
    
    Args:
        uuid_string: UUID string to validate
        field_name: Name of the field for error messages
        
    Raises:
        ValidationError: If validation fails
    """
    uuid_pattern = re.compile(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
        re.IGNORECASE
    )
    
    if not uuid_pattern.match(uuid_string):
        raise ValidationError(f"Invalid {field_name} format")


def validate_story_content(content: str) -> None:
    """
    Validate story content.
    
    Args:
        content: Story text content
        
    Raises:
        ValidationError: If validation fails
    """
    if not content or not content.strip():
        raise ValidationError("Story content cannot be empty")
        
    word_count = len(content.split())
    if word_count < 50:
        raise ValidationError(f"Story too short ({word_count} words). Minimum 50 words required")
        
    if word_count > 500:
        raise ValidationError(f"Story too long ({word_count} words). Maximum 500 words allowed")


def sanitize_filename(filename: str) -> str:
    """
    Sanitize filename for safe storage.
    
    Args:
        filename: Original filename
        
    Returns:
        Sanitized filename
    """
    # Remove any path components
    filename = filename.split("/")[-1].split("\\")[-1]
    
    # Replace spaces and special characters
    filename = re.sub(r'[^\w\-_\.]', '_', filename)
    
    # Ensure it has an extension
    if "." not in filename:
        filename += ".mp3"
        
    return filename