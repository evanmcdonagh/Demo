"""Registration repository for data access operations."""

from typing import Optional, List, Dict, Any
from botocore.exceptions import ClientError
from boto3.dynamodb.conditions import Key

from backend.repositories.base import BaseRepository
from backend.models.domain import DomainRegistration
from backend.exceptions import RepositoryError


class RegistrationRepository(BaseRepository):
    """Repository for registration data access."""
    
    def create_registration(self, registration: DomainRegistration) -> DomainRegistration:
        """Create a new registration.
        
        Args:
            registration: DomainRegistration to create
            
        Returns:
            Created DomainRegistration
            
        Raises:
            RepositoryError: If database operation fails
        """
        try:
            # Create user -> event lookup
            self.table.put_item(
                Item={
                    'PK': f'USER#{registration.user_id}',
                    'SK': f'EVENT#{registration.event_id}',
                    'userId': registration.user_id,
                    'eventId': registration.event_id,
                    'registrationStatus': registration.registration_status,
                    'registeredAt': registration.registered_at
                }
            )
            
            # Create event -> user lookup
            self.table.put_item(
                Item={
                    'PK': f'EVENT#{registration.event_id}',
                    'SK': f'REGISTRATION#{registration.user_id}',
                    'userId': registration.user_id,
                    'eventId': registration.event_id,
                    'registrationStatus': registration.registration_status,
                    'registeredAt': registration.registered_at
                }
            )
            
            return registration
        except ClientError as e:
            raise RepositoryError(f"Failed to create registration: {str(e)}")
    
    def get_registration(self, user_id: str, event_id: str) -> Optional[DomainRegistration]:
        """Get registration by user and event ID.
        
        Args:
            user_id: User ID
            event_id: Event ID
            
        Returns:
            DomainRegistration if found, None otherwise
            
        Raises:
            RepositoryError: If database operation fails
        """
        try:
            response = self.table.get_item(
                Key={
                    'PK': f'USER#{user_id}',
                    'SK': f'EVENT#{event_id}'
                }
            )
            
            if 'Item' not in response:
                return None
            
            item = response['Item']
            return DomainRegistration(
                user_id=item['userId'],
                event_id=item['eventId'],
                registration_status=item['registrationStatus'],
                registered_at=item['registeredAt']
            )
        except ClientError as e:
            raise RepositoryError(f"Failed to get registration: {str(e)}")
    
    def delete_registration(self, user_id: str, event_id: str) -> None:
        """Delete a registration.
        
        Args:
            user_id: User ID
            event_id: Event ID
            
        Raises:
            RepositoryError: If database operation fails
        """
        try:
            # Delete user -> event lookup
            self.table.delete_item(
                Key={
                    'PK': f'USER#{user_id}',
                    'SK': f'EVENT#{event_id}'
                }
            )
            
            # Delete event -> user lookup
            self.table.delete_item(
                Key={
                    'PK': f'EVENT#{event_id}',
                    'SK': f'REGISTRATION#{user_id}'
                }
            )
        except ClientError as e:
            raise RepositoryError(f"Failed to delete registration: {str(e)}")
    
    def list_user_registrations(self, user_id: str) -> List[DomainRegistration]:
        """List all registrations for a user.
        
        Args:
            user_id: User ID
            
        Returns:
            List of DomainRegistration objects
            
        Raises:
            RepositoryError: If database operation fails
        """
        try:
            response = self.table.query(
                KeyConditionExpression=Key('PK').eq(f'USER#{user_id}') & Key('SK').begins_with('EVENT#')
            )
            
            items = response.get('Items', [])
            
            return [
                DomainRegistration(
                    user_id=item['userId'],
                    event_id=item['eventId'],
                    registration_status=item['registrationStatus'],
                    registered_at=item['registeredAt']
                )
                for item in items
            ]
        except ClientError as e:
            raise RepositoryError(f"Failed to list user registrations: {str(e)}")
    
    def list_event_registrations(self, event_id: str) -> List[DomainRegistration]:
        """List all registrations for an event.
        
        Args:
            event_id: Event ID
            
        Returns:
            List of DomainRegistration objects
            
        Raises:
            RepositoryError: If database operation fails
        """
        try:
            response = self.table.query(
                KeyConditionExpression=Key('PK').eq(f'EVENT#{event_id}') & Key('SK').begins_with('REGISTRATION#')
            )
            
            items = response.get('Items', [])
            
            return [
                DomainRegistration(
                    user_id=item['userId'],
                    event_id=item['eventId'],
                    registration_status=item['registrationStatus'],
                    registered_at=item['registeredAt']
                )
                for item in items
            ]
        except ClientError as e:
            raise RepositoryError(f"Failed to list event registrations: {str(e)}")
    
    def add_to_waitlist(self, user_id: str, event_id: str, timestamp: str) -> None:
        """Add a user to the event waitlist.
        
        Args:
            user_id: User ID
            event_id: Event ID
            timestamp: Timestamp for waitlist ordering
            
        Raises:
            RepositoryError: If database operation fails
        """
        try:
            self.table.put_item(
                Item={
                    'PK': f'EVENT#{event_id}',
                    'SK': f'WAITLIST#{timestamp}#{user_id}',
                    'userId': user_id,
                    'eventId': event_id,
                    'addedAt': timestamp
                }
            )
        except ClientError as e:
            raise RepositoryError(f"Failed to add to waitlist: {str(e)}")
    
    def get_first_waitlisted(self, event_id: str) -> Optional[Dict[str, Any]]:
        """Get the first user on the waitlist for an event.
        
        Args:
            event_id: Event ID
            
        Returns:
            Dictionary with waitlist entry data if found, None otherwise
            
        Raises:
            RepositoryError: If database operation fails
        """
        try:
            response = self.table.query(
                KeyConditionExpression=Key('PK').eq(f'EVENT#{event_id}') & Key('SK').begins_with('WAITLIST#'),
                Limit=1
            )
            
            items = response.get('Items', [])
            return items[0] if items else None
        except ClientError as e:
            raise RepositoryError(f"Failed to get first waitlisted: {str(e)}")
    
    def remove_from_waitlist(self, pk: str, sk: str) -> None:
        """Remove an entry from the waitlist.
        
        Args:
            pk: Partition key
            sk: Sort key
            
        Raises:
            RepositoryError: If database operation fails
        """
        try:
            self.table.delete_item(
                Key={
                    'PK': pk,
                    'SK': sk
                }
            )
        except ClientError as e:
            raise RepositoryError(f"Failed to remove from waitlist: {str(e)}")
    
    def update_registration_status(self, user_id: str, event_id: str, status: str) -> None:
        """Update the status of a registration.
        
        Args:
            user_id: User ID
            event_id: Event ID
            status: New registration status
            
        Raises:
            RepositoryError: If database operation fails
        """
        try:
            # Update user -> event lookup
            self.table.update_item(
                Key={
                    'PK': f'USER#{user_id}',
                    'SK': f'EVENT#{event_id}'
                },
                UpdateExpression='SET registrationStatus = :status',
                ExpressionAttributeValues={':status': status}
            )
            
            # Update event -> user lookup
            self.table.update_item(
                Key={
                    'PK': f'EVENT#{event_id}',
                    'SK': f'REGISTRATION#{user_id}'
                },
                UpdateExpression='SET registrationStatus = :status',
                ExpressionAttributeValues={':status': status}
            )
        except ClientError as e:
            raise RepositoryError(f"Failed to update registration status: {str(e)}")
