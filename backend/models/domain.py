"""Domain models representing internal business entities."""

from dataclasses import dataclass
from typing import Optional


@dataclass
class DomainEvent:
    """Internal representation of an event."""
    event_id: str
    title: str
    description: str
    date: str
    location: str
    capacity: int
    organizer: str
    status: str
    current_registrations: int
    waitlist_enabled: bool
    created_at: str
    updated_at: str


@dataclass
class DomainUser:
    """Internal representation of a user."""
    user_id: str
    name: str
    created_at: str


@dataclass
class DomainRegistration:
    """Internal representation of a registration."""
    user_id: str
    event_id: str
    registration_status: str
    registered_at: str
