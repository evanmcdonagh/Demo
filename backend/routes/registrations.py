"""Registration API routes."""

from typing import List
from fastapi import APIRouter, HTTPException, status, Depends

from backend.models.api import Registration, RegistrationRequest, EventRegistrationRequest, Event
from backend.services.registration_service import RegistrationService
from backend.services.event_service import EventService
from backend.dependencies import get_registration_service, get_event_service
from backend.exceptions import (
    ResourceNotFoundError,
    ResourceAlreadyExistsError,
    CapacityExceededError,
    RepositoryError
)


router = APIRouter(tags=["registrations"])


@router.post("/registrations", response_model=Registration, status_code=status.HTTP_201_CREATED)
def register_user_for_event(
    registration: RegistrationRequest,
    registration_service: RegistrationService = Depends(get_registration_service)
):
    """Register a user for an event."""
    try:
        domain_registration = registration_service.register_user(
            registration.userId,
            registration.eventId
        )
        
        # Convert domain model to API model
        return Registration(
            userId=domain_registration.user_id,
            eventId=domain_registration.event_id,
            registrationStatus=domain_registration.registration_status,
            registeredAt=domain_registration.registered_at
        )
    except ResourceNotFoundError as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(e)
        )
    except ResourceAlreadyExistsError as e:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=str(e)
        )
    except CapacityExceededError as e:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=str(e)
        )
    except RepositoryError as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )


@router.delete("/registrations/{user_id}/{event_id}", status_code=status.HTTP_204_NO_CONTENT)
def unregister_user_from_event(
    user_id: str,
    event_id: str,
    registration_service: RegistrationService = Depends(get_registration_service)
):
    """Unregister a user from an event."""
    try:
        registration_service.unregister_user(user_id, event_id)
        return None
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


@router.get("/users/{user_id}/events", response_model=List[Event])
def get_user_events(
    user_id: str,
    registration_service: RegistrationService = Depends(get_registration_service)
):
    """Get all events a user is registered for."""
    try:
        domain_events = registration_service.get_user_events(user_id)
        
        # Convert domain models to API models
        return [
            Event(
                eventId=e.event_id,
                title=e.title,
                description=e.description,
                date=e.date,
                location=e.location,
                capacity=e.capacity,
                organizer=e.organizer,
                status=e.status,
                currentRegistrations=e.current_registrations,
                waitlistEnabled=e.waitlist_enabled,
                createdAt=e.created_at,
                updatedAt=e.updated_at
            )
            for e in domain_events
        ]
    except RepositoryError as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )


@router.post("/events/{event_id}/registrations", response_model=Registration, status_code=status.HTTP_201_CREATED)
def register_user_for_event_alt(
    event_id: str,
    reg_request: EventRegistrationRequest,
    registration_service: RegistrationService = Depends(get_registration_service)
):
    """Alternative endpoint: POST /events/{event_id}/registrations"""
    try:
        domain_registration = registration_service.register_user(
            reg_request.userId,
            event_id
        )
        
        # Convert domain model to API model
        return Registration(
            userId=domain_registration.user_id,
            eventId=domain_registration.event_id,
            registrationStatus=domain_registration.registration_status,
            registeredAt=domain_registration.registered_at
        )
    except ResourceNotFoundError as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(e)
        )
    except ResourceAlreadyExistsError as e:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=str(e)
        )
    except CapacityExceededError as e:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=str(e)
        )
    except RepositoryError as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )


@router.get("/events/{event_id}/registrations", response_model=List[Registration])
def get_event_registrations(
    event_id: str,
    registration_service: RegistrationService = Depends(get_registration_service)
):
    """Get all registrations for an event."""
    try:
        domain_registrations = registration_service.get_event_registrations(event_id)
        
        # Convert domain models to API models
        return [
            Registration(
                userId=r.user_id,
                eventId=r.event_id,
                registrationStatus=r.registration_status,
                registeredAt=r.registered_at
            )
            for r in domain_registrations
        ]
    except RepositoryError as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )


@router.delete("/events/{event_id}/registrations/{user_id}", status_code=status.HTTP_204_NO_CONTENT)
def unregister_user_from_event_alt(
    event_id: str,
    user_id: str,
    registration_service: RegistrationService = Depends(get_registration_service)
):
    """Alternative endpoint: DELETE /events/{event_id}/registrations/{user_id}"""
    try:
        registration_service.unregister_user(user_id, event_id)
        return None
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


@router.get("/users/{user_id}/registrations", response_model=List[Registration])
def get_user_registrations(
    user_id: str,
    registration_service: RegistrationService = Depends(get_registration_service)
):
    """Get all registrations for a user."""
    try:
        domain_registrations = registration_service.get_user_registrations(user_id)
        
        # Convert domain models to API models
        return [
            Registration(
                userId=r.user_id,
                eventId=r.event_id,
                registrationStatus=r.registration_status,
                registeredAt=r.registered_at
            )
            for r in domain_registrations
        ]
    except RepositoryError as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )
