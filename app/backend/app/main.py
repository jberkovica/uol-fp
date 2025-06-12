from fastapi import FastAPI, UploadFile, File, HTTPException, Depends, BackgroundTasks, Form
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from pydantic import BaseModel, EmailStr
from typing import Optional, List
import os
import uuid
import logging
from datetime import datetime

# Initialize FastAPI app
app = FastAPI(
    title="Mira Storyteller API",
    description="Backend API for Mira Storyteller application",
    version="0.1.0"
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

# Models
class StoryRequest(BaseModel):
    image_id: str
    parent_email: EmailStr
    child_name: str
    preferences: Optional[dict] = None

class StoryResponse(BaseModel):
    story_id: str
    status: str
    message: str

class StoryReview(BaseModel):
    story_id: str
    approved: bool
    feedback: Optional[str] = None

# Routes
@app.get("/")
def read_root():
    return {"message": "Welcome to Mira Storyteller API", "status": "active"}

@app.post("/upload-image/", response_model=dict)
async def upload_image(file: UploadFile = File(...)):
    """
    Upload an image for story generation
    """
    try:
        # Create a unique ID for the image
        image_id = str(uuid.uuid4())
        
        # Here we would save the file to storage (e.g., local disk or cloud storage)
        # For now, we'll just return success with the image ID
        
        logger.info(f"Image uploaded with ID: {image_id}")
        return {
            "image_id": image_id,
            "status": "success",
            "message": "Image uploaded successfully"
        }
    except Exception as e:
        logger.error(f"Error uploading image: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Error uploading image: {str(e)}")

@app.post("/generate-story/", response_model=StoryResponse)
async def generate_story(
    story_request: StoryRequest,
    background_tasks: BackgroundTasks
):
    """
    Generate a story based on the uploaded image
    """
    try:
        # Create a unique ID for the story
        story_id = str(uuid.uuid4())
        
        # In a real implementation, we would:
        # 1. Retrieve the image from storage
        # 2. Analyze the image using AI
        # 3. Generate a story based on the analysis
        # 4. Send an email to the parent for approval
        
        # Add story generation to background tasks
        background_tasks.add_task(
            process_story_generation,
            story_id,
            story_request.image_id,
            story_request.parent_email,
            story_request.child_name,
            story_request.preferences
        )
        
        logger.info(f"Story generation initiated with ID: {story_id}")
        return StoryResponse(
            story_id=story_id,
            status="pending",
            message="Story generation initiated. Parent will receive an email for approval."
        )
    except Exception as e:
        logger.error(f"Error generating story: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Error generating story: {str(e)}")

@app.post("/review-story/", response_model=dict)
async def review_story(review: StoryReview):
    """
    Handle parent review of the generated story
    """
    try:
        # In a real implementation, we would:
        # 1. Update the story status in database
        # 2. If approved, convert to audio
        # 3. Make available in the child's app
        
        status = "approved" if review.approved else "rejected"
        logger.info(f"Story {review.story_id} {status} by parent")
        
        return {
            "story_id": review.story_id,
            "status": status,
            "message": f"Story has been {status}"
        }
    except Exception as e:
        logger.error(f"Error reviewing story: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Error reviewing story: {str(e)}")

@app.get("/story/{story_id}", response_model=dict)
async def get_story(story_id: str):
    """
    Retrieve a story by ID
    """
    try:
        # In a real implementation, we would:
        # 1. Retrieve the story from database
        # 2. Check if it's approved
        # 3. Return the story content and audio URL
        
        # Mock response for now
        return {
            "story_id": story_id,
            "title": "Froggy's Adventure",
            "content": "Once upon a time, there was a tiny green frog...",
            "audio_url": f"/audio/{story_id}.mp3",
            "status": "approved",
            "created_at": datetime.now().isoformat()
        }
    except Exception as e:
        logger.error(f"Error retrieving story: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Error retrieving story: {str(e)}")

# Background task for story generation
async def process_story_generation(
    story_id: str,
    image_id: str,
    parent_email: str,
    child_name: str,
    preferences: Optional[dict]
):
    """
    Process story generation in the background
    """
    try:
        logger.info(f"Processing story generation for ID: {story_id}")
        
        # In a real implementation, we would:
        # 1. Analyze the image using AI models
        # 2. Generate a story based on the analysis
        # 3. Send an email to the parent for approval
        
        # For now, we'll just log the process
        logger.info(f"Story generated for {child_name}, email sent to {parent_email}")
    except Exception as e:
        logger.error(f"Error in background story processing: {str(e)}")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("app.main:app", host="0.0.0.0", port=8000, reload=True)
