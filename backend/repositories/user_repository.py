"""User repository for data access operations."""

from typing import Optional
from botocore.exceptions import ClientError

from backend.repositories.base import BaseRepository
from backend.models.domain import DomainUser
from backend.exceptions import ResourceAlreadyExistsError, RepositoryError


class UserRepository(BaseRepository):
    """Repository for user data access."""
    
    def create(self, user: DomainUser) -> DomainUser:
        """Create a new user.
        
        Args:
            user: DomainUser to create
            
        Returns:
            Created DomainUser
            
        Raises:
            ResourceAlreadyExistsError: If user already exists
            RepositoryError: If database operation fails
        """
        try:
            self.table.put_item(
                Item={
                    'PK': f'USER#{user.user_id}',
                    'SK': 'PROFILE',
                    'userId': user.user_id,
                    'name': user.name,
                    'createdAt': user.created_at
                },
                ConditionExpression='attribute_not_exists(PK)'
            )
            return user
        except ClientError as e:
            if e.response['Error']['Code'] == 'ConditionalCheckFailedException':
                raise ResourceAlreadyExistsError(f"User with ID {user.user_id} already exists")
            raise RepositoryError(f"Failed to create user: {str(e)}")
    
    def get_by_id(self, user_id: str) -> Optional[DomainUser]:
        """Get user by ID.
        
        Args:
            user_id: User ID
            
        Returns:
            DomainUser if found, None otherwise
            
        Raises:
            RepositoryError: If database operation fails
        """
        try:
            response = self.table.get_item(
                Key={
                    'PK': f'USER#{user_id}',
                    'SK': 'PROFILE'
                }
            )
            
            if 'Item' not in response:
                return None
            
            item = response['Item']
            return DomainUser(
                user_id=item['userId'],
                name=item['name'],
                created_at=item['createdAt']
            )
        except ClientError as e:
            raise RepositoryError(f"Failed to get user: {str(e)}")
    
    def exists(self, user_id: str) -> bool:
        """Check if user exists.
        
        Args:
            user_id: User ID
            
        Returns:
            True if user exists, False otherwise
            
        Raises:
            RepositoryError: If database operation fails
        """
        return self.get_by_id(user_id) is not None
