from fastapi import FastAPI, UploadFile, File, HTTPException, Depends, BackgroundTasks, Form
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse, FileResponse
from pydantic import BaseModel, EmailStr
from typing import Optional, List
import os
import uuid
import logging
import tempfile
import base64
from datetime import datetime
from pathlib import Path
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

# Import our AI services
from .services.image_analysis import ImageAnalysisService
from .services.story_generator import StoryGeneratorService
from .services.text_to_speech import TextToSpeechService
from .services.story_service import StoryService

# Import validation utilities
from .utils.validation import validate_story_request

# Import database
from .database import init_database

# Initialize FastAPI app
app = FastAPI(
    title="Mira Storyteller API",
    description="Backend API for Mira Storyteller application with real AI services",
    version="0.3.0"
)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # For development; restrict in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
)
logger = logging.getLogger("mira-api")

# Initialize AI services
image_service = ImageAnalysisService()
story_service = StoryGeneratorService()
tts_service = TextToSpeechService()

# Create directories for audio storage only (no image storage needed)
AUDIO_DIR = Path("audio")
AUDIO_DIR.mkdir(exist_ok=True)

# Initialize database
try:
    init_database()
    logger.info("Database initialized successfully")
except Exception as e:
    logger.error(f"Failed to initialize database: {e}")
    raise

# Models
class ImageUpload(BaseModel):
    image_data: str  # base64 encoded image
    mime_type: str = "image/jpeg"

class StoryRequest(BaseModel):
    child_name: str
    image_data: str  # base64 encoded image
    mime_type: str = "image/jpeg"
    preferences: Optional[dict] = None

class StoryResponse(BaseModel):
    story_id: str
    status: str
    message: str

class StoryDetail(BaseModel):
    story_id: str
    title: str
    content: str
    caption: Optional[str] = None
    audio_url: Optional[str] = None
    status: str
    created_at: str
    child_name: str

class StoryReview(BaseModel):
    story_id: str
    approved: bool
    feedback: Optional[str] = None

# Routes
@app.get("/")
def read_root():
    return {
        "message": "Welcome to Mira Storyteller API with Real AI Services", 
        "status": "active",
        "version": "0.3.0",
        "ai_services": {
            "image_analysis": "Gemini 2.0 Flash",
            "story_generation": "Mistral Medium Latest", 
            "text_to_speech": "ElevenLabs Callum Voice"
        },
        "features": ["No file storage required", "Base64 image processing", "Real-time AI generation"]
    }

@app.post("/generate-story-from-image/", response_model=StoryResponse)
async def generate_story_from_image(
    background_tasks: BackgroundTasks,
    story_request: StoryRequest
):
    """
    Generate a story directly from base64 image data using real AI services
    No file storage required - processes image in memory
    """
    try:
        # Validate the request
        validate_story_request(story_request)
        
        # Create story record in database
        story_id = StoryService.create_story(
            child_name=story_request.child_name,
            preferences=story_request.preferences,
            status="processing"
        )
        
        if not story_id:
            raise HTTPException(status_code=500, detail="Failed to create story record")
        
        # Add story generation to background tasks
        background_tasks.add_task(
            process_story_generation_from_base64,
            story_id,
            story_request.image_data,
            story_request.mime_type,
            story_request.child_name,
            story_request.preferences
        )
        
        logger.info(f"Story generation initiated with ID: {story_id}")
        return StoryResponse(
            story_id=story_id,
            status="processing",
            message="Story generation initiated. Processing with AI services..."
        )
    except Exception as e:
        logger.error(f"Error generating story: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Error generating story: {str(e)}")

# Legacy endpoints for backward compatibility
@app.post("/upload-image/", response_model=dict)
async def upload_image(file: UploadFile = File(...)):
    """
    Legacy endpoint - converts uploaded file to base64 and returns it
    """
    try:
        # Validate file type
        if not file.content_type.startswith('image/'):
            raise HTTPException(status_code=400, detail="File must be an image")
        
        # Read file content and convert to base64
        content = await file.read()
        base64_data = base64.b64encode(content).decode('utf-8')
        
        # Create a unique ID
        image_id = str(uuid.uuid4())
        
        logger.info(f"Image converted to base64 with ID: {image_id}")
        return {
            "image_id": image_id,
            "status": "success",
            "message": "Image processed successfully",
            "image_data": base64_data,
            "mime_type": file.content_type
        }
    except Exception as e:
        logger.error(f"Error processing image: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Error processing image: {str(e)}")

@app.post("/generate-story/", response_model=StoryResponse)
async def generate_story(
    background_tasks: BackgroundTasks,
    image_id: str = Form(...),
    child_name: str = Form(...),
    preferences: Optional[str] = Form(None)
):
    """
    Legacy endpoint - requires image to be uploaded first
    """
    try:
        # This is now a legacy approach - recommend using generate-story-from-image directly
        logger.warning("Using legacy story generation endpoint. Consider using /generate-story-from-image/ directly.")
        
        # Create story record in database with error status
        story_id = StoryService.create_story(
            child_name=child_name,
            title="Legacy Error",
            content="Legacy endpoint used",
            preferences={"error": "Legacy endpoint - image file not found. Please use /generate-story-from-image/ with base64 data."},
            status="error"
        )
        
        logger.info(f"Story generation failed - legacy endpoint used: {story_id}")
        return StoryResponse(
            story_id=story_id,
            status="error",
            message="Please use /generate-story-from-image/ endpoint with base64 image data"
        )
    except Exception as e:
        logger.error(f"Error generating story: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Error generating story: {str(e)}")

@app.post("/review-story/", response_model=dict)
async def review_story(review: StoryReview, background_tasks: BackgroundTasks):
    """
    Handle parent review of the generated story
    """
    try:
        # Check if story exists
        story_data = StoryService.get_story(review.story_id)
        if not story_data:
            raise HTTPException(status_code=404, detail="Story not found")
        
        # Update story status
        status = "approved" if review.approved else "rejected"
        updates = {
            "status": status,
            "preferences": {
                **story_data.get("preferences", {}),
                "feedback": review.feedback
            }
        }
        
        success = StoryService.update_story(review.story_id, updates)
        if not success:
            raise HTTPException(status_code=500, detail="Failed to update story")
        
        # If approved, generate audio in background
        if review.approved:
            background_tasks.add_task(
                generate_story_audio,
                review.story_id
            )
            message = "Story approved. Generating audio..."
        else:
            message = "Story rejected. Feedback recorded."
        
        logger.info(f"Story {review.story_id} {status} by parent")
        
        return {
            "story_id": review.story_id,
            "status": status,
            "message": message
        }
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error reviewing story: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Error reviewing story: {str(e)}")

@app.get("/story/{story_id}", response_model=StoryDetail)
async def get_story(story_id: str):
    """
    Retrieve a story by ID
    """
    try:
        story_data = StoryService.get_story(story_id)
        if not story_data:
            raise HTTPException(status_code=404, detail="Story not found")
        
        # Build audio URL if audio file exists
        audio_url = None
        if story_data.get("audio_filename"):
            audio_url = f"/audio/{story_id}"
        
        return StoryDetail(
            story_id=story_data["story_id"],
            title=story_data.get("title", "Untitled Story"),
            content=story_data.get("content", "Story is being generated..."),
            caption=story_data.get("image_caption"),
            audio_url=audio_url,
            status=story_data["status"],
            created_at=story_data["created_at"],
            child_name=story_data["child_name"]
        )
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error retrieving story: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Error retrieving story: {str(e)}")

@app.get("/stories/pending", response_model=List[StoryDetail])
async def get_pending_stories():
    """Get all pending stories for parent review"""
    try:
        story_list = StoryService.list_stories(status="pending")
        pending_stories = []
        
        for story_data in story_list:
            # Build audio URL if audio file exists
            audio_url = None
            if story_data.get("audio_filename"):
                audio_url = f"/audio/{story_data['story_id']}"
            
            pending_stories.append(StoryDetail(
                story_id=story_data["story_id"],
                title=story_data.get("title", "Untitled Story"),
                content=story_data.get("content", ""),
                caption=story_data.get("image_caption"),
                audio_url=audio_url,
                status=story_data["status"],
                created_at=story_data["created_at"],
                child_name=story_data["child_name"]
            ))
        return pending_stories
    except Exception as e:
        logger.error(f"Error getting pending stories: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Error getting pending stories: {str(e)}")

@app.get("/stories/approved", response_model=List[StoryDetail])
async def get_approved_stories():
    """Get all approved stories for child app"""
    try:
        story_list = StoryService.list_stories(status="approved")
        approved_stories = []
        
        for story_data in story_list:
            # Build audio URL if audio file exists
            audio_url = None
            if story_data.get("audio_filename"):
                audio_url = f"/audio/{story_data['story_id']}"
            
            approved_stories.append(StoryDetail(
                story_id=story_data["story_id"],
                title=story_data.get("title", "Untitled Story"),
                content=story_data.get("content", ""),
                caption=story_data.get("image_caption"),
                audio_url=audio_url,
                status=story_data["status"],
                created_at=story_data["created_at"],
                child_name=story_data["child_name"]
            ))
        return approved_stories
    except Exception as e:
        logger.error(f"Error getting approved stories: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Error getting approved stories: {str(e)}")

@app.get("/audio/{story_id}")
async def get_story_audio(story_id: str):
    """Serve audio file for a story"""
    try:
        audio_path = AUDIO_DIR / f"{story_id}.mp3"
        if not audio_path.exists():
            raise HTTPException(status_code=404, detail="Audio file not found")
        
        return FileResponse(
            path=audio_path,
            media_type="audio/mpeg",
            filename=f"story_{story_id}.mp3"
        )
    except Exception as e:
        logger.error(f"Error serving audio: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Error serving audio: {str(e)}")

# Background task for story generation using real AI services with base64 images
async def process_story_generation_from_base64(
    story_id: str,
    image_data: str,
    mime_type: str,
    child_name: str,
    preferences: Optional[str]
):
    """
    Process story generation in the background using real AI services from base64 image data
    """
    try:
        logger.info(f"Processing story generation for ID: {story_id}")
        
        # Step 1: Analyze image with Gemini 2.0 Flash using base64 data
        logger.info(f"Analyzing image with Gemini 2.0 Flash from base64 data")
        image_analysis = image_service.analyze_image_from_base64(image_data, mime_type)
        caption = image_analysis.get("caption", "a colorful scene")
        
        # Step 2: Generate story with Mistral Medium
        logger.info(f"Generating story with Mistral Medium for {child_name}")
        story_result = story_service.generate_story(caption, child_name)
        
        # Step 3: Generate audio immediately (skip approval)
        logger.info(f"Generating audio immediately for story {story_id}")
        story_content = story_result.get("content", "")
        
        audio_path = None
        if story_content:
            try:
                audio_path = tts_service.generate_story_audio(
                    story_content, 
                    story_id, 
                    str(AUDIO_DIR)
                )
                logger.info(f"Audio generated successfully for story {story_id}")
            except Exception as audio_error:
                logger.error(f"Audio generation failed for story {story_id}: {str(audio_error)}")
        
        # Update story record in database - mark as approved with audio ready
        updates = {
            "image_caption": caption,
            "title": story_result.get("title", "A Magical Story"),
            "content": story_result.get("content", ""),
            "status": "approved",  # Skip approval - directly approved
            "audio_filename": f"{story_id}.mp3" if audio_path else None,
            "ai_models_used": {
                "image_analysis": image_analysis,
                "story_metadata": story_result
            }
        }
        
        success = StoryService.update_story(story_id, updates)
        if not success:
            logger.error(f"Failed to update story {story_id} in database")
        
        logger.info(f"Story generation completed for {child_name}. Audio ready!")
        
    except Exception as e:
        logger.error(f"Error in background story processing: {str(e)}")
        # Update story status to error in database
        error_updates = {
            "status": "error",
            "ai_models_used": {"error": str(e)}
        }
        StoryService.update_story(story_id, error_updates)

# Legacy background task for file-based story generation (deprecated)
async def process_story_generation(
    story_id: str,
    image_id: str,
    child_name: str,
    preferences: Optional[str]
):
    """
    Legacy process story generation in the background using real AI services
    """
    try:
        logger.warning(f"Using legacy story generation process for ID: {story_id}")
        
        # Update story status to error since we no longer store files
        error_updates = {
            "status": "error",
            "ai_models_used": {"error": "Legacy file-based processing no longer supported. Use base64 image data."}
        }
        StoryService.update_story(story_id, error_updates)
        
    except Exception as e:
        logger.error(f"Error in legacy story processing: {str(e)}")
        # Update story status to error
        error_updates = {
            "status": "error",
            "ai_models_used": {"error": str(e)}
        }
        StoryService.update_story(story_id, error_updates)

# Background task for audio generation
async def generate_story_audio(story_id: str):
    """Generate audio for an approved story"""
    try:
        story_data = StoryService.get_story(story_id)
        if not story_data:
            raise Exception("Story not found")
        
        story_content = story_data.get("content", "")
        
        if not story_content:
            raise Exception("No story content available for audio generation")
        
        logger.info(f"Generating audio for story {story_id} with ElevenLabs Callum voice")
        
        # Generate audio with Callum voice
        audio_path = tts_service.generate_story_audio(
            story_content, 
            story_id, 
            str(AUDIO_DIR)
        )
        
        if audio_path:
            audio_updates = {"audio_filename": f"{story_id}.mp3"}
            success = StoryService.update_story(story_id, audio_updates)
            if success:
                logger.info(f"Audio generated successfully for story {story_id}")
            else:
                logger.error(f"Failed to update audio info for story {story_id}")
        else:
            raise Exception("Failed to generate audio")
            
    except Exception as e:
        logger.error(f"Error generating audio for story {story_id}: {str(e)}")
        # Store audio error in database
        error_updates = {
            "ai_models_used": {"audio_error": str(e)}
        }
        StoryService.update_story(story_id, error_updates)

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("app.main:app", host="0.0.0.0", port=8000, reload=True)
