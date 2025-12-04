# Requirements Document

## Introduction

This document specifies the requirements for a user registration system that allows users to register for events with capacity constraints and waitlist management. The system extends the existing Events Management API to support user creation, event registration, capacity enforcement, and waitlist functionality.

## Glossary

- **System**: The Events Management API backend
- **User**: An individual who can register for events
- **Event**: A scheduled activity with capacity constraints
- **Registration**: The act of a user signing up for an event
- **Capacity**: The maximum number of users that can be registered for an event
- **Waitlist**: A queue of users waiting for spots to become available when an event is at capacity
- **DynamoDB**: The database service used for data persistence
- **Composite Key**: A primary key pattern using partition key (PK) and sort key (SK) for flexible data modeling

## Requirements

### Requirement 1

**User Story:** As a system administrator, I want to create users with basic information, so that they can participate in the event registration system.

#### Acceptance Criteria

1. WHEN a user creation request is received with userId and name THEN the System SHALL create a new user record in DynamoDB
2. WHEN a user creation request contains an empty or missing userId THEN the System SHALL reject the request and return an error
3. WHEN a user creation request contains an empty or missing name THEN the System SHALL reject the request and return an error
4. WHEN a user creation request contains a userId that already exists THEN the System SHALL reject the request and return an error

### Requirement 2

**User Story:** As an event organizer, I want to configure events with capacity constraints and optional waitlists, so that I can manage event attendance effectively.

#### Acceptance Criteria

1. WHEN an event is created or updated with a capacity value THEN the System SHALL store the capacity constraint
2. WHEN an event is created or updated with a waitlist flag set to true THEN the System SHALL enable waitlist functionality for that event
3. WHEN an event is created or updated with a waitlist flag set to false THEN the System SHALL disable waitlist functionality for that event
4. WHEN an event capacity is set to a positive integer THEN the System SHALL enforce that capacity during registration

### Requirement 3

**User Story:** As a user, I want to register for events, so that I can participate in activities I'm interested in.

#### Acceptance Criteria

1. WHEN a user registers for an event that has available capacity THEN the System SHALL create a registration record and decrement available capacity
2. WHEN a user attempts to register for an event that is at full capacity and has no waitlist THEN the System SHALL reject the registration and return an error
3. WHEN a user attempts to register for an event that is at full capacity and has a waitlist enabled THEN the System SHALL add the user to the waitlist
4. WHEN a user attempts to register for an event they are already registered for THEN the System SHALL reject the request and return an error
5. WHEN a user attempts to register for a non-existent event THEN the System SHALL reject the request and return an error

### Requirement 4

**User Story:** As a user, I want to unregister from events, so that I can free up my spot if I can no longer attend.

#### Acceptance Criteria

1. WHEN a user unregisters from an event they are registered for THEN the System SHALL remove the registration record and increment available capacity
2. WHEN a user unregisters from an event and a waitlist exists THEN the System SHALL promote the first waitlisted user to registered status
3. WHEN a user attempts to unregister from an event they are not registered for THEN the System SHALL reject the request and return an error
4. WHEN a user attempts to unregister from a non-existent event THEN the System SHALL reject the request and return an error

### Requirement 5

**User Story:** As a user, I want to list all events I am registered for, so that I can keep track of my commitments.

#### Acceptance Criteria

1. WHEN a user requests their registered events THEN the System SHALL return all events where the user has an active registration
2. WHEN a user requests their registered events THEN the System SHALL exclude events where the user is only on the waitlist
3. WHEN a user has no registered events THEN the System SHALL return an empty list
4. WHEN a non-existent user requests their registered events THEN the System SHALL return an empty list

### Requirement 6

**User Story:** As a developer, I want to use a composite key schema (PK/SK) across all DynamoDB tables, so that the data model is flexible and supports efficient queries.

#### Acceptance Criteria

1. WHEN storing any entity in DynamoDB THEN the System SHALL use a partition key (PK) and sort key (SK) pattern
2. WHEN storing user records THEN the System SHALL use PK format "USER#{userId}" and SK format "PROFILE"
3. WHEN storing event records THEN the System SHALL use PK format "EVENT#{eventId}" and SK format "METADATA"
4. WHEN storing registration records THEN the System SHALL use PK format "USER#{userId}" and SK format "EVENT#{eventId}"
5. WHEN storing waitlist records THEN the System SHALL use PK format "EVENT#{eventId}" and SK format "WAITLIST#{timestamp}#{userId}"
6. WHEN migrating existing event data THEN the System SHALL convert single-key schema to composite key schema

### Requirement 7

**User Story:** As a developer, I want to update the infrastructure to support the new data model and API endpoints, so that the system can handle user registration functionality.

#### Acceptance Criteria

1. WHEN deploying infrastructure updates THEN the System SHALL configure DynamoDB tables with composite key schema (PK and SK)
2. WHEN deploying infrastructure updates THEN the System SHALL create necessary Global Secondary Indexes for efficient querying
3. WHEN deploying infrastructure updates THEN the System SHALL update Lambda function permissions to access all required DynamoDB operations
4. WHEN deploying infrastructure updates THEN the System SHALL configure API Gateway routes for user and registration endpoints
