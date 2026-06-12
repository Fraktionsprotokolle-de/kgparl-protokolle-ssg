#!/usr/bin/env python3
"""
Environment configuration helper module.

Provides utilities for loading environment-specific configuration
for Typesense and GitHub settings.
"""

import json
import os
from pathlib import Path
from dotenv import load_dotenv

# Get the project root directory
PROJECT_ROOT = Path(__file__).parent.parent
CONFIG_DIR = PROJECT_ROOT / "config"


def get_environment_config(env_name: str = "live") -> dict:
    """
    Load the complete configuration for a given environment.

    Args:
        env_name: Environment name ('live' or 'test')

    Returns:
        dict with 'typesense' and 'github' configuration
    """
    env_file = CONFIG_DIR / "environments.json"

    if not env_file.exists():
        raise FileNotFoundError(f"Environment config file not found: {env_file}")

    with open(env_file, "r", encoding="utf-8") as f:
        all_configs = json.load(f)

    if env_name not in all_configs:
        raise ValueError(f"Unknown environment: {env_name}. Available: {list(all_configs.keys())}")

    return all_configs[env_name]


def load_env_secrets(env_name: str = "live") -> dict:
    """
    Load secrets from the environment-specific .env file.

    Args:
        env_name: Environment name ('live' or 'test')

    Returns:
        dict with apiKey, adminKey, and githubToken
    """
    env_file = CONFIG_DIR / f"{env_name}.env"

    if not env_file.exists():
        # Fallback to root .env file
        env_file = PROJECT_ROOT / ".env"

    if env_file.exists():
        load_dotenv(env_file, override=True)

    return {
        "apiKey": os.getenv("TYPESENSE_API_KEY", os.getenv("TYPESENSE_SEARCH_KEY", "")),
        "adminKey": os.getenv("TYPESENSE_ADMIN_KEY", os.getenv("TYPESENSE_API_KEY", "")),
        "githubToken": os.getenv("GITHUB_TOKEN", os.getenv("TOKEN", "")),
    }


def get_typesense_config(env_name: str = "live") -> dict:
    """
    Get Typesense connection configuration for a given environment.

    Args:
        env_name: Environment name ('live' or 'test')

    Returns:
        dict with host, port, protocol, timeout, apiKey, and collections
    """
    config = get_environment_config(env_name)
    secrets = load_env_secrets(env_name)

    ts_config = config["typesense"]

    return {
        "host": ts_config["host"],
        "port": ts_config["port"],
        "protocol": ts_config["protocol"],
        "timeout": ts_config["timeout"],
        "apiKey": secrets["adminKey"],  # Use admin key for indexing
        "collections": ts_config["collections"],
    }


def get_github_config(env_name: str = "live") -> dict:
    """
    Get GitHub configuration for a given environment.

    Args:
        env_name: Environment name ('live' or 'test')

    Returns:
        dict with repo, branch, and token
    """
    config = get_environment_config(env_name)
    secrets = load_env_secrets(env_name)

    gh_config = config["github"]

    return {
        "repo": gh_config["repo"],
        "branch": gh_config["branch"],
        "token": secrets["githubToken"],
    }


def setup_typesense_env_vars(env_name: str = "live"):
    """
    Set up environment variables for Typesense client (acdh_cfts_pyutils compatibility).

    This is for backwards compatibility with scripts using TYPESENSE_CLIENT from acdh_cfts_pyutils.
    """
    ts_config = get_typesense_config(env_name)

    os.environ["TYPESENSE_API_KEY"] = ts_config["apiKey"]
    os.environ["TYPESENSE_HOST"] = ts_config["host"]
    os.environ["TYPESENSE_PORT"] = str(ts_config["port"])
    os.environ["TYPESENSE_PROTOCOL"] = ts_config["protocol"]


# Convenience function for argparse
def add_env_argument(parser):
    """Add --env argument to an argparse parser."""
    parser.add_argument(
        "--env",
        choices=["live", "test"],
        default="live",
        help="Environment to use (default: live)"
    )
    return parser
