"""Event repository for data access operations."""

from typing import Optional, List, Dict, Any
from botocore.exceptions import ClientError
from boto3.dynamodb.conditions import Attr

from backend.repositories.base import BaseRepository
from backend.models.domain import DomainEvent
from backend.exceptions import ResourceNotFoundError, RepositoryError


class EventRepository(BaseRepository):
    """Repository for event data access."""
    
    def create(self, event: DomainEvent) -> DomainEvent:
        """Create a new event.
        
        Args:
            event: DomainEvent to create
            
        Returns:
            Created DomainEvent
            
        Raises:
            RepositoryError: If database operation fails
        """
        try:
            self.table.put_item(
                Item={
                    'PK': f'EVENT#{event.event_id}',
                    'SK': 'METADATA',
                    'eventId': event.event_id,
                    'title': event.title,
                    'description': event.description,
                    'date': event.date,
                    'location': event.location,
                    'capacity': event.capacity,
                    'organizer': event.organizer,
                    'status': event.status,
                    'currentRegistrations': event.current_registrations,
                    'waitlistEnabled': event.waitlist_enabled,
                    'createdAt': event.created_at,
                    'updatedAt': event.updated_at
                }
            )
            return event
        except ClientError as e:
            raise RepositoryError(f"Failed to create event: {str(e)}")
    
    def get_by_id(self, event_id: str) -> Optional[DomainEvent]:
        """Get event by ID.
        
        Args:
            event_id: Event ID
            
        Returns:
            DomainEvent if found, None otherwise
            
        Raises:
            RepositoryError: If database operation fails
        """
        try:
            response = self.table.get_item(
                Key={
                    'PK': f'EVENT#{event_id}',
                    'SK': 'METADATA'
                }
            )
            
            if 'Item' not in response:
                return None
            
            item = response['Item']
            return DomainEvent(
                event_id=item['eventId'],
                title=item['title'],
                description=item['description'],
                date=item['date'],
                location=item['location'],
                capacity=item['capacity'],
                organizer=item['organizer'],
                status=item['status'],
                current_registrations=item.get('currentRegistrations', 0),
                waitlist_enabled=item.get('waitlistEnabled', False),
                created_at=item['createdAt'],
                updated_at=item['updatedAt']
            )
        except ClientError as e:
            raise RepositoryError(f"Failed to get event: {str(e)}")
    
    def list_all(self, status_filter: Optional[str] = None) -> List[DomainEvent]:
        """List all events, optionally filtered by status.
        
        Args:
            status_filter: Optional status to filter by
            
        Returns:
            List of DomainEvent objects
            
        Raises:
            RepositoryError: If database operation fails
        """
        try:
            if status_filter:
                response = self.table.scan(
                    FilterExpression=Attr('SK').eq('METADATA') & Attr('status').eq(status_filter)
                )
            else:
                response = self.table.scan(
                    FilterExpression=Attr('SK').eq('METADATA')
                )
            
            items = response.get('Items', [])
            
            # Handle pagination
            while 'LastEvaluatedKey' in response:
                if status_filter:
                    response = self.table.scan(
                        ExclusiveStartKey=response['LastEvaluatedKey'],
                        FilterExpression=Attr('SK').eq('METADATA') & Attr('status').eq(status_filter)
                    )
                else:
                    response = self.table.scan(
                        ExclusiveStartKey=response['LastEvaluatedKey'],
                        FilterExpression=Attr('SK').eq('METADATA')
                    )
                items.extend(response.get('Items', []))
            
            return [
                DomainEvent(
                    event_id=item['eventId'],
                    title=item['title'],
                    description=item['description'],
                    date=item['date'],
                    location=item['location'],
                    capacity=item['capacity'],
                    organizer=item['organizer'],
                    status=item['status'],
                    current_registrations=item.get('currentRegistrations', 0),
                    waitlist_enabled=item.get('waitlistEnabled', False),
                    created_at=item['createdAt'],
                    updated_at=item['updatedAt']
                )
                for item in items
            ]
        except ClientError as e:
            raise RepositoryError(f"Failed to list events: {str(e)}")
    
    def update(self, event_id: str, updates: Dict[str, Any]) -> DomainEvent:
        """Update an event.
        
        Args:
            event_id: Event ID
            updates: Dictionary of fields to update
            
        Returns:
            Updated DomainEvent
            
        Raises:
            ResourceNotFoundError: If event not found
            RepositoryError: If database operation fails
        """
        try:
            # Check if event exists
            existing = self.get_by_id(event_id)
            if not existing:
                raise ResourceNotFoundError(f"Event with ID {event_id} not found")
            
            # Build update expression with reserved keyword handling
            reserved_keywords = {'date', 'location', 'capacity', 'status', 'name'}
            update_expression_parts = []
            expression_attribute_names = {}
            expression_attribute_values = {}
            
            for k, v in updates.items():
                if k in reserved_keywords:
                    update_expression_parts.append(f"#{k} = :{k}")
                    expression_attribute_names[f"#{k}"] = k
                else:
                    update_expression_parts.append(f"#{k} = :{k}")
                    expression_attribute_names[f"#{k}"] = k
                expression_attribute_values[f":{k}"] = v
            
            update_expression = "SET " + ", ".join(update_expression_parts)
            
            response = self.table.update_item(
                Key={
                    'PK': f'EVENT#{event_id}',
                    'SK': 'METADATA'
                },
                UpdateExpression=update_expression,
                ExpressionAttributeNames=expression_attribute_names,
                ExpressionAttributeValues=expression_attribute_values,
                ReturnValues="ALL_NEW"
            )
            
            item = response['Attributes']
            return DomainEvent(
                event_id=item['eventId'],
                title=item['title'],
                description=item['description'],
                date=item['date'],
                location=item['location'],
                capacity=item['capacity'],
                organizer=item['organizer'],
                status=item['status'],
                current_registrations=item.get('currentRegistrations', 0),
                waitlist_enabled=item.get('waitlistEnabled', False),
                created_at=item['createdAt'],
                updated_at=item['updatedAt']
            )
        except ResourceNotFoundError:
            raise
        except ClientError as e:
            raise RepositoryError(f"Failed to update event: {str(e)}")
    
    def delete(self, event_id: str) -> None:
        """Delete an event.
        
        Args:
            event_id: Event ID
            
        Raises:
            ResourceNotFoundError: If event not found
            RepositoryError: If database operation fails
        """
        try:
            # Check if event exists
            existing = self.get_by_id(event_id)
            if not existing:
                raise ResourceNotFoundError(f"Event with ID {event_id} not found")
            
            self.table.delete_item(
                Key={
                    'PK': f'EVENT#{event_id}',
                    'SK': 'METADATA'
                }
            )
        except ResourceNotFoundError:
            raise
        except ClientError as e:
            raise RepositoryError(f"Failed to delete event: {str(e)}")
    
    def increment_registrations(self, event_id: str) -> None:
        """Increment the registration count for an event.
        
        Args:
            event_id: Event ID
            
        Raises:
            RepositoryError: If database operation fails
        """
        try:
            self.table.update_item(
                Key={
                    'PK': f'EVENT#{event_id}',
                    'SK': 'METADATA'
                },
                UpdateExpression='SET currentRegistrations = currentRegistrations + :inc',
                ExpressionAttributeValues={':inc': 1}
            )
        except ClientError as e:
            raise RepositoryError(f"Failed to increment registrations: {str(e)}")
    
    def decrement_registrations(self, event_id: str) -> None:
        """Decrement the registration count for an event.
        
        Args:
            event_id: Event ID
            
        Raises:
            RepositoryError: If database operation fails
        """
        try:
            self.table.update_item(
                Key={
                    'PK': f'EVENT#{event_id}',
                    'SK': 'METADATA'
                },
                UpdateExpression='SET currentRegistrations = currentRegistrations - :dec',
                ExpressionAttributeValues={':dec': 1}
            )
        except ClientError as e:
            raise RepositoryError(f"Failed to decrement registrations: {str(e)}")
