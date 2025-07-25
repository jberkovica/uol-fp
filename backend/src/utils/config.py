"""Configuration utilities for loading and accessing config.yaml."""
import os
import re
import yaml
from typing import Dict, Any

_config_cache: Dict[str, Any] = {}


def load_config() -> Dict[str, Any]:
    """Load configuration from config.yaml with environment variable expansion."""
    global _config_cache
    
    if _config_cache:
        return _config_cache
    
    # Look for config.yaml in the backend directory
    backend_dir = os.path.dirname(os.path.dirname(os.path.dirname(__file__)))
    config_path = os.path.join(backend_dir, "config.yaml")
    
    with open(config_path, 'r') as f:
        content = f.read()
    
    # Replace ${VAR} and ${VAR:default} with environment variables
    def replace_env_var(match):
        var_expr = match.group(1)
        if ':' in var_expr:
            var_name, default_value = var_expr.split(':', 1)
            return os.getenv(var_name, default_value)
        else:
            return os.getenv(var_expr, '')
    
    # Pattern to match ${VAR} or ${VAR:default}
    pattern = r'\$\{([^}]+)\}'
    expanded_content = re.sub(pattern, replace_env_var, content)
    
    # Parse YAML
    config = yaml.safe_load(expanded_content)
    _config_cache = config
    return config


def get_config() -> Dict[str, Any]:
    """Get the loaded configuration."""
    return load_config()


def clear_config_cache():
    """Clear the configuration cache (useful for testing)."""
    global _config_cache
    _config_cache = {}