# User Registration API Documentation

## Overview

The Events Management API now includes user registration functionality with capacity enforcement and waitlist management.

**API Base URL**: `https://knknpcjjz7.execute-api.us-west-2.amazonaws.com/prod`

## New Features

- ✅ User management (create, retrieve users)
- ✅ Event registration with capacity constraints
- ✅ Automatic waitlist management
- ✅ Waitlist promotion when spots open up
- ✅ Query user's registered events
- ✅ Composite key schema (PK/SK) for flexible data modeling

## API Endpoints

### User Management

#### Create User
```bash
POST /users
Content-Type: application/json

{
  "userId": "user-001",
  "name": "Alice Johnson"
}

Response: 201 Created
{
  "userId": "user-001",
  "name": "Alice Johnson",
  "createdAt": "2025-12-04T01:49:28.116147"
}
```

#### Get User
```bash
GET /users/{userId}

Response: 200 OK
{
  "userId": "user-001",
  "name": "Alice Johnson",
  "createdAt": "2025-12-04T01:49:28.116147"
}
```

### Event Management (Updated)

Events now support `capacity` and `waitlistEnabled` fields:

```bash
POST /events
Content-Type: application/json

{
  "eventId": "event-001",
  "title": "Tech Conference 2024",
  "description": "Annual technology conference",
  "date": "2024-12-20",
  "location": "San Francisco",
  "capacity": 50,
  "organizer": "Tech Corp",
  "status": "active",
  "waitlistEnabled": true
}

Response: 201 Created
{
  "eventId": "event-001",
  "title": "Tech Conference 2024",
  "description": "Annual technology conference",
  "date": "2024-12-20",
  "location": "San Francisco",
  "capacity": 50,
  "organizer": "Tech Corp",
  "status": "active",
  "currentRegistrations": 0,
  "waitlistEnabled": true,
  "createdAt": "2025-12-04T01:49:28.602803",
  "updatedAt": "2025-12-04T01:49:28.602803"
}
```

### Registration Management

The API supports two endpoint patterns for registration management:

#### Pattern 1: User-centric endpoints

**Register User for Event**
```bash
POST /registrations
Content-Type: application/json

{
  "userId": "user-001",
  "eventId": "event-001"
}

Response: 201 Created
{
  "userId": "user-001",
  "eventId": "event-001",
  "registrationStatus": "registered",  # or "waitlisted" if event is full
  "registeredAt": "2025-12-04T01:49:28.781471"
}
```

**Unregister User from Event**
```bash
DELETE /registrations/{userId}/{eventId}

Response: 204 No Content
```

**Get User's Registered Events**
```bash
GET /users/{userId}/events

Response: 200 OK
[
  {
    "eventId": "event-001",
    "title": "Tech Conference 2024",
    ...
  }
]
```

**Get User's Registrations**
```bash
GET /users/{userId}/registrations

Response: 200 OK
[
  {
    "userId": "user-001",
    "eventId": "event-001",
    "registrationStatus": "registered",
    "registeredAt": "2025-12-04T01:49:28.781471"
  }
]
```

#### Pattern 2: Event-centric endpoints

**Register User for Event**
```bash
POST /events/{eventId}/registrations
Content-Type: application/json

{
  "userId": "user-001"
}

Response: 201 Created
{
  "userId": "user-001",
  "eventId": "event-001",
  "registrationStatus": "registered",
  "registeredAt": "2025-12-04T01:49:28.781471"
}
```

**Unregister User from Event**
```bash
DELETE /events/{eventId}/registrations/{userId}

Response: 204 No Content
```

**Get Event's Registrations**
```bash
GET /events/{eventId}/registrations

Response: 200 OK
[
  {
    "userId": "user-001",
    "eventId": "event-001",
    "registrationStatus": "registered",
    "registeredAt": "2025-12-04T01:49:28.781471"
  },
  {
    "userId": "user-002",
    "eventId": "event-001",
    "registrationStatus": "waitlisted",
    "registeredAt": "2025-12-04T01:50:15.123456"
  }
]
```

**Registration Behavior**:
- If event has available capacity → User is registered
- If event is full and waitlist is disabled → Error 409 (Conflict)
- If event is full and waitlist is enabled → User is added to waitlist

**Unregistration Behavior**:
- Removes user's registration
- If waitlist exists, automatically promotes first waitlisted user to registered status
- Updates event capacity accordingly

**Note**: `GET /users/{userId}/events` only returns events where user has `registrationStatus: "registered"`. Waitlisted events are excluded.

## Registration Workflow Examples

### Example 1: Successful Registration

```bash
# 1. Create a user
curl -X POST "$API_URL/users" \
  -H "Content-Type: application/json" \
  -d '{"userId": "alice", "name": "Alice Johnson"}'

# 2. Create an event with capacity
curl -X POST "$API_URL/events" \
  -H "Content-Type: application/json" \
  -d '{
    "eventId": "conf-2024",
    "title": "Tech Conference",
    "description": "Annual conference",
    "date": "2024-12-20",
    "location": "San Francisco",
    "capacity": 100,
    "organizer": "Tech Corp",
    "status": "active",
    "waitlistEnabled": true
  }'

# 3. Register user for event
curl -X POST "$API_URL/registrations" \
  -H "Content-Type: application/json" \
  -d '{"userId": "alice", "eventId": "conf-2024"}'

# 4. View user's events
curl -X GET "$API_URL/users/alice/events"
```

### Example 2: Waitlist Scenario

```bash
# Event has capacity of 2, waitlist enabled
# User 1 registers → registered
# User 2 registers → registered
# User 3 registers → waitlisted (event full)
# User 1 unregisters → User 3 automatically promoted to registered
```

### Example 3: Full Event Without Waitlist

```bash
# Event has capacity of 1, waitlist disabled
# User 1 registers → registered
# User 2 tries to register → Error 409: "Event is at full capacity and waitlist is not enabled"
```

## Error Responses

### 400 Bad Request
```json
{
  "detail": "Validation error message"
}
```

### 404 Not Found
```json
{
  "detail": "User with ID user-001 not found"
}
```

### 409 Conflict
```json
{
  "detail": "User is already registered for this event"
}
```

or

```json
{
  "detail": "Event is at full capacity and waitlist is not enabled"
}
```

## Data Model Changes

### DynamoDB Schema

The system now uses a composite key pattern (PK/SK) for flexible data modeling:

**Users**:
- PK: `USER#{userId}`
- SK: `PROFILE`

**Events**:
- PK: `EVENT#{eventId}`
- SK: `METADATA`

**Registrations**:
- PK: `USER#{userId}`
- SK: `EVENT#{eventId}`

**Waitlist Entries**:
- PK: `EVENT#{eventId}`
- SK: `WAITLIST#{timestamp}#{userId}`

**Event-User Index** (for reverse lookups):
- PK: `EVENT#{eventId}`
- SK: `REGISTRATION#{userId}`

## Testing

Run the comprehensive test suite:

```bash
./test_registration.sh
```

This tests:
- User creation and retrieval
- Event creation with capacity constraints
- Registration with available capacity
- Waitlist functionality when event is full
- Automatic waitlist promotion on unregistration
- Duplicate registration prevention
- Full event without waitlist rejection
- User events query filtering

## Migration Notes

⚠️ **Important**: The new system uses a different DynamoDB table (`EventsTableV2`) with composite keys. Existing events in the old table need to be migrated.

To migrate existing events, you'll need to:
1. Read events from old table
2. Transform to new schema with PK/SK
3. Add new fields: `currentRegistrations`, `waitlistEnabled`
4. Write to new table

## Next Steps

- Implement data migration script for existing events (Task 2)
- Add property-based tests for correctness properties
- Add integration tests for complex workflows
- Consider adding pagination for large result sets
- Add event capacity update validation (prevent reducing below current registrations)
