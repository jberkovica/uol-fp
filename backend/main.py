"""Mira Storyteller Backend - Main entry point."""
import os
import uvicorn
from dotenv import load_dotenv
from src.api.app import create_app, load_config

# Load environment variables from root .env file
load_dotenv("../.env")

# Create the FastAPI app
app = create_app()

if __name__ == "__main__":
    # Load configuration
    config = load_config()
    api_config = config.get("api", {})
    
    # Run the server
    uvicorn.run(
        "main:app",
        host=api_config.get("host", "0.0.0.0"),
        port=api_config.get("port", 8000),
        reload=os.getenv("ENVIRONMENT", "development") == "development",
        log_level="info"
    )