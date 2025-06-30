"""
SQLAlchemy models for Mira Storyteller database with user authentication
Implements proper user -> kids -> stories relationships
"""

from sqlalchemy import Column, String, Text, DateTime, Boolean, ForeignKey, JSON
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
import uuid

Base = declarative_base()


class Kid(Base):
    """
    Kids table - child profiles linked to authenticated users
    Each user can have multiple kids
    """
    __tablename__ = "kids"
    
    # Primary key
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    
    # Link to Supabase Auth user
    user_id = Column(UUID(as_uuid=True), nullable=False)  # References auth.users(id)
    
    # Kid profile information
    name = Column(String(100), nullable=False)
    avatar_type = Column(String(50), default='profile1')  # ProfileType enum value
    
    # Timestamps
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
    
    # Relationship to stories
    stories = relationship("Story", back_populates="kid", cascade="all, delete-orphan")


class Story(Base):
    """
    Stories table - now properly linked to kids and users
    Replaces the in-memory stories_db = {} with proper relationships
    """
    __tablename__ = "stories"
    
    # Primary key
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    
    # Foreign key to kids table
    kid_id = Column(UUID(as_uuid=True), ForeignKey('kids.id'), nullable=False)
    
    # Keep child_name for backward compatibility and easy display
    child_name = Column(String(100), nullable=False)
    
    # Story content
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
    
    # Relationship to kid
    kid = relationship("Kid", back_populates="stories")


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