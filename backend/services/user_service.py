"""User service for business logic."""

from typing import Dict, Any

from backend.repositories.user_repository import UserRepository
from backend.models.domain import DomainUser
from backend.exceptions import ResourceNotFoundError
from backend.utils import get_timestamp


class UserService:
    """Service for user business logic."""
    
    def __init__(self, user_repository: UserRepository):
        """Initialize user service.
        
        Args:
            user_repository: UserRepository instance
        """
        self.user_repo = user_repository
    
    def create_user(self, user_data: Dict[str, Any]) -> DomainUser:
        """Create a new user.
        
        Args:
            user_data: Dictionary with user data
            
        Returns:
            Created DomainUser
            
        Raises:
            ResourceAlreadyExistsError: If user already exists
        """
        timestamp = get_timestamp()
        
        user = DomainUser(
            user_id=user_data['userId'],
            name=user_data['name'],
            created_at=timestamp
        )
        
        return self.user_repo.create(user)
    
    def get_user(self, user_id: str) -> DomainUser:
        """Get a user by ID.
        
        Args:
            user_id: User ID
            
        Returns:
            DomainUser
            
        Raises:
            ResourceNotFoundError: If user not found
        """
        user = self.user_repo.get_by_id(user_id)
        if not user:
            raise ResourceNotFoundError(f"User with ID {user_id} not found")
        return user
