"""Dependency injection setup for FastAPI."""

import boto3
from fastapi import Depends

from backend.config import Config
from backend.repositories.event_repository import EventRepository
from backend.repositories.user_repository import UserRepository
from backend.repositories.registration_repository import RegistrationRepository
from backend.services.event_service import EventService
from backend.services.user_service import UserService
from backend.services.registration_service import RegistrationService


def get_config() -> Config:
    """Get application configuration.
    
    Returns:
        Config instance loaded from environment
    """
    return Config.from_env()


def get_dynamodb_table(config: Config = Depends(get_config)):
    """Get DynamoDB table instance.
    
    Args:
        config: Application configuration
        
    Returns:
        boto3 DynamoDB Table resource
    """
    dynamodb = boto3.resource('dynamodb')
    return dynamodb.Table(config.table_name)


def get_event_repository(table=Depends(get_dynamodb_table)) -> EventRepository:
    """Get event repository instance.
    
    Args:
        table: DynamoDB table
        
    Returns:
        EventRepository instance
    """
    return EventRepository(table)


def get_user_repository(table=Depends(get_dynamodb_table)) -> UserRepository:
    """Get user repository instance.
    
    Args:
        table: DynamoDB table
        
    Returns:
        UserRepository instance
    """
    return UserRepository(table)


def get_registration_repository(table=Depends(get_dynamodb_table)) -> RegistrationRepository:
    """Get registration repository instance.
    
    Args:
        table: DynamoDB table
        
    Returns:
        RegistrationRepository instance
    """
    return RegistrationRepository(table)


def get_event_service(repo: EventRepository = Depends(get_event_repository)) -> EventService:
    """Get event service instance.
    
    Args:
        repo: EventRepository instance
        
    Returns:
        EventService instance
    """
    return EventService(repo)


def get_user_service(repo: UserRepository = Depends(get_user_repository)) -> UserService:
    """Get user service instance.
    
    Args:
        repo: UserRepository instance
        
    Returns:
        UserService instance
    """
    return UserService(repo)


def get_registration_service(
    reg_repo: RegistrationRepository = Depends(get_registration_repository),
    event_repo: EventRepository = Depends(get_event_repository),
    user_repo: UserRepository = Depends(get_user_repository)
) -> RegistrationService:
    """Get registration service instance.
    
    Args:
        reg_repo: RegistrationRepository instance
        event_repo: EventRepository instance
        user_repo: UserRepository instance
        
    Returns:
        RegistrationService instance
    """
    return RegistrationService(reg_repo, event_repo, user_repo)
