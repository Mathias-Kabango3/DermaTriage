"""Configuration and path helpers for the DermaTriage ML pipeline."""

from pathlib import Path

import yaml


def load_config(path):
    """Load a YAML config file and return it as a dict.

    Args:
        path: Path to the YAML file.

    Returns:
        dict: Parsed configuration.
    """
    with open(path, "r") as f:
        return yaml.safe_load(f)


def get_project_root():
    """Return the project root, two levels above this file.

    This file lives at ``<root>/src/utils/config.py``, so the parent of the
    parent of the containing directory is the project root.
    """
    return Path(__file__).resolve().parents[2]
