# Mira Storyteller

## Overview
Mira Storyteller is an interactive application designed to transform children's drawings and photos into narrated stories. The app aims to foster creativity, imagination, and literacy in children while providing an engaging and educational entertainment experience.

## Features

- **Image Upload**: Children can upload their drawings or photos through a kid-friendly interface
- **Image Analysis**: AI-powered image recognition identifies elements in the uploaded image
- **Story Generation**: Advanced language models create custom stories based on the identified elements
- **Parental Review**: Parents receive notification to approve generated stories before they're available to children
- **Text-to-Speech Narration**: Approved stories are narrated with an engaging, child-friendly voice
- **User Profiles**: Separate interfaces for children and parents

## Tech Stack

### Frontend
- **Flutter**: Cross-platform UI framework for iOS and Android
- **Dart**: Programming language for Flutter

### Backend
- **Python**: Server-side language
- **FastAPI**: API framework for the backend service
- **Google Cloud Storage**: For storing images and audio files

### AI/ML Services
- **Image Analysis**: Google Gemini Vision (or similar) for image understanding
- **Story Generation**: Google Gemini Pro (or similar) for creative text generation
- **Text-to-Speech**: Google Cloud TTS (or similar) for audio narration

## Architecture

The application follows a client-server architecture:

1. **Child App**: Flutter UI for image upload and story playback
2. **Parent Dashboard**: Flutter UI for story review and account management
3. **Backend Server**: Python/FastAPI service handling:
   - Image processing
   - AI model integration
   - User authentication
   - Content storage and retrieval
   - Notification system

## Setup and Installation

### Prerequisites
- Flutter SDK (version 3.0+)
- Dart (version 2.17+)
- Python (version 3.9+)
- Google Cloud account (for AI services)

### Frontend Setup
```bash
# Navigate to the Flutter app directory
cd app/flutter_app

# Get dependencies
flutter pub get

# Run the app in development mode
flutter run
```

### Backend Setup
```bash
# Navigate to the Python backend directory
cd app/backend

# Create and activate virtual environment
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Start the server
python main.py
```

## Project Status
This project is currently under development as part of a university final project.

## License
[Specify license information here]

## Contact
For questions or feedback, please contact [your contact information].
