"""
Story service layer for database operations
Replaces the in-memory stories_db = {} dictionary
"""

from typing import Optional, Dict, Any, List
from sqlalchemy.orm import Session
from sqlalchemy.exc import SQLAlchemyError
from app.database import Story, get_database, close_database_session
import logging
from datetime import datetime

logger = logging.getLogger(__name__)


class StoryService:
    """Service for story database operations"""
    
    @staticmethod
    def create_story(
        child_name: str,
        title: str = "",
        content: str = "",
        language: str = "en",
        image_caption: str = None,
        preferences: Dict[str, Any] = None,
        status: str = "processing"
    ) -> Optional[str]:
        """
        Create a new story record
        
        Args:
            child_name: Name of the child
            title: Story title
            content: Story content
            language: Story language (en, ru, lv, es)
            image_caption: Generated image caption
            preferences: Story preferences
            status: Initial status
            
        Returns:
            Story ID if successful, None if failed
        """
        try:
            db = get_database()
            
            story = Story(
                child_name=child_name,
                title=title or "Untitled Story",
                content=content or "",
                language=language,
                image_caption=image_caption,
                preferences=preferences or {},
                status=status
            )
            
            db.add(story)
            db.commit()
            db.refresh(story)
            
            story_id = str(story.id)
            logger.info(f"Created story {story_id} for {child_name}")
            
            close_database_session(db)
            return story_id
            
        except SQLAlchemyError as e:
            logger.error(f"Database error creating story: {e}")
            if db:
                db.rollback()
                close_database_session(db)
            return None
        except Exception as e:
            logger.error(f"Error creating story: {e}")
            if db:
                close_database_session(db)
            return None
    
    @staticmethod
    def get_story(story_id: str) -> Optional[Dict[str, Any]]:
        """
        Get story by ID
        
        Args:
            story_id: Story ID
            
        Returns:
            Story data as dict, None if not found
        """
        try:
            db = get_database()
            
            story = db.query(Story).filter(Story.id == story_id).first()
            
            if not story:
                close_database_session(db)
                return None
            
            # Convert to dict format matching current API expectations
            story_dict = {
                "story_id": str(story.id),
                "child_name": story.child_name,
                "title": story.title,
                "content": story.content,
                "language": story.language,
                "status": story.status,
                "created_at": story.created_at.isoformat(),
                "preferences": story.preferences,
                "image_caption": story.image_caption,
                "audio_filename": story.audio_filename,
                "ai_models_used": story.ai_models_used
            }
            
            close_database_session(db)
            return story_dict
            
        except SQLAlchemyError as e:
            logger.error(f"Database error getting story {story_id}: {e}")
            if db:
                close_database_session(db)
            return None
        except Exception as e:
            logger.error(f"Error getting story {story_id}: {e}")
            if db:
                close_database_session(db)
            return None
    
    @staticmethod
    def update_story(story_id: str, updates: Dict[str, Any]) -> bool:
        """
        Update story fields
        
        Args:
            story_id: Story ID
            updates: Dict of fields to update
            
        Returns:
            True if successful, False otherwise
        """
        try:
            db = get_database()
            
            story = db.query(Story).filter(Story.id == story_id).first()
            
            if not story:
                close_database_session(db)
                return False
            
            # Update allowed fields
            allowed_fields = [
                'title', 'content', 'status', 'image_caption', 
                'audio_filename', 'preferences', 'ai_models_used'
            ]
            
            for field, value in updates.items():
                if field in allowed_fields and hasattr(story, field):
                    setattr(story, field, value)
            
            db.commit()
            
            logger.info(f"Updated story {story_id}")
            close_database_session(db)
            return True
            
        except SQLAlchemyError as e:
            logger.error(f"Database error updating story {story_id}: {e}")
            if db:
                db.rollback()
                close_database_session(db)
            return False
        except Exception as e:
            logger.error(f"Error updating story {story_id}: {e}")
            if db:
                close_database_session(db)
            return False
    
    @staticmethod
    def list_stories(
        limit: int = 50,
        offset: int = 0,
        status: str = None,
        language: str = None
    ) -> List[Dict[str, Any]]:
        """
        List stories with optional filtering
        
        Args:
            limit: Maximum number of stories to return
            offset: Number of stories to skip
            status: Filter by status
            language: Filter by language
            
        Returns:
            List of story dicts
        """
        try:
            db = get_database()
            
            query = db.query(Story)
            
            # Apply filters
            if status:
                query = query.filter(Story.status == status)
            if language:
                query = query.filter(Story.language == language)
            
            # Order by creation date (newest first)
            query = query.order_by(Story.created_at.desc())
            
            # Apply pagination
            stories = query.offset(offset).limit(limit).all()
            
            # Convert to dict format
            story_list = []
            for story in stories:
                story_dict = {
                    "story_id": str(story.id),
                    "child_name": story.child_name,
                    "title": story.title,
                    "content": story.content,
                    "language": story.language,
                    "status": story.status,
                    "created_at": story.created_at.isoformat(),
                    "audio_filename": story.audio_filename
                }
                story_list.append(story_dict)
            
            close_database_session(db)
            return story_list
            
        except SQLAlchemyError as e:
            logger.error(f"Database error listing stories: {e}")
            if db:
                close_database_session(db)
            return []
        except Exception as e:
            logger.error(f"Error listing stories: {e}")
            if db:
                close_database_session(db)
            return []
    
    @staticmethod
    def delete_story(story_id: str) -> bool:
        """
        Delete story by ID
        
        Args:
            story_id: Story ID
            
        Returns:
            True if successful, False otherwise
        """
        try:
            db = get_database()
            
            story = db.query(Story).filter(Story.id == story_id).first()
            
            if not story:
                close_database_session(db)
                return False
            
            db.delete(story)
            db.commit()
            
            logger.info(f"Deleted story {story_id}")
            close_database_session(db)
            return True
            
        except SQLAlchemyError as e:
            logger.error(f"Database error deleting story {story_id}: {e}")
            if db:
                db.rollback()
                close_database_session(db)
            return False
        except Exception as e:
            logger.error(f"Error deleting story {story_id}: {e}")
            if db:
                close_database_session(db)
            return False