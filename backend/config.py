"""Application configuration."""

import os
from typing import Optional


class Config:
    """Application configuration loaded from environment variables."""
    
    def __init__(self, table_name: str, aws_region: Optional[str] = None):
        self.table_name = table_name
        self.aws_region = aws_region
    
    @classmethod
    def from_env(cls) -> 'Config':
        """Load configuration from environment variables."""
        table_name = os.environ.get('EVENTS_TABLE_NAME', 'EventsTable')
        aws_region = os.environ.get('AWS_REGION', os.environ.get('AWS_DEFAULT_REGION'))
        return cls(table_name=table_name, aws_region=aws_region)
