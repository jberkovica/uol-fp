"""
Input validation utilities for Mira Storyteller API
"""

import base64
import io
import logging
from typing import Tuple, Optional
from PIL import Image
from fastapi import HTTPException

logger = logging.getLogger(__name__)

# Configuration constants
MAX_IMAGE_SIZE_MB = 10
MAX_IMAGE_DIMENSION = 4096
MIN_IMAGE_DIMENSION = 32
ALLOWED_MIME_TYPES = {
    "image/jpeg", "image/jpg", "image/png", "image/webp", "image/gif"
}
ALLOWED_EXTENSIONS = {".jpg", ".jpeg", ".png", ".webp", ".gif"}

class ValidationError(Exception):
    """Custom validation error"""
    pass

def validate_base64_image(base64_data: str, mime_type: str) -> Tuple[bool, Optional[str]]:
    """
    Validate base64 encoded image data
    
    Args:
        base64_data: Base64 encoded image string
        mime_type: MIME type of the image
        
    Returns:
        Tuple of (is_valid, error_message)
    """
    try:
        # Check MIME type
        if mime_type.lower() not in ALLOWED_MIME_TYPES:
            return False, f"Invalid MIME type. Allowed types: {', '.join(ALLOWED_MIME_TYPES)}"
        
        # Validate base64 format
        if not base64_data:
            return False, "Empty image data"
        
        # Remove data URL prefix if present
        if ',' in base64_data:
            base64_data = base64_data.split(',', 1)[1]
        
        # Check if it's valid base64
        try:
            image_bytes = base64.b64decode(base64_data, validate=True)
        except Exception as e:
            return False, f"Invalid base64 encoding: {str(e)}"
        
        # Check file size
        size_mb = len(image_bytes) / (1024 * 1024)
        if size_mb > MAX_IMAGE_SIZE_MB:
            return False, f"Image too large. Maximum size: {MAX_IMAGE_SIZE_MB}MB, got: {size_mb:.2f}MB"
        
        # Validate image content
        try:
            image = Image.open(io.BytesIO(image_bytes))
            
            # Check image dimensions
            width, height = image.size
            if width < MIN_IMAGE_DIMENSION or height < MIN_IMAGE_DIMENSION:
                return False, f"Image too small. Minimum dimensions: {MIN_IMAGE_DIMENSION}x{MIN_IMAGE_DIMENSION}px"
            
            if width > MAX_IMAGE_DIMENSION or height > MAX_IMAGE_DIMENSION:
                return False, f"Image too large. Maximum dimensions: {MAX_IMAGE_DIMENSION}x{MAX_IMAGE_DIMENSION}px"
            
            # Verify image format matches MIME type
            image_format = image.format
            if image_format:
                expected_formats = {
                    "image/jpeg": ["JPEG"],
                    "image/jpg": ["JPEG"],
                    "image/png": ["PNG"],
                    "image/webp": ["WEBP"],
                    "image/gif": ["GIF"]
                }
                
                if image_format not in expected_formats.get(mime_type.lower(), []):
                    return False, f"Image format {image_format} doesn't match MIME type {mime_type}"
            
            # Additional security checks
            if hasattr(image, 'verify'):
                image.verify()  # This will raise an exception if the image is corrupted
            
            logger.info(f"Image validation passed: {width}x{height}px, {size_mb:.2f}MB, format: {image_format}")
            return True, None
            
        except Exception as e:
            return False, f"Invalid image content: {str(e)}"
        
    except Exception as e:
        logger.error(f"Unexpected error in image validation: {str(e)}")
        return False, f"Validation error: {str(e)}"

def validate_child_name(name: str) -> Tuple[bool, Optional[str]]:
    """
    Validate child name input
    
    Args:
        name: Child's name
        
    Returns:
        Tuple of (is_valid, error_message)
    """
    if not name or not name.strip():
        return False, "Child name is required"
    
    name = name.strip()
    
    # Length check
    if len(name) < 1:
        return False, "Child name cannot be empty"
    
    if len(name) > 50:
        return False, "Child name too long (maximum 50 characters)"
    
    # Character validation (letters, spaces, hyphens, apostrophes)
    import re
    if not re.match(r"^[a-zA-Z\s\-']+$", name):
        return False, "Child name can only contain letters, spaces, hyphens, and apostrophes"
    
    # Check for suspicious patterns
    suspicious_patterns = [
        r'<[^>]*>',  # HTML tags
        r'javascript:',  # JavaScript
        r'data:',  # Data URLs
        r'vbscript:',  # VBScript
        r'onload=',  # Event handlers
        r'onerror=',
    ]
    
    name_lower = name.lower()
    for pattern in suspicious_patterns:
        if re.search(pattern, name_lower):
            return False, "Child name contains invalid characters"
    
    return True, None

def validate_story_request(story_request) -> None:
    """
    Validate complete story request
    
    Args:
        story_request: StoryRequest object
        
    Raises:
        HTTPException: If validation fails
    """
    # Validate child name
    name_valid, name_error = validate_child_name(story_request.child_name)
    if not name_valid:
        raise HTTPException(status_code=400, detail=f"Invalid child name: {name_error}")
    
    # Validate image
    image_valid, image_error = validate_base64_image(story_request.image_data, story_request.mime_type)
    if not image_valid:
        raise HTTPException(status_code=400, detail=f"Invalid image: {image_error}")
    
    # Validate preferences if provided
    if story_request.preferences:
        if not isinstance(story_request.preferences, dict):
            raise HTTPException(status_code=400, detail="Preferences must be a dictionary")
        
        # Check for reasonable preference values
        allowed_keys = {"length", "style", "age_group", "theme"}
        for key in story_request.preferences.keys():
            if key not in allowed_keys:
                raise HTTPException(status_code=400, detail=f"Invalid preference key: {key}")
    
    logger.info(f"Story request validation passed for child: {story_request.child_name}")

def sanitize_filename(filename: str) -> str:
    """
    Sanitize filename for safe storage
    
    Args:
        filename: Original filename
        
    Returns:
        Sanitized filename
    """
    import re
    # Remove any characters that aren't alphanumeric, dots, dashes, or underscores
    sanitized = re.sub(r'[^a-zA-Z0-9.\-_]', '', filename)
    
    # Limit length
    if len(sanitized) > 100:
        sanitized = sanitized[:100]
    
    return sanitized or "unnamed_file"