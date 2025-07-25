"""Custom exceptions for the application."""


class MiraException(Exception):
    """Base exception for all Mira application errors."""
    def __init__(self, message: str, code: str = None):
        self.message = message
        self.code = code
        super().__init__(message)


class ValidationError(MiraException):
    """Raised when input validation fails."""
    def __init__(self, message: str):
        super().__init__(message, code="VALIDATION_ERROR")


class NotFoundError(MiraException):
    """Raised when a resource is not found."""
    def __init__(self, resource: str, id: str):
        message = f"{resource} with id '{id}' not found"
        super().__init__(message, code="NOT_FOUND")


class AuthenticationError(MiraException):
    """Raised when authentication fails."""
    def __init__(self, message: str = "Authentication failed"):
        super().__init__(message, code="AUTHENTICATION_ERROR")


class AuthorizationError(MiraException):
    """Raised when user lacks permissions."""
    def __init__(self, message: str = "Insufficient permissions"):
        super().__init__(message, code="AUTHORIZATION_ERROR")


class AgentError(MiraException):
    """Raised when an AI agent fails."""
    def __init__(self, agent_type: str, message: str):
        full_message = f"{agent_type} agent error: {message}"
        super().__init__(full_message, code=f"{agent_type.upper()}_AGENT_ERROR")


class StorageError(MiraException):
    """Raised when storage operations fail."""
    def __init__(self, message: str):
        super().__init__(message, code="STORAGE_ERROR")


class RateLimitError(MiraException):
    """Raised when rate limit is exceeded."""
    def __init__(self, message: str = "Rate limit exceeded"):
        super().__init__(message, code="RATE_LIMIT_ERROR")