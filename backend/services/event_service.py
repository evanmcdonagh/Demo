"""Event service for business logic."""

from typing import Dict, Any, List, Optional
import uuid

from backend.repositories.event_repository import EventRepository
from backend.models.domain import DomainEvent
from backend.exceptions import ResourceNotFoundError
from backend.utils import get_timestamp


class EventService:
    """Service for event business logic."""
    
    def __init__(self, event_repository: EventRepository):
        """Initialize event service.
        
        Args:
            event_repository: EventRepository instance
        """
        self.event_repo = event_repository
    
    def create_event(self, event_data: Dict[str, Any]) -> DomainEvent:
        """Create a new event.
        
        Args:
            event_data: Dictionary with event data
            
        Returns:
            Created DomainEvent
        """
        event_id = event_data.get('eventId') or str(uuid.uuid4())
        timestamp = get_timestamp()
        
        event = DomainEvent(
            event_id=event_id,
            title=event_data['title'],
            description=event_data['description'],
            date=event_data['date'],
            location=event_data['location'],
            capacity=event_data['capacity'],
            organizer=event_data['organizer'],
            status=event_data['status'],
            current_registrations=0,
            waitlist_enabled=event_data.get('waitlistEnabled', False),
            created_at=timestamp,
            updated_at=timestamp
        )
        
        return self.event_repo.create(event)
    
    def get_event(self, event_id: str) -> DomainEvent:
        """Get an event by ID.
        
        Args:
            event_id: Event ID
            
        Returns:
            DomainEvent
            
        Raises:
            ResourceNotFoundError: If event not found
        """
        event = self.event_repo.get_by_id(event_id)
        if not event:
            raise ResourceNotFoundError(f"Event with ID {event_id} not found")
        return event
    
    def list_events(self, status_filter: Optional[str] = None) -> List[DomainEvent]:
        """List all events, optionally filtered by status.
        
        Args:
            status_filter: Optional status to filter by
            
        Returns:
            List of DomainEvent objects
        """
        return self.event_repo.list_all(status_filter)
    
    def update_event(self, event_id: str, updates: Dict[str, Any]) -> DomainEvent:
        """Update an event.
        
        Args:
            event_id: Event ID
            updates: Dictionary of fields to update
            
        Returns:
            Updated DomainEvent
            
        Raises:
            ResourceNotFoundError: If event not found
        """
        if not updates:
            raise ValueError("No fields to update")
        
        # Add updated timestamp
        updates['updatedAt'] = get_timestamp()
        
        return self.event_repo.update(event_id, updates)
    
    def delete_event(self, event_id: str) -> None:
        """Delete an event.
        
        Args:
            event_id: Event ID
            
        Raises:
            ResourceNotFoundError: If event not found
        """
        self.event_repo.delete(event_id)
