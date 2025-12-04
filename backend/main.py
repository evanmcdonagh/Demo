import os
from datetime import datetime
from typing import Optional, List
from fastapi import FastAPI, HTTPException, status, Query
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field, field_validator
from mangum import Mangum
import boto3
from boto3.dynamodb.conditions import Attr, Key
from botocore.exceptions import ClientError
import uuid

app = FastAPI(title="Events API", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

dynamodb = boto3.resource('dynamodb')
table_name = os.environ.get('EVENTS_TABLE_NAME', 'EventsTable')
table = dynamodb.Table(table_name)

# ============================================================================
# Data Models
# ============================================================================

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

# ============================================================================
# Helper Functions
# ============================================================================

def get_timestamp():
    return datetime.utcnow().isoformat()

# ============================================================================
# Event Endpoints (Updated for composite keys)
# ============================================================================

@app.get("/")
def read_root():
    return {"message": "Events API is running", "version": "1.0.0"}

@app.get("/health")
def health_check():
    return {"status": "healthy"}

@app.post("/events", response_model=Event, status_code=status.HTTP_201_CREATED)
def create_event(event: EventCreate):
    try:
        event_id = event.eventId if event.eventId else str(uuid.uuid4())
        timestamp = get_timestamp()
        
        item = {
            'PK': f'EVENT#{event_id}',
            'SK': 'METADATA',
            'eventId': event_id,
            'title': event.title,
            'description': event.description,
            '#date': event.date,  # date is reserved
            '#location': event.location,  # location is reserved
            '#capacity': event.capacity,  # capacity is reserved
            'organizer': event.organizer,
            '#status': event.status,  # status is reserved
            'currentRegistrations': 0,
            'waitlistEnabled': event.waitlistEnabled,
            'createdAt': timestamp,
            'updatedAt': timestamp
        }
        
        # Use expression attribute names for reserved keywords
        table.put_item(
            Item={
                'PK': item['PK'],
                'SK': item['SK'],
                'eventId': item['eventId'],
                'title': item['title'],
                'description': item['description'],
                'date': event.date,
                'location': event.location,
                'capacity': event.capacity,
                'organizer': item['organizer'],
                'status': event.status,
                'currentRegistrations': item['currentRegistrations'],
                'waitlistEnabled': item['waitlistEnabled'],
                'createdAt': item['createdAt'],
                'updatedAt': item['updatedAt']
            }
        )
        
        return Event(
            eventId=event_id,
            title=event.title,
            description=event.description,
            date=event.date,
            location=event.location,
            capacity=event.capacity,
            organizer=event.organizer,
            status=event.status,
            currentRegistrations=0,
            waitlistEnabled=event.waitlistEnabled,
            createdAt=timestamp,
            updatedAt=timestamp
        )
    except ClientError as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to create event: {str(e)}"
        )

@app.get("/events", response_model=List[Event])
def list_events(status_filter: Optional[str] = Query(None, alias="status")):
    try:
        # Scan for all items where SK = 'METADATA' (events)
        if status_filter:
            response = table.scan(
                FilterExpression=Attr('SK').eq('METADATA') & Attr('status').eq(status_filter)
            )
        else:
            response = table.scan(
                FilterExpression=Attr('SK').eq('METADATA')
            )
        
        items = response.get('Items', [])
        
        while 'LastEvaluatedKey' in response:
            if status_filter:
                response = table.scan(
                    ExclusiveStartKey=response['LastEvaluatedKey'],
                    FilterExpression=Attr('SK').eq('METADATA') & Attr('status').eq(status_filter)
                )
            else:
                response = table.scan(
                    ExclusiveStartKey=response['LastEvaluatedKey'],
                    FilterExpression=Attr('SK').eq('METADATA')
                )
            items.extend(response.get('Items', []))
        
        return [Event(**item) for item in items]
    except ClientError as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to list events: {str(e)}"
        )

@app.get("/events/{event_id}", response_model=Event)
def get_event(event_id: str):
    try:
        response = table.get_item(
            Key={
                'PK': f'EVENT#{event_id}',
                'SK': 'METADATA'
            }
        )
        
        if 'Item' not in response:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Event with ID {event_id} not found"
            )
        
        return Event(**response['Item'])
    except ClientError as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get event: {str(e)}"
        )

@app.put("/events/{event_id}", response_model=Event)
def update_event(event_id: str, event_update: EventUpdate):
    try:
        response = table.get_item(
            Key={
                'PK': f'EVENT#{event_id}',
                'SK': 'METADATA'
            }
        )
        if 'Item' not in response:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Event with ID {event_id} not found"
            )
        
        update_data = event_update.model_dump(exclude_unset=True)
        if not update_data:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="No fields to update"
            )
        
        update_data['updatedAt'] = get_timestamp()
        
        # Map reserved keywords
        reserved_keywords = {'date', 'location', 'capacity', 'status', 'name'}
        update_expression_parts = []
        expression_attribute_names = {}
        expression_attribute_values = {}
        
        for k, v in update_data.items():
            if k in reserved_keywords:
                update_expression_parts.append(f"#{k} = :{k}")
                expression_attribute_names[f"#{k}"] = k
            else:
                update_expression_parts.append(f"#{k} = :{k}")
                expression_attribute_names[f"#{k}"] = k
            expression_attribute_values[f":{k}"] = v
        
        update_expression = "SET " + ", ".join(update_expression_parts)
        
        response = table.update_item(
            Key={
                'PK': f'EVENT#{event_id}',
                'SK': 'METADATA'
            },
            UpdateExpression=update_expression,
            ExpressionAttributeNames=expression_attribute_names,
            ExpressionAttributeValues=expression_attribute_values,
            ReturnValues="ALL_NEW"
        )
        
        return Event(**response['Attributes'])
    except ClientError as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to update event: {str(e)}"
        )

@app.delete("/events/{event_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_event(event_id: str):
    try:
        response = table.get_item(
            Key={
                'PK': f'EVENT#{event_id}',
                'SK': 'METADATA'
            }
        )
        if 'Item' not in response:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Event with ID {event_id} not found"
            )
        
        table.delete_item(
            Key={
                'PK': f'EVENT#{event_id}',
                'SK': 'METADATA'
            }
        )
        return None
    except ClientError as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to delete event: {str(e)}"
        )

# ============================================================================
# User Endpoints
# ============================================================================

@app.post("/users", response_model=User, status_code=status.HTTP_201_CREATED)
def create_user(user: User):
    try:
        # Check if user already exists
        response = table.get_item(
            Key={
                'PK': f'USER#{user.userId}',
                'SK': 'PROFILE'
            }
        )
        
        if 'Item' in response:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail=f"User with ID {user.userId} already exists"
            )
        
        timestamp = get_timestamp()
        
        table.put_item(
            Item={
                'PK': f'USER#{user.userId}',
                'SK': 'PROFILE',
                'userId': user.userId,
                'name': user.name,
                'createdAt': timestamp
            },
            ConditionExpression='attribute_not_exists(PK)'
        )
        
        return User(userId=user.userId, name=user.name, createdAt=timestamp)
    except ClientError as e:
        if e.response['Error']['Code'] == 'ConditionalCheckFailedException':
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail=f"User with ID {user.userId} already exists"
            )
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to create user: {str(e)}"
        )

@app.get("/users/{user_id}", response_model=User)
def get_user(user_id: str):
    try:
        response = table.get_item(
            Key={
                'PK': f'USER#{user_id}',
                'SK': 'PROFILE'
            }
        )
        
        if 'Item' not in response:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"User with ID {user_id} not found"
            )
        
        return User(**response['Item'])
    except ClientError as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get user: {str(e)}"
        )

# ============================================================================
# Registration Endpoints
# ============================================================================

@app.post("/registrations", response_model=Registration, status_code=status.HTTP_201_CREATED)
def register_user_for_event(registration: RegistrationRequest):
    try:
        # Check if user exists
        user_response = table.get_item(
            Key={
                'PK': f'USER#{registration.userId}',
                'SK': 'PROFILE'
            }
        )
        if 'Item' not in user_response:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"User with ID {registration.userId} not found"
            )
        
        # Check if event exists and get current registrations
        event_response = table.get_item(
            Key={
                'PK': f'EVENT#{registration.eventId}',
                'SK': 'METADATA'
            }
        )
        if 'Item' not in event_response:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Event with ID {registration.eventId} not found"
            )
        
        event = event_response['Item']
        current_registrations = event.get('currentRegistrations', 0)
        capacity = event.get('capacity', 0)
        waitlist_enabled = event.get('waitlistEnabled', False)
        
        # Check if user is already registered
        existing_reg = table.get_item(
            Key={
                'PK': f'USER#{registration.userId}',
                'SK': f'EVENT#{registration.eventId}'
            }
        )
        if 'Item' in existing_reg:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail=f"User is already registered for this event"
            )
        
        timestamp = get_timestamp()
        registration_status = 'registered'
        
        # Check capacity
        if current_registrations >= capacity:
            if not waitlist_enabled:
                raise HTTPException(
                    status_code=status.HTTP_409_CONFLICT,
                    detail=f"Event is at full capacity and waitlist is not enabled"
                )
            else:
                # Add to waitlist
                registration_status = 'waitlisted'
                table.put_item(
                    Item={
                        'PK': f'EVENT#{registration.eventId}',
                        'SK': f'WAITLIST#{timestamp}#{registration.userId}',
                        'userId': registration.userId,
                        'eventId': registration.eventId,
                        'addedAt': timestamp
                    }
                )
        else:
            # Register user and increment count
            table.update_item(
                Key={
                    'PK': f'EVENT#{registration.eventId}',
                    'SK': 'METADATA'
                },
                UpdateExpression='SET currentRegistrations = currentRegistrations + :inc',
                ExpressionAttributeValues={':inc': 1}
            )
        
        # Create registration record
        table.put_item(
            Item={
                'PK': f'USER#{registration.userId}',
                'SK': f'EVENT#{registration.eventId}',
                'userId': registration.userId,
                'eventId': registration.eventId,
                'registrationStatus': registration_status,
                'registeredAt': timestamp
            }
        )
        
        # Also create reverse lookup for event -> users
        table.put_item(
            Item={
                'PK': f'EVENT#{registration.eventId}',
                'SK': f'REGISTRATION#{registration.userId}',
                'userId': registration.userId,
                'eventId': registration.eventId,
                'registrationStatus': registration_status,
                'registeredAt': timestamp
            }
        )
        
        return Registration(
            userId=registration.userId,
            eventId=registration.eventId,
            registrationStatus=registration_status,
            registeredAt=timestamp
        )
    except HTTPException:
        raise
    except ClientError as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to register user: {str(e)}"
        )

@app.delete("/registrations/{user_id}/{event_id}", status_code=status.HTTP_204_NO_CONTENT)
def unregister_user_from_event(user_id: str, event_id: str):
    try:
        # Check if registration exists
        reg_response = table.get_item(
            Key={
                'PK': f'USER#{user_id}',
                'SK': f'EVENT#{event_id}'
            }
        )
        if 'Item' not in reg_response:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Registration not found"
            )
        
        registration = reg_response['Item']
        
        # Only decrement if user was registered (not waitlisted)
        if registration.get('registrationStatus') == 'registered':
            # Decrement event registration count
            table.update_item(
                Key={
                    'PK': f'EVENT#{event_id}',
                    'SK': 'METADATA'
                },
                UpdateExpression='SET currentRegistrations = currentRegistrations - :dec',
                ExpressionAttributeValues={':dec': 1}
            )
            
            # Check for waitlist and promote first user
            waitlist_response = table.query(
                KeyConditionExpression=Key('PK').eq(f'EVENT#{event_id}') & Key('SK').begins_with('WAITLIST#'),
                Limit=1
            )
            
            if waitlist_response.get('Items'):
                waitlist_entry = waitlist_response['Items'][0]
                waitlisted_user_id = waitlist_entry['userId']
                
                # Update waitlisted user to registered
                table.update_item(
                    Key={
                        'PK': f'USER#{waitlisted_user_id}',
                        'SK': f'EVENT#{event_id}'
                    },
                    UpdateExpression='SET registrationStatus = :status',
                    ExpressionAttributeValues={':status': 'registered'}
                )
                
                # Update reverse lookup
                table.update_item(
                    Key={
                        'PK': f'EVENT#{event_id}',
                        'SK': f'REGISTRATION#{waitlisted_user_id}'
                    },
                    UpdateExpression='SET registrationStatus = :status',
                    ExpressionAttributeValues={':status': 'registered'}
                )
                
                # Remove from waitlist
                table.delete_item(
                    Key={
                        'PK': waitlist_entry['PK'],
                        'SK': waitlist_entry['SK']
                    }
                )
                
                # Increment count back (since we promoted someone)
                table.update_item(
                    Key={
                        'PK': f'EVENT#{event_id}',
                        'SK': 'METADATA'
                    },
                    UpdateExpression='SET currentRegistrations = currentRegistrations + :inc',
                    ExpressionAttributeValues={':inc': 1}
                )
        
        # Delete registration record
        table.delete_item(
            Key={
                'PK': f'USER#{user_id}',
                'SK': f'EVENT#{event_id}'
            }
        )
        
        # Delete reverse lookup
        table.delete_item(
            Key={
                'PK': f'EVENT#{event_id}',
                'SK': f'REGISTRATION#{user_id}'
            }
        )
        
        return None
    except HTTPException:
        raise
    except ClientError as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to unregister user: {str(e)}"
        )

@app.get("/users/{user_id}/events", response_model=List[Event])
def get_user_events(user_id: str):
    try:
        # Query all registrations for user
        response = table.query(
            KeyConditionExpression=Key('PK').eq(f'USER#{user_id}') & Key('SK').begins_with('EVENT#')
        )
        
        registrations = response.get('Items', [])
        
        # Filter for only registered events (not waitlisted)
        registered_event_ids = [
            reg['eventId'] for reg in registrations 
            if reg.get('registrationStatus') == 'registered'
        ]
        
        if not registered_event_ids:
            return []
        
        # Fetch event details
        events = []
        for event_id in registered_event_ids:
            event_response = table.get_item(
                Key={
                    'PK': f'EVENT#{event_id}',
                    'SK': 'METADATA'
                }
            )
            if 'Item' in event_response:
                events.append(Event(**event_response['Item']))
        
        return events
    except ClientError as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get user events: {str(e)}"
        )

# ============================================================================
# Alternative Registration Endpoints (Event-centric)
# ============================================================================

class EventRegistrationRequest(BaseModel):
    userId: str = Field(..., min_length=1)

@app.post("/events/{event_id}/registrations", response_model=Registration, status_code=status.HTTP_201_CREATED)
def register_user_for_event_alt(event_id: str, reg_request: EventRegistrationRequest):
    """Alternative endpoint: POST /events/{event_id}/registrations"""
    registration = RegistrationRequest(userId=reg_request.userId, eventId=event_id)
    return register_user_for_event(registration)

@app.get("/events/{event_id}/registrations", response_model=List[Registration])
def get_event_registrations(event_id: str):
    """Get all registrations for an event"""
    try:
        # Query all registrations for event
        response = table.query(
            KeyConditionExpression=Key('PK').eq(f'EVENT#{event_id}') & Key('SK').begins_with('REGISTRATION#')
        )
        
        registrations = response.get('Items', [])
        
        return [Registration(**reg) for reg in registrations]
    except ClientError as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get event registrations: {str(e)}"
        )

@app.delete("/events/{event_id}/registrations/{user_id}", status_code=status.HTTP_204_NO_CONTENT)
def unregister_user_from_event_alt(event_id: str, user_id: str):
    """Alternative endpoint: DELETE /events/{event_id}/registrations/{user_id}"""
    return unregister_user_from_event(user_id, event_id)

@app.get("/users/{user_id}/registrations", response_model=List[Registration])
def get_user_registrations(user_id: str):
    """Get all registrations for a user"""
    try:
        # Query all registrations for user
        response = table.query(
            KeyConditionExpression=Key('PK').eq(f'USER#{user_id}') & Key('SK').begins_with('EVENT#')
        )
        
        registrations = response.get('Items', [])
        
        return [Registration(**reg) for reg in registrations]
    except ClientError as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get user registrations: {str(e)}"
        )

handler = Mangum(app)
