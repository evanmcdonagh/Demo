"""Event API routes."""

from typing import List, Optional
from fastapi import APIRouter, HTTPException, status, Query, Depends

from backend.models.api import Event, EventCreate, EventUpdate
from backend.services.event_service import EventService
from backend.dependencies import get_event_service
from backend.exceptions import ResourceNotFoundError, RepositoryError


router = APIRouter(prefix="/events", tags=["events"])


@router.post("", response_model=Event, status_code=status.HTTP_201_CREATED)
def create_event(
    event: EventCreate,
    event_service: EventService = Depends(get_event_service)
):
    """Create a new event."""
    try:
        event_data = event.model_dump()
        domain_event = event_service.create_event(event_data)
        
        # Convert domain model to API model
        return Event(
            eventId=domain_event.event_id,
            title=domain_event.title,
            description=domain_event.description,
            date=domain_event.date,
            location=domain_event.location,
            capacity=domain_event.capacity,
            organizer=domain_event.organizer,
            status=domain_event.status,
            currentRegistrations=domain_event.current_registrations,
            waitlistEnabled=domain_event.waitlist_enabled,
            createdAt=domain_event.created_at,
            updatedAt=domain_event.updated_at
        )
    except RepositoryError as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )


@router.get("", response_model=List[Event])
def list_events(
    status_filter: Optional[str] = Query(None, alias="status"),
    event_service: EventService = Depends(get_event_service)
):
    """List all events, optionally filtered by status."""
    try:
        domain_events = event_service.list_events(status_filter)
        
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


@router.get("/{event_id}", response_model=Event)
def get_event(
    event_id: str,
    event_service: EventService = Depends(get_event_service)
):
    """Get an event by ID."""
    try:
        domain_event = event_service.get_event(event_id)
        
        # Convert domain model to API model
        return Event(
            eventId=domain_event.event_id,
            title=domain_event.title,
            description=domain_event.description,
            date=domain_event.date,
            location=domain_event.location,
            capacity=domain_event.capacity,
            organizer=domain_event.organizer,
            status=domain_event.status,
            currentRegistrations=domain_event.current_registrations,
            waitlistEnabled=domain_event.waitlist_enabled,
            createdAt=domain_event.created_at,
            updatedAt=domain_event.updated_at
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


@router.put("/{event_id}", response_model=Event)
def update_event(
    event_id: str,
    event_update: EventUpdate,
    event_service: EventService = Depends(get_event_service)
):
    """Update an event."""
    try:
        update_data = event_update.model_dump(exclude_unset=True)
        
        if not update_data:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="No fields to update"
            )
        
        domain_event = event_service.update_event(event_id, update_data)
        
        # Convert domain model to API model
        return Event(
            eventId=domain_event.event_id,
            title=domain_event.title,
            description=domain_event.description,
            date=domain_event.date,
            location=domain_event.location,
            capacity=domain_event.capacity,
            organizer=domain_event.organizer,
            status=domain_event.status,
            currentRegistrations=domain_event.current_registrations,
            waitlistEnabled=domain_event.waitlist_enabled,
            createdAt=domain_event.created_at,
            updatedAt=domain_event.updated_at
        )
    except ResourceNotFoundError as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(e)
        )
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
    except RepositoryError as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )


@router.delete("/{event_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_event(
    event_id: str,
    event_service: EventService = Depends(get_event_service)
):
    """Delete an event."""
    try:
        event_service.delete_event(event_id)
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
