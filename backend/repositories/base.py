"""Base repository class."""


class BaseRepository:
    """Base class for all repositories."""
    
    def __init__(self, table):
        """Initialize repository with DynamoDB table.
        
        Args:
            table: boto3 DynamoDB Table resource
        """
        self.table = table
