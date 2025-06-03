"""
Utility functions for image handling, processing, and display.
"""
import os
import base64
import logging
from PIL import Image
import matplotlib.pyplot as plt
import io

logger = logging.getLogger(__name__)

def load_image_bytes(image_path):
    """Load an image file as bytes."""
    try:
        with open(image_path, "rb") as image_file:
            return image_file.read()
    except Exception as e:
        logger.error(f"Error loading image from {image_path}: {e}")
        raise

def encode_image(image_path):
    """
    Convert an image file to base64 encoded string.
    Used for API requests that require base64 encoding.
    """
    try:
        with open(image_path, "rb") as image_file:
            return base64.b64encode(image_file.read()).decode('utf-8')
    except Exception as e:
        logger.error(f"Error encoding image {image_path}: {e}")
        raise

def save_display_image(image_path, output_path=None, size=(400, 400)):
    """
    Display an image and optionally save it to the specified path.
    
    Args:
        image_path: Path to the image file
        output_path: Optional path to save the displayed image
        size: Tuple of (width, height) for display
    
    Returns:
        Path to the saved image if output_path is provided, otherwise None
    """
    try:
        img = Image.open(image_path)
        plt.figure(figsize=(10, 10))
        plt.imshow(img)
        plt.axis('off')
        
        if output_path:
            plt.savefig(output_path, bbox_inches='tight', pad_inches=0.1)
            logger.info(f"Image saved to {output_path}")
            return output_path
        
        plt.close()
        return None
    except Exception as e:
        logger.error(f"Error displaying/saving image {image_path}: {e}")
        return None

def get_image_files(folder_path, extensions=('.png', '.jpg', '.jpeg', '.gif')):
    """
    Get a list of image files in the specified folder.
    
    Args:
        folder_path: Path to the folder containing images
        extensions: Tuple of valid image extensions
    
    Returns:
        List of image filenames (not full paths)
    """
    if not os.path.exists(folder_path):
        logger.warning(f"Image folder {folder_path} not found")
        return []
    
    image_files = [
        f for f in os.listdir(folder_path)
        if os.path.isfile(os.path.join(folder_path, f))
        and f.lower().endswith(extensions)
    ]
    
    logger.info(f"Found {len(image_files)} images in {folder_path}")
    return image_files
