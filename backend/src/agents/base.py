"""Base agent interface for all AI agents."""
from abc import ABC, abstractmethod
from typing import Any, Dict, Optional
from enum import Enum


class AgentVendor(str, Enum):
    """Supported AI vendors."""
    OPENAI = "openai"
    GOOGLE = "google"
    ANTHROPIC = "anthropic"
    MISTRAL = "mistral"
    ELEVENLABS = "elevenlabs"
    AZURE = "azure"
    AWS = "aws"


class BaseAgent(ABC):
    """Base class for all AI agents."""
    
    def __init__(self, vendor: AgentVendor, config: Dict[str, Any]):
        self.vendor = vendor
        self.config = config
        self.api_key = config.get("api_key")
        self.model = config.get("model")
        
    @abstractmethod
    async def process(self, input_data: Any, **kwargs) -> Any:
        """Process input and return result."""
        pass
    
    @abstractmethod
    def validate_config(self) -> bool:
        """Validate agent configuration."""
        pass
    
    def get_vendor_client(self):
        """Get vendor-specific client."""
        # This will be implemented by each agent based on vendor
        raise NotImplementedError