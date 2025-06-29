"""
Minimal SQLAlchemy models for Mira Storyteller database
Start simple, add features incrementally
"""

from sqlalchemy import Column, String, Text, DateTime, Boolean, ForeignKey, JSON
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
import uuid

Base = declarative_base()


class Story(Base):
    """
    Core stories table - replaces the in-memory stories_db = {}
    Start with just what we currently store in memory
    """
    __tablename__ = "stories"
    
    # Core fields (matching current in-memory structure)
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    child_name = Column(String(100), nullable=False)  # Simple for now, no user system yet
    title = Column(String(200), nullable=False)
    content = Column(Text, nullable=False)
    language = Column(String(5), default='en')  # en, ru, lv, es
    
    # AI processing fields
    image_caption = Column(Text, nullable=True)
    audio_filename = Column(String(255), nullable=True)
    status = Column(String(20), default='processing')  # processing, approved, rejected
    
    # Metadata
    preferences = Column(JSON, default=lambda: {})  # Store the current preferences dict
    ai_models_used = Column(JSON, default=lambda: {})  # Track which models were used
    
    # Timestamps
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())


# Future tables - commented out for incremental implementation
"""
class Family(Base):
    # Add when we implement user authentication
    pass

class UserProfile(Base):
    # Add when we implement parent/child accounts  
    pass

class Subscription(Base):
    # Add when we research app store vs web subscriptions
    pass
"""