import os
from datetime import datetime
from typing import Optional, List
from fastapi import FastAPI, HTTPException, status, Query
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field, field_validator
from mangum import Mangum
import boto3
from boto3.dynamodb.conditions import Attr
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

class EventUpdate(BaseModel):
    title: Optional[str] = Field(None, min_length=1, max_length=200)
    description: Optional[str] = Field(None, min_length=1, max_length=2000)
    date: Optional[str] = None
    location: Optional[str] = Field(None, min_length=1, max_length=300)
    capacity: Optional[int] = Field(None, gt=0, le=100000)
    organizer: Optional[str] = Field(None, min_length=1, max_length=200)
    status: Optional[str] = Field(None, pattern="^(scheduled|ongoing|completed|cancelled|active)$")
    
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

def get_timestamp():
    return datetime.utcnow().isoformat()

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
            'eventId': event_id,
            'title': event.title,
            'description': event.description,
            'date': event.date,
            'location': event.location,
            'capacity': event.capacity,
            'organizer': event.organizer,
            'status': event.status,
            'createdAt': timestamp,
            'updatedAt': timestamp
        }
        
        table.put_item(Item=item)
        return Event(**item)
    except ClientError as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to create event: {str(e)}"
        )

@app.get("/events", response_model=List[Event])
def list_events(status_filter: Optional[str] = Query(None, alias="status")):
    try:
        if status_filter:
            response = table.scan(FilterExpression=Attr('status').eq(status_filter))
        else:
            response = table.scan()
        
        items = response.get('Items', [])
        
        while 'LastEvaluatedKey' in response:
            if status_filter:
                response = table.scan(
                    ExclusiveStartKey=response['LastEvaluatedKey'],
                    FilterExpression=Attr('status').eq(status_filter)
                )
            else:
                response = table.scan(ExclusiveStartKey=response['LastEvaluatedKey'])
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
        response = table.get_item(Key={'eventId': event_id})
        
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
        response = table.get_item(Key={'eventId': event_id})
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
        
        update_expression = "SET " + ", ".join([f"#{k} = :{k}" for k in update_data.keys()])
        expression_attribute_names = {f"#{k}": k for k in update_data.keys()}
        expression_attribute_values = {f":{k}": v for k, v in update_data.items()}
        
        response = table.update_item(
            Key={'eventId': event_id},
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
        response = table.get_item(Key={'eventId': event_id})
        if 'Item' not in response:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Event with ID {event_id} not found"
            )
        
        table.delete_item(Key={'eventId': event_id})
        return None
    except ClientError as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to delete event: {str(e)}"
        )

handler = Mangum(app)
