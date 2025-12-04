# Design Document: User Registration Feature

## Overview

The user registration feature extends the existing Events Management API to support user management, event registration with capacity constraints, and waitlist functionality. The system uses a composite key schema (PK/SK) in DynamoDB for flexible data modeling and efficient querying.

The design focuses on simplicity while maintaining data consistency and supporting the core registration workflows: user creation, event registration, capacity enforcement, waitlist management, and registration queries.

## Architecture

### High-Level Architecture

The system follows a serverless architecture pattern:

```
Client → API Gateway → Lambda (FastAPI) → DynamoDB
```

### Data Flow

1. **User Creation**: Client sends user data → API validates → Lambda creates user record in DynamoDB
2. **Event Registration**: Client sends registration request → API checks capacity → Lambda creates registration or waitlist record
3. **Event Unregistration**: Client sends unregister request → Lambda removes registration → Promotes waitlist user if applicable
4. **List User Events**: Client requests user's events → Lambda queries registrations → Returns event details

### DynamoDB Table Design

We'll use a single-table design with composite keys (PK/SK) to store all entities:

**Table Name**: `EventsTable`

**Primary Key**:
- Partition Key (PK): String
- Sort Key (SK): String

**Entity Patterns**:

1. **User**: 
   - PK: `USER#{userId}`
   - SK: `PROFILE`
   - Attributes: userId, name, createdAt

2. **Event**:
   - PK: `EVENT#{eventId}`
   - SK: `METADATA`
   - Attributes: eventId, title, description, date, location, capacity, organizer, status, currentRegistrations, waitlistEnabled

3. **Registration**:
   - PK: `USER#{userId}`
   - SK: `EVENT#{eventId}`
   - Attributes: userId, eventId, registeredAt, registrationStatus (registered/waitlisted)

4. **Event Registration Index** (for querying registrations by event):
   - PK: `EVENT#{eventId}`
   - SK: `REGISTRATION#{userId}`
   - Attributes: userId, eventId, registeredAt, registrationStatus

5. **Waitlist Entry**:
   - PK: `EVENT#{eventId}`
   - SK: `WAITLIST#{timestamp}#{userId}`
   - Attributes: userId, eventId, addedAt, position

**Global Secondary Indexes**:

1. **GSI1** (for querying by SK):
   - PK: SK
   - SK: PK
   - Use case: Query all registrations for an event

## Components and Interfaces

### API Endpoints

#### User Management

**POST /users**
- Request: `{ "userId": "string", "name": "string" }`
- Response: `{ "userId": "string", "name": "string", "createdAt": "string" }`
- Status: 201 Created, 400 Bad Request, 409 Conflict

**GET /users/{userId}**
- Response: `{ "userId": "string", "name": "string", "createdAt": "string" }`
- Status: 200 OK, 404 Not Found

#### Registration Management

**POST /registrations**
- Request: `{ "userId": "string", "eventId": "string" }`
- Response: `{ "userId": "string", "eventId": "string", "status": "registered|waitlisted", "registeredAt": "string" }`
- Status: 201 Created, 400 Bad Request, 409 Conflict

**DELETE /registrations/{userId}/{eventId}**
- Response: `{ "message": "string" }`
- Status: 204 No Content, 404 Not Found

**GET /users/{userId}/events**
- Response: `{ "events": [{ "eventId": "string", "title": "string", ... }] }`
- Status: 200 OK

#### Event Management (Updated)

**POST /events** (updated to include capacity and waitlistEnabled)
- Request: `{ "eventId": "string", "title": "string", "description": "string", "date": "string", "location": "string", "capacity": number, "organizer": "string", "status": "string", "waitlistEnabled": boolean }`
- Response: Event object
- Status: 201 Created

**PUT /events/{eventId}** (updated to support capacity and waitlistEnabled)
- Request: Partial event object
- Response: Updated event object
- Status: 200 OK

### Core Functions

1. **create_user(user_data)**: Creates a new user record
2. **get_user(user_id)**: Retrieves user information
3. **register_user_for_event(user_id, event_id)**: Handles registration logic with capacity checks
4. **unregister_user_from_event(user_id, event_id)**: Handles unregistration and waitlist promotion
5. **get_user_events(user_id)**: Retrieves all events a user is registered for
6. **check_event_capacity(event_id)**: Checks if event has available capacity
7. **add_to_waitlist(user_id, event_id)**: Adds user to event waitlist
8. **promote_from_waitlist(event_id)**: Promotes first waitlisted user to registered status

## Data Models

### User Model

```python
class User(BaseModel):
    userId: str = Field(..., min_length=1, max_length=100)
    name: str = Field(..., min_length=1, max_length=200)
    createdAt: Optional[str] = None
```

### Event Model (Updated)

```python
class Event(BaseModel):
    eventId: str = Field(..., min_length=1, max_length=100)
    title: str = Field(..., min_length=1, max_length=200)
    description: str = Field(..., max_length=1000)
    date: str = Field(..., pattern=r'^\d{4}-\d{2}-\d{2}$')
    location: str = Field(..., min_length=1, max_length=200)
    capacity: int = Field(..., gt=0)
    organizer: str = Field(..., min_length=1, max_length=200)
    status: str = Field(..., pattern=r'^(active|cancelled|completed)$')
    currentRegistrations: Optional[int] = 0
    waitlistEnabled: bool = False
```

### Registration Model

```python
class Registration(BaseModel):
    userId: str
    eventId: str
    registrationStatus: str = Field(..., pattern=r'^(registered|waitlisted)$')
    registeredAt: Optional[str] = None
```

### Registration Request Model

```python
class RegistrationRequest(BaseModel):
    userId: str = Field(..., min_length=1)
    eventId: str = Field(..., min_length=1)
```

## 
Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system—essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Property 1: User creation round trip
*For any* valid userId and name, creating a user then retrieving it should return the same userId and name
**Validates: Requirements 1.1**

### Property 2: Invalid user input rejection
*For any* user creation request with empty or whitespace-only userId or name, the system should reject the request with an error
**Validates: Requirements 1.2, 1.3**

### Property 3: Duplicate user prevention
*For any* userId, after successfully creating a user with that userId, attempting to create another user with the same userId should be rejected
**Validates: Requirements 1.4**

### Property 4: Event attributes round trip
*For any* event with capacity and waitlistEnabled values, creating or updating the event then retrieving it should preserve both the capacity value and waitlistEnabled flag
**Validates: Requirements 2.1, 2.2, 2.3**

### Property 5: Capacity enforcement
*For any* event with capacity N and no waitlist, after N successful registrations, the (N+1)th registration attempt should be rejected
**Validates: Requirements 2.4, 3.2**

### Property 6: Registration creates record and decrements capacity
*For any* event with available capacity, registering a user should create a registration record and reduce the available capacity by one
**Validates: Requirements 3.1**

### Property 7: Waitlist addition when full
*For any* event at full capacity with waitlist enabled, registering a user should add them to the waitlist with status "waitlisted"
**Validates: Requirements 3.3**

### Property 8: Duplicate registration prevention
*For any* user and event, after successfully registering the user for the event, attempting to register the same user for the same event again should be rejected
**Validates: Requirements 3.4**

### Property 9: Unregistration removes record and increments capacity
*For any* registered user and event, unregistering the user should remove the registration record and increase the available capacity by one
**Validates: Requirements 4.1**

### Property 10: Waitlist promotion on unregistration
*For any* event with at least one waitlisted user, when a registered user unregisters, the first waitlisted user should be promoted to registered status
**Validates: Requirements 4.2**

### Property 11: User events query returns only registered events
*For any* user with both registered events and waitlisted events, querying their events should return only events where registrationStatus is "registered"
**Validates: Requirements 5.1, 5.2**

## Error Handling

### Error Types

1. **ValidationError (400)**: Invalid input data (empty fields, invalid formats)
2. **ConflictError (409)**: Duplicate resource (user already exists, already registered)
3. **NotFoundError (404)**: Resource not found (user doesn't exist, event doesn't exist)
4. **CapacityError (409)**: Event at full capacity with no waitlist

### Error Response Format

```json
{
  "error": "error_type",
  "message": "Human-readable error message",
  "details": {}
}
```

### Specific Error Scenarios

1. **User Creation**:
   - Empty userId/name → ValidationError
   - Duplicate userId → ConflictError

2. **Registration**:
   - Non-existent user/event → NotFoundError
   - Already registered → ConflictError
   - Event full, no waitlist → CapacityError
   - Event full, waitlist enabled → Success (added to waitlist)

3. **Unregistration**:
   - Non-existent user/event → NotFoundError
   - Not registered → NotFoundError

4. **Query User Events**:
   - Non-existent user → Return empty list (not an error)

## Testing Strategy

### Unit Testing

Unit tests will cover specific examples and integration points:

1. **User Management**:
   - Create user with valid data
   - Retrieve existing user
   - Handle duplicate user creation

2. **Registration Logic**:
   - Register user for event with capacity
   - Handle full event without waitlist
   - Handle full event with waitlist
   - Unregister user and verify capacity update

3. **Waitlist Management**:
   - Add user to waitlist when event is full
   - Promote waitlisted user when spot opens
   - Maintain waitlist order (FIFO)

4. **Query Operations**:
   - List user's registered events
   - Filter out waitlisted events
   - Handle empty results

### Property-Based Testing

Property-based tests will verify universal properties across all inputs using **Hypothesis** (Python property-based testing library). Each test will run a minimum of 100 iterations.

Each property-based test will be tagged with a comment explicitly referencing the correctness property in this design document using the format: **Feature: user-registration, Property {number}: {property_text}**

Property tests will cover:

1. **User Creation Properties** (Properties 1-3):
   - Round-trip consistency for valid users
   - Rejection of invalid inputs
   - Duplicate prevention

2. **Event Capacity Properties** (Properties 4-5):
   - Attribute persistence
   - Capacity enforcement

3. **Registration Properties** (Properties 6-8):
   - Registration record creation
   - Waitlist functionality
   - Duplicate prevention

4. **Unregistration Properties** (Properties 9-10):
   - Record removal and capacity updates
   - Waitlist promotion

5. **Query Properties** (Property 11):
   - Correct filtering of registered vs waitlisted events

### Test Data Generation

Property-based tests will use smart generators that:
- Generate valid userIds and names (non-empty strings)
- Generate valid event data with various capacity values
- Generate registration scenarios with different capacity states
- Generate waitlist scenarios with multiple users
- Constrain inputs to valid ranges to focus on business logic

### Integration Testing

Integration tests will verify end-to-end workflows:
1. Create user → Register for event → Verify registration
2. Fill event to capacity → Attempt registration → Verify rejection or waitlist
3. Unregister user → Verify waitlist promotion
4. Query user events → Verify correct event list

## Implementation Notes

### DynamoDB Considerations

1. **Atomic Operations**: Use DynamoDB transactions for operations that require atomicity (e.g., registration with capacity check)
2. **Conditional Writes**: Use condition expressions to prevent race conditions (e.g., capacity checks)
3. **Consistent Reads**: Use consistent reads when checking capacity to avoid stale data
4. **Reserved Keywords**: Continue using expression attribute names for reserved keywords (status, capacity, date, location, name)

### Migration Strategy

To migrate existing events to the composite key schema:

1. Read all existing events (PK: eventId)
2. For each event, create new record with PK: `EVENT#{eventId}`, SK: `METADATA`
3. Add new fields: currentRegistrations (default 0), waitlistEnabled (default false)
4. Verify migration, then remove old records

### Capacity Tracking

Track current registrations in two ways:
1. **Event record**: Store `currentRegistrations` count for quick capacity checks
2. **Registration records**: Query actual registrations as source of truth

Use optimistic locking with conditional updates to prevent race conditions when updating capacity.

### Waitlist Implementation

Waitlist entries use timestamp-based sort keys to maintain FIFO order:
- SK format: `WAITLIST#{timestamp}#{userId}`
- Query waitlist entries sorted by SK to get FIFO order
- When promoting, query first entry and update to registered status

## Infrastructure Updates

### DynamoDB Table Changes

1. **Update table schema** to use composite keys (PK, SK)
2. **Add GSI1** for querying by SK (reverse lookup)
3. **Update table capacity** if needed for increased load

### Lambda Function Updates

1. **Update IAM permissions** for new DynamoDB operations
2. **Update environment variables** if needed
3. **Increase memory/timeout** if needed for complex queries

### API Gateway Updates

1. **Add routes** for user management endpoints
2. **Add routes** for registration endpoints
3. **Update CORS** configuration if needed

### CDK Stack Updates

```typescript
// Update table definition
const table = new dynamodb.Table(this, 'EventsTable', {
  partitionKey: { name: 'PK', type: dynamodb.AttributeType.STRING },
  sortKey: { name: 'SK', type: dynamodb.AttributeType.STRING },
  // Add GSI for reverse lookups
});

table.addGlobalSecondaryIndex({
  indexName: 'GSI1',
  partitionKey: { name: 'SK', type: dynamodb.AttributeType.STRING },
  sortKey: { name: 'PK', type: dynamodb.AttributeType.STRING },
});
```
