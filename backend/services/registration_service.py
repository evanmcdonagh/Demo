"""Registration service for business logic."""

from typing import List

from backend.repositories.registration_repository import RegistrationRepository
from backend.repositories.event_repository import EventRepository
from backend.repositories.user_repository import UserRepository
from backend.models.domain import DomainRegistration, DomainEvent
from backend.exceptions import ResourceNotFoundError, ResourceAlreadyExistsError, CapacityExceededError
from backend.utils import get_timestamp


class RegistrationService:
    """Service for registration business logic."""
    
    def __init__(
        self,
        registration_repository: RegistrationRepository,
        event_repository: EventRepository,
        user_repository: UserRepository
    ):
        """Initialize registration service."""
        self.registration_repo = registration_repository
        self.event_repo = event_repository
        self.user_repo = user_repository
    
    def register_user(self, user_id: str, event_id: str) -> DomainRegistration:
        """Register a user for an event."""
        # Verify user exists
        user = self.user_repo.get_by_id(user_id)
        if not user:
            raise ResourceNotFoundError(f"User with ID {user_id} not found")
        
        # Verify event exists and get details
        event = self.event_repo.get_by_id(event_id)
        if not event:
            raise ResourceNotFoundError(f"Event with ID {event_id} not found")
        
        # Check if already registered
        existing_reg = self.registration_repo.get_registration(user_id, event_id)
        if existing_reg:
            raise ResourceAlreadyExistsError("User is already registered for this event")
        
        timestamp = get_timestamp()
        registration_status = 'registered'
        
        # Check capacity
        if event.current_registrations >= event.capacity:
            if not event.waitlist_enabled:
                raise CapacityExceededError("Event is at full capacity and waitlist is not enabled")
            else:
                registration_status = 'waitlisted'
                self.registration_repo.add_to_waitlist(user_id, event_id, timestamp)
        else:
            self.event_repo.increment_registrations(event_id)
        
        # Create registration record
        registration = DomainRegistration(
            user_id=user_id,
            event_id=event_id,
            registration_status=registration_status,
            registered_at=timestamp
        )
        
        return self.registration_repo.create_registration(registration)
    
    def unregister_user(self, user_id: str, event_id: str) -> None:
        """Unregister a user from an event."""
        registration = self.registration_repo.get_registration(user_id, event_id)
        if not registration:
            raise ResourceNotFoundError("Registration not found")
        
        if registration.registration_status == 'registered':
            self.event_repo.decrement_registrations(event_id)
            
            waitlist_entry = self.registration_repo.get_first_waitlisted(event_id)
            
            if waitlist_entry:
                waitlisted_user_id = waitlist_entry['userId']
                
                self.registration_repo.update_registration_status(
                    waitlisted_user_id,
                    event_id,
                    'registered'
                )
                
                self.registration_repo.remove_from_waitlist(
                    waitlist_entry['PK'],
                    waitlist_entry['SK']
                )
                
                self.event_repo.increment_registrations(event_id)
        
        self.registration_repo.delete_registration(user_id, event_id)
    
    def get_user_events(self, user_id: str) -> List[DomainEvent]:
        """Get all events a user is registered for."""
        registrations = self.registration_repo.list_user_registrations(user_id)
        
        registered_event_ids = [
            reg.event_id for reg in registrations
            if reg.registration_status == 'registered'
        ]
        
        if not registered_event_ids:
            return []
        
        events = []
        for event_id in registered_event_ids:
            event = self.event_repo.get_by_id(event_id)
            if event:
                events.append(event)
        
        return events
    
    def get_event_registrations(self, event_id: str) -> List[DomainRegistration]:
        """Get all registrations for an event."""
        return self.registration_repo.list_event_registrations(event_id)
    
    def get_user_registrations(self, user_id: str) -> List[DomainRegistration]:
        """Get all registrations for a user."""
        return self.registration_repo.list_user_registrations(user_id)
