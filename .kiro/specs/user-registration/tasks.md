# Implementation Plan

- [ ] 1. Update DynamoDB table schema to composite key pattern (PK/SK)
  - Update CDK infrastructure to define table with PK and SK
  - Add GSI1 for reverse lookups (SK as PK, PK as SK)
  - Deploy infrastructure changes
  - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5, 7.1, 7.2_

- [ ] 2. Migrate existing event data to composite key schema
  - Write migration script to read existing events
  - Transform events to new schema (PK: EVENT#{eventId}, SK: METADATA)
  - Add new fields: currentRegistrations (0), waitlistEnabled (false)
  - Verify migration and clean up old records
  - _Requirements: 6.6_

- [ ] 3. Update event CRUD operations for composite key schema
  - Update create_event to use PK/SK pattern
  - Update get_event to query with PK/SK
  - Update update_event to use PK/SK
  - Update delete_event to use PK/SK
  - Update list_events to scan with PK/SK filter
  - _Requirements: 6.3, 2.1, 2.2, 2.3_

- [ ]* 3.1 Write property test for event attributes round trip
  - **Property 4: Event attributes round trip**
  - **Validates: Requirements 2.1, 2.2, 2.3**

- [ ] 4. Implement user management
- [ ] 4.1 Create user data model and validation
  - Define User Pydantic model with userId and name validation
  - Implement validation for non-empty fields
  - _Requirements: 1.1, 1.2, 1.3_

- [ ] 4.2 Implement create_user function
  - Write function to create user in DynamoDB with PK/SK pattern
  - Add duplicate userId check with conditional write
  - Handle DynamoDB reserved keyword "name"
  - _Requirements: 1.1, 1.4, 6.2_

- [ ] 4.3 Implement get_user function
  - Write function to retrieve user by userId
  - Handle user not found case
  - _Requirements: 1.1_

- [ ] 4.4 Create user API endpoints
  - Implement POST /users endpoint
  - Implement GET /users/{userId} endpoint
  - Add error handling for validation and conflicts
  - Update API Gateway routes in CDK
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 7.4_

- [ ]* 4.5 Write property test for user creation round trip
  - **Property 1: User creation round trip**
  - **Validates: Requirements 1.1**

- [ ]* 4.6 Write property test for invalid user input rejection
  - **Property 2: Invalid user input rejection**
  - **Validates: Requirements 1.2, 1.3**

- [ ]* 4.7 Write property test for duplicate user prevention
  - **Property 3: Duplicate user prevention**
  - **Validates: Requirements 1.4**

- [ ] 5. Implement registration logic with capacity enforcement
- [ ] 5.1 Create registration data models
  - Define Registration and RegistrationRequest Pydantic models
  - Add validation for userId and eventId
  - _Requirements: 3.1_

- [ ] 5.2 Implement check_event_capacity function
  - Write function to check available capacity
  - Use consistent reads to avoid stale data
  - _Requirements: 2.4, 3.1_

- [ ] 5.3 Implement register_user_for_event function
  - Check if user and event exist
  - Check if user already registered
  - Check event capacity
  - Create registration record with PK/SK pattern
  - Update event currentRegistrations count atomically
  - Handle full event without waitlist (reject)
  - Handle full event with waitlist (add to waitlist)
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 6.4_

- [ ] 5.4 Create registration API endpoint
  - Implement POST /registrations endpoint
  - Add error handling for all scenarios
  - Update API Gateway routes in CDK
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 7.4_

- [ ]* 5.5 Write property test for registration creates record and decrements capacity
  - **Property 6: Registration creates record and decrements capacity**
  - **Validates: Requirements 3.1**

- [ ]* 5.6 Write property test for capacity enforcement
  - **Property 5: Capacity enforcement**
  - **Validates: Requirements 2.4, 3.2**

- [ ]* 5.7 Write property test for duplicate registration prevention
  - **Property 8: Duplicate registration prevention**
  - **Validates: Requirements 3.4**

- [ ] 6. Implement waitlist functionality
- [ ] 6.1 Implement add_to_waitlist function
  - Create waitlist entry with PK/SK pattern (WAITLIST#{timestamp}#{userId})
  - Store waitlist position and timestamp
  - _Requirements: 3.3, 6.5_

- [ ] 6.2 Implement promote_from_waitlist function
  - Query first waitlist entry (sorted by SK)
  - Convert waitlist entry to registration
  - Remove from waitlist
  - Update event currentRegistrations
  - _Requirements: 4.2_

- [ ]* 6.3 Write property test for waitlist addition when full
  - **Property 7: Waitlist addition when full**
  - **Validates: Requirements 3.3**

- [ ]* 6.4 Write property test for waitlist promotion on unregistration
  - **Property 10: Waitlist promotion on unregistration**
  - **Validates: Requirements 4.2**

- [ ] 7. Implement unregistration logic
- [ ] 7.1 Implement unregister_user_from_event function
  - Check if user is registered for event
  - Remove registration record
  - Update event currentRegistrations count atomically
  - Call promote_from_waitlist if waitlist exists
  - _Requirements: 4.1, 4.2, 4.3, 4.4_

- [ ] 7.2 Create unregistration API endpoint
  - Implement DELETE /registrations/{userId}/{eventId} endpoint
  - Add error handling for not found cases
  - Update API Gateway routes in CDK
  - _Requirements: 4.1, 4.2, 4.3, 4.4, 7.4_

- [ ]* 7.3 Write property test for unregistration removes record and increments capacity
  - **Property 9: Unregistration removes record and increments capacity**
  - **Validates: Requirements 4.1**

- [ ] 8. Implement user events query
- [ ] 8.1 Implement get_user_events function
  - Query all registrations for user (PK: USER#{userId})
  - Filter for registrationStatus = "registered"
  - Fetch event details for each registration
  - Return list of events
  - _Requirements: 5.1, 5.2, 5.3, 5.4_

- [ ] 8.2 Create user events API endpoint
  - Implement GET /users/{userId}/events endpoint
  - Handle empty results gracefully
  - Update API Gateway routes in CDK
  - _Requirements: 5.1, 5.2, 5.3, 5.4, 7.4_

- [ ]* 8.3 Write property test for user events query returns only registered events
  - **Property 11: User events query returns only registered events**
  - **Validates: Requirements 5.1, 5.2**

- [ ] 9. Update Lambda permissions and deploy
  - Update Lambda IAM role with permissions for all DynamoDB operations
  - Update Lambda environment variables if needed
  - Deploy updated infrastructure and application
  - _Requirements: 7.3_

- [ ] 10. Final checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.
