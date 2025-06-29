"""
Kid management service for Mira Storyteller
Handles CRUD operations for kid profiles linked to users
"""

from typing import List, Optional, Dict, Any
from sqlalchemy.orm import Session
from sqlalchemy.exc import SQLAlchemyError
import logging
import uuid

from ..database.database import DatabaseSession
from ..database.models import Kid

logger = logging.getLogger(__name__)


class KidService:
    """Service for managing kid profiles"""

    @staticmethod
    def create_kid(user_id: str, name: str, avatar_type: str = 'hero1') -> Optional[str]:
        """
        Create a new kid profile for a user
        
        Args:
            user_id: Supabase Auth user ID
            name: Kid's name
            avatar_type: Avatar character type (default: 'hero1')
            
        Returns:
            Kid ID if successful, None if failed
        """
        try:
            with DatabaseSession() as session:
                # Create new kid
                new_kid = Kid(
                    user_id=uuid.UUID(user_id),
                    name=name.strip(),
                    avatar_type=avatar_type
                )
                
                session.add(new_kid)
                session.commit()
                session.refresh(new_kid)
                
                logger.info(f"Created kid '{name}' for user {user_id}")
                return str(new_kid.id)
                
        except SQLAlchemyError as e:
            logger.error(f"Database error creating kid: {str(e)}")
            return None
        except Exception as e:
            logger.error(f"Error creating kid: {str(e)}")
            return None

    @staticmethod
    def get_kid(kid_id: str) -> Optional[Dict[str, Any]]:
        """
        Get a kid by ID
        
        Args:
            kid_id: Kid UUID
            
        Returns:
            Kid data dict or None if not found
        """
        try:
            with DatabaseSession() as session:
                kid = session.query(Kid).filter(Kid.id == uuid.UUID(kid_id)).first()
                
                if not kid:
                    return None
                
                return {
                    'kid_id': str(kid.id),
                    'user_id': str(kid.user_id),
                    'name': kid.name,
                    'avatar_type': kid.avatar_type,
                    'created_at': kid.created_at.isoformat(),
                    'updated_at': kid.updated_at.isoformat()
                }
                
        except SQLAlchemyError as e:
            logger.error(f"Database error getting kid {kid_id}: {str(e)}")
            return None
        except Exception as e:
            logger.error(f"Error getting kid {kid_id}: {str(e)}")
            return None

    @staticmethod
    def list_kids_for_user(user_id: str) -> List[Dict[str, Any]]:
        """
        Get all kids for a specific user
        
        Args:
            user_id: Supabase Auth user ID
            
        Returns:
            List of kid data dicts
        """
        try:
            with DatabaseSession() as session:
                kids = session.query(Kid).filter(
                    Kid.user_id == uuid.UUID(user_id)
                ).order_by(Kid.created_at.asc()).all()
                
                return [
                    {
                        'kid_id': str(kid.id),
                        'user_id': str(kid.user_id),
                        'name': kid.name,
                        'avatar_type': kid.avatar_type,
                        'created_at': kid.created_at.isoformat(),
                        'updated_at': kid.updated_at.isoformat()
                    }
                    for kid in kids
                ]
                
        except SQLAlchemyError as e:
            logger.error(f"Database error listing kids for user {user_id}: {str(e)}")
            return []
        except Exception as e:
            logger.error(f"Error listing kids for user {user_id}: {str(e)}")
            return []

    @staticmethod
    def update_kid(kid_id: str, updates: Dict[str, Any]) -> bool:
        """
        Update a kid's information
        
        Args:
            kid_id: Kid UUID
            updates: Dict with fields to update (name, avatar_type)
            
        Returns:
            True if successful, False otherwise
        """
        try:
            with DatabaseSession() as session:
                kid = session.query(Kid).filter(Kid.id == uuid.UUID(kid_id)).first()
                
                if not kid:
                    logger.warning(f"Kid {kid_id} not found for update")
                    return False
                
                # Update allowed fields
                if 'name' in updates:
                    kid.name = updates['name'].strip()
                if 'avatar_type' in updates:
                    kid.avatar_type = updates['avatar_type']
                
                session.commit()
                logger.info(f"Updated kid {kid_id}")
                return True
                
        except SQLAlchemyError as e:
            logger.error(f"Database error updating kid {kid_id}: {str(e)}")
            return False
        except Exception as e:
            logger.error(f"Error updating kid {kid_id}: {str(e)}")
            return False

    @staticmethod
    def delete_kid(kid_id: str) -> bool:
        """
        Delete a kid and all associated stories
        
        Args:
            kid_id: Kid UUID
            
        Returns:
            True if successful, False otherwise
        """
        try:
            with DatabaseSession() as session:
                kid = session.query(Kid).filter(Kid.id == uuid.UUID(kid_id)).first()
                
                if not kid:
                    logger.warning(f"Kid {kid_id} not found for deletion")
                    return False
                
                # Delete kid (cascade will delete associated stories)
                session.delete(kid)
                session.commit()
                
                logger.info(f"Deleted kid {kid_id} and associated stories")
                return True
                
        except SQLAlchemyError as e:
            logger.error(f"Database error deleting kid {kid_id}: {str(e)}")
            return False
        except Exception as e:
            logger.error(f"Error deleting kid {kid_id}: {str(e)}")
            return False

    @staticmethod
    def verify_kid_belongs_to_user(kid_id: str, user_id: str) -> bool:
        """
        Verify that a kid belongs to a specific user
        
        Args:
            kid_id: Kid UUID
            user_id: Supabase Auth user ID
            
        Returns:
            True if kid belongs to user, False otherwise
        """
        try:
            with DatabaseSession() as session:
                kid = session.query(Kid).filter(
                    Kid.id == uuid.UUID(kid_id),
                    Kid.user_id == uuid.UUID(user_id)
                ).first()
                
                return kid is not None
                
        except SQLAlchemyError as e:
            logger.error(f"Database error verifying kid ownership: {str(e)}")
            return False
        except Exception as e:
            logger.error(f"Error verifying kid ownership: {str(e)}")
            return False