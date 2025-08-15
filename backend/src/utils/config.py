"""Configuration utilities for loading and merging app.yaml and individual agent configs."""
import os
import re
import yaml
from typing import Dict, Any
from glob import glob

_config_cache: Dict[str, Any] = {}


def load_config() -> Dict[str, Any]:
    """Load and merge configuration from app.yaml and individual agent configs with environment variable expansion."""
    global _config_cache
    
    if _config_cache:
        return _config_cache
    
    # Look for config files in src/config directory
    config_dir = os.path.join(os.path.dirname(__file__), '..', 'config')
    app_config_path = os.path.join(config_dir, "app.yaml")
    agents_config_path = os.path.join(config_dir, "agents.yaml")
    agents_dir = os.path.join(config_dir, "agents")
    
    def load_yaml_with_env_expansion(file_path: str) -> Dict[str, Any]:
        """Load YAML file and expand environment variables."""
        with open(file_path, 'r') as f:
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
        
        return yaml.safe_load(expanded_content)
    
    # Load app configuration
    app_config = load_yaml_with_env_expansion(app_config_path)
    
    # Check if we have individual agent configs or the monolithic agents.yaml
    agents_config = {"agents": {}}
    
    if os.path.exists(agents_dir) and os.listdir(agents_dir):
        # Load individual agent configuration files
        agent_files = glob(os.path.join(agents_dir, "*.yaml"))
        
        for agent_file in agent_files:
            agent_name = os.path.basename(agent_file).replace('.yaml', '')
            try:
                agent_config = load_yaml_with_env_expansion(agent_file)
                agents_config["agents"][agent_name] = agent_config
            except Exception as e:
                print(f"Warning: Failed to load agent config {agent_file}: {e}")
                continue
                
    elif os.path.exists(agents_config_path):
        # Fallback to monolithic agents.yaml
        agents_config = load_yaml_with_env_expansion(agents_config_path)
    else:
        print("Warning: No agent configuration found (neither agents/ directory nor agents.yaml)")
    
    # Merge configurations
    config = {**app_config, **agents_config}
    _config_cache = config
    return config


def get_config() -> Dict[str, Any]:
    """Get the loaded configuration."""
    return load_config()


def clear_config_cache():
    """Clear the configuration cache (useful for testing)."""
    global _config_cache
    _config_cache = {}