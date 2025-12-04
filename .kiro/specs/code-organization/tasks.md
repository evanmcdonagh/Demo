# Implementation Plan

- [x] 1. Create foundational modules and exception classes
  - Create `backend/exceptions.py` with custom exception hierarchy (DomainException, ResourceNotFoundError, ResourceAlreadyExistsError, CapacityExceededError, RepositoryError)
  - Create `backend/utils.py` and move `get_timestamp()` function
  - Create `backend/config.py` with Config class for environment variables
  - Create empty `__init__.py` files for all new directories
  - _Requirements: 7.1, 7.2_

- [x] 2. Extract and organize data models
  - Create `backend/models/` directory structure
  - Create `backend/models/domain.py` with DomainEvent, DomainUser, DomainRegistration classes
  - Create `backend/models/api.py` and move existing Pydantic models (EventBase, EventCreate, EventUpdate, Event, User, RegistrationRequest, Registration, EventRegistrationRequest)
  - _Requirements: 5.1, 5.2, 3.1_

- [ ] 3. Implement repository layer
- [x] 3.1 Create base repository and event repository
  - Create `backend/repositories/` directory
  - Create `backend/repositories/base.py` with BaseRepository class
  - Create `backend/repositories/event_repository.py` with EventRepository class implementing all event CRUD operations
  - Handle DynamoDB reserved keywords using ExpressionAttributeNames
  - Translate ClientError to RepositoryError
  - _Requirements: 2.1, 2.2, 2.4, 2.5, 7.2_

- [x] 3.2 Create user repository
  - Create `backend/repositories/user_repository.py` with UserRepository class
  - Implement create, get_by_id, and exists methods
  - Handle AWS errors and translate to domain exceptions
  - _Requirements: 2.1, 2.2, 2.4, 7.2_

- [x] 3.3 Create registration repository
  - Create `backend/repositories/registration_repository.py` with RegistrationRepository class
  - Implement registration CRUD, waitlist operations, and query methods
  - Handle composite key patterns for user-event and event-user lookups
  - _Requirements: 2.1, 2.2, 2.4, 7.2_

- [ ]* 3.4 Write property test for repository reserved keyword handling
  - **Property 5: Repository operations with reserved keywords succeed**
  - **Validates: Requirements 2.5**

- [ ]* 3.5 Write property test for AWS error wrapping
  - **Property 6: AWS ClientError exceptions are wrapped in domain exceptions**
  - **Validates: Requirements 7.2, 7.5**

- [ ]* 3.6 Write unit tests for repositories
  - Test event repository CRUD operations with mock DynamoDB table
  - Test user repository operations
  - Test registration repository operations including waitlist logic
  - Verify domain object construction from DynamoDB items
  - _Requirements: 2.1, 2.2, 2.4_

- [ ] 4. Implement service layer
- [x] 4.1 Create event service
  - Create `backend/services/` directory
  - Create `backend/services/event_service.py` with EventService class
  - Implement business logic for event operations (create, get, list, update, delete)
  - Raise domain exceptions for error conditions
  - _Requirements: 1.1, 1.3, 1.5_

- [x] 4.2 Create user service
  - Create `backend/services/user_service.py` with UserService class
  - Implement user creation and retrieval logic
  - Raise ResourceAlreadyExistsError for duplicate users
  - _Requirements: 1.1, 1.3, 1.5_

- [x] 4.3 Create registration service
  - Create `backend/services/registration_service.py` with RegistrationService class
  - Implement registration business logic including capacity checks and waitlist management
  - Orchestrate operations across registration, event, and user repositories
  - Raise CapacityExceededError when appropriate
  - _Requirements: 1.1, 1.3, 1.5_

- [ ]* 4.4 Write property test for service return types
  - **Property 1: Service functions return domain objects or raise domain exceptions**
  - **Validates: Requirements 1.3**

- [ ]* 4.5 Write property test for domain exception propagation
  - **Property 7: Domain exceptions propagate through service layer**
  - **Validates: Requirements 7.3**

- [ ]* 4.6 Write property test for custom exception types
  - **Property 9: Custom exception types are raised for domain errors**
  - **Validates: Requirements 7.1**

- [ ]* 4.7 Write unit tests for services
  - Test event service with mock event repository
  - Test user service with mock user repository
  - Test registration service with mock repositories
  - Verify business rule enforcement and exception raising
  - _Requirements: 1.1, 1.3, 1.5_

- [x] 5. Create dependency injection setup
  - Create `backend/dependencies.py` with FastAPI dependency functions
  - Implement get_config, get_dynamodb_table, get_*_repository, get_*_service functions
  - Use FastAPI Depends() for dependency injection
  - _Requirements: 6.1, 6.2, 6.3_

- [ ] 6. Implement API route handlers
- [x] 6.1 Create event routes
  - Create `backend/routes/` directory
  - Create `backend/routes/events.py` with all event endpoints
  - Use dependency injection to obtain EventService
  - Convert between API models and domain models
  - Translate domain exceptions to HTTP status codes
  - _Requirements: 1.1, 1.4, 3.4, 4.1, 4.2, 4.3, 4.4, 4.5, 8.1, 8.2, 8.3, 8.4, 8.5_

- [x] 6.2 Create user routes
  - Create `backend/routes/users.py` with user endpoints
  - Use dependency injection to obtain UserService
  - Handle exception-to-HTTP-status-code mapping
  - _Requirements: 1.1, 1.4, 3.4, 4.1, 4.2, 8.1, 8.2, 8.3, 8.4_

- [x] 6.3 Create registration routes
  - Create `backend/routes/registrations.py` with all registration endpoints
  - Include both user-centric and event-centric endpoints
  - Use dependency injection to obtain RegistrationService and EventService
  - Handle all exception types appropriately
  - _Requirements: 1.1, 1.4, 3.4, 4.1, 4.2, 4.4, 8.1, 8.2, 8.3, 8.4, 8.5_

- [ ]* 6.4 Write property test for exception-to-HTTP-status-code mapping
  - **Property 4: Domain exceptions map to appropriate HTTP status codes**
  - **Validates: Requirements 1.4, 7.4**

- [ ]* 6.5 Write property test for validation at both layers
  - **Property 8: Validation occurs at both API and service layers**
  - **Validates: Requirements 5.5**

- [ ]* 6.6 Write unit tests for API handlers
  - Test request validation with invalid inputs
  - Test exception-to-HTTP-status-code mapping
  - Test model conversion between API and domain models
  - Verify dependency injection works correctly
  - _Requirements: 1.1, 1.4, 5.3, 5.4_

- [x] 7. Update main.py and wire everything together
  - Refactor `backend/main.py` to only handle app initialization and route registration
  - Import and include routers from routes modules
  - Keep CORS middleware configuration
  - Keep Lambda handler export
  - Remove all business logic, models, and endpoint definitions from main.py
  - _Requirements: 3.4, 8.1_

- [x] 8. Checkpoint - Verify all endpoints work identically
  - Ensure all tests pass, ask the user if questions arise.

- [ ]* 9. Write property test for API behavioral equivalence
  - **Property 3: API behavioral equivalence after refactoring**
  - **Validates: Requirements 4.1, 4.2, 4.3, 4.4, 4.5, 8.4**

- [ ]* 10. Write integration tests for end-to-end functionality
  - Test complete request-response cycles for all endpoints
  - Verify database state changes occur correctly
  - Test error cases produce correct responses
  - Compare behavior with original implementation where possible
  - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5, 8.1, 8.2, 8.3, 8.4, 8.5_

- [x] 11. Final checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.
