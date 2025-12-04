"""User API routes."""

from fastapi import APIRouter, HTTPException, status, Depends

from backend.models.api import User
from backend.services.user_service import UserService
from backend.dependencies import get_user_service
from backend.exceptions import ResourceNotFoundError, ResourceAlreadyExistsError, RepositoryError


router = APIRouter(prefix="/users", tags=["users"])


@router.post("", response_model=User, status_code=status.HTTP_201_CREATED)
def create_user(
    user: User,
    user_service: UserService = Depends(get_user_service)
):
    """Create a new user."""
    try:
        user_data = user.model_dump()
        domain_user = user_service.create_user(user_data)
        
        # Convert domain model to API model
        return User(
            userId=domain_user.user_id,
            name=domain_user.name,
            createdAt=domain_user.created_at
        )
    except ResourceAlreadyExistsError as e:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=str(e)
        )
    except RepositoryError as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )


@router.get("/{user_id}", response_model=User)
def get_user(
    user_id: str,
    user_service: UserService = Depends(get_user_service)
):
    """Get a user by ID."""
    try:
        domain_user = user_service.get_user(user_id)
        
        # Convert domain model to API model
        return User(
            userId=domain_user.user_id,
            name=domain_user.name,
            createdAt=domain_user.created_at
        )
    except ResourceNotFoundError as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(e)
        )
    except RepositoryError as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )
