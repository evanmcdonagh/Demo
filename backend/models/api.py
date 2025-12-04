"""API models for HTTP request and response structures."""

from datetime import datetime
from typing import Optional
from pydantic import BaseModel, Field, field_validator


class EventBase(BaseModel):
    title: str = Field(..., min_length=1, max_length=200)
    description: str = Field(..., min_length=1, max_length=2000)
    date: str = Field(..., description="Event date in ISO format (YYYY-MM-DD)")
    location: str = Field(..., min_length=1, max_length=300)
    capacity: int = Field(..., gt=0, le=100000)
    organizer: str = Field(..., min_length=1, max_length=200)
    status: str = Field(..., pattern="^(scheduled|ongoing|completed|cancelled|active)$")
    
    @field_validator('date')
    @classmethod
    def validate_date(cls, v):
        try:
            datetime.fromisoformat(v)
            return v
        except ValueError:
            raise ValueError('Date must be in ISO format (YYYY-MM-DD)')


class EventCreate(EventBase):
    eventId: Optional[str] = None
    waitlistEnabled: Optional[bool] = False


class EventUpdate(BaseModel):
    title: Optional[str] = Field(None, min_length=1, max_length=200)
    description: Optional[str] = Field(None, min_length=1, max_length=2000)
    date: Optional[str] = None
    location: Optional[str] = Field(None, min_length=1, max_length=300)
    capacity: Optional[int] = Field(None, gt=0, le=100000)
    organizer: Optional[str] = Field(None, min_length=1, max_length=200)
    status: Optional[str] = Field(None, pattern="^(scheduled|ongoing|completed|cancelled|active)$")
    waitlistEnabled: Optional[bool] = None
    
    @field_validator('date')
    @classmethod
    def validate_date(cls, v):
        if v is not None:
            try:
                datetime.fromisoformat(v)
                return v
            except ValueError:
                raise ValueError('Date must be in ISO format (YYYY-MM-DD)')
        return v


class Event(EventBase):
    eventId: str
    createdAt: str
    updatedAt: str
    currentRegistrations: Optional[int] = 0
    waitlistEnabled: bool = False


class User(BaseModel):
    userId: str = Field(..., min_length=1, max_length=100)
    name: str = Field(..., min_length=1, max_length=200)
    createdAt: Optional[str] = None


class RegistrationRequest(BaseModel):
    userId: str = Field(..., min_length=1)
    eventId: str = Field(..., min_length=1)


class Registration(BaseModel):
    userId: str
    eventId: str
    registrationStatus: str
    registeredAt: str


class EventRegistrationRequest(BaseModel):
    userId: str = Field(..., min_length=1)
