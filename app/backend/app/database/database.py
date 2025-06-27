"""
Minimal database connection and setup for Supabase
"""

import os
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, Session
from supabase import create_client, Client
from .models import Base
import logging
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

logger = logging.getLogger(__name__)

# Global database objects
engine = None
SessionLocal = None
supabase_client = None


def get_database_url() -> str:
    """Get database URL from environment"""
    # For development, allow SQLite fallback
    database_url = os.getenv("DATABASE_URL")
    
    if not database_url:
        # SQLite fallback for development
        database_url = "sqlite:///./mira_storyteller.db"
        logger.warning("No DATABASE_URL found, using SQLite fallback")
    
    return database_url


def init_database():
    """Initialize database connection"""
    global engine, SessionLocal, supabase_client
    
    database_url = get_database_url()
    
    # Create SQLAlchemy engine
    if database_url.startswith("sqlite"):
        engine = create_engine(database_url, connect_args={"check_same_thread": False})
    else:
        engine = create_engine(database_url)
    
    SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
    
    # Create tables
    Base.metadata.create_all(bind=engine)
    
    # Initialize Supabase client (optional for now)
    supabase_url = os.getenv("SUPABASE_URL")
    supabase_key = os.getenv("SUPABASE_ANON_KEY")
    
    if supabase_url and supabase_key:
        supabase_client = create_client(supabase_url, supabase_key)
        logger.info("Supabase client initialized")
    else:
        logger.warning("Supabase credentials not found, running without Supabase client")
    
    logger.info(f"Database initialized with URL: {database_url}")


def get_database() -> Session:
    """Get database session"""
    if SessionLocal is None:
        init_database()
    
    db = SessionLocal()
    try:
        return db
    except Exception as e:
        db.close()
        raise e


def close_database_session(db: Session):
    """Close database session"""
    db.close()


# Context manager for database sessions
class DatabaseSession:
    def __init__(self):
        self.db = None
    
    def __enter__(self) -> Session:
        self.db = get_database()
        return self.db
    
    def __exit__(self, exc_type, exc_val, exc_tb):
        if self.db:
            self.db.close()