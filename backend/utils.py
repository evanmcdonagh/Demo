"""Shared utility functions."""

from datetime import datetime


def get_timestamp() -> str:
    """Generate ISO format timestamp."""
    return datetime.utcnow().isoformat()
