# Design Document

## Overview

This design document outlines the refactoring of the Events API backend from a monolithic `main.py` file into a layered, modular architecture. The refactoring will separate concerns into distinct layers: API handlers, service layer, repository layer, and domain models. This architecture follows the principles of clean architecture and dependency inversion, making the codebase more maintainable, testable, and scalable.

The refactoring will preserve all existing API functionality while improving code organization, testability, and maintainability.

## Architecture

### Layered Architecture

The system will be organized into the following layers:

```
backend/
├── main.py                 # FastAPI app initialization and configuration
├── config.py               # Configuration and environment variables
├── dependencies.py         # Dependency injection setup
├── models/                 # Domain and API models
│   ├── __init__.py
│   ├── domain.py          # Internal domain models
│   └── api.py             # API request/response models
├── repositories/           # Data access layer
│   ├── __init__.py
│   ├── base.py            # Base repository interface
│   ├── event_repository.py
│   ├── user_repository.py
│   └── registration_repository.py
├── services/               # Business logic layer
│   ├── __init__.py
│   ├── event_service.py
│   ├── user_service.py
│   └── registration_service.py
├── routes/                 # API route handlers
│   ├── __init__.py
│   ├── events.py
│   ├── users.py
│   └── registrations.py
├── exceptions.py           # Custom exception classes
└── utils.py               # Shared utility functions
```

### Layer Responsibilities

**API Layer (routes/):**
- Handle HTTP requests and responses
- Validate request data using Pydantic models
- Convert between API models and domain models
- Translate domain exceptions to HTTP status codes
- Use dependency injection to obtain service instances

**Service Layer (services/):**
- Implement business logic and domain rules
- Orchestrate operations across multiple repositories
- Enforce business constraints and validation
- Raise domain-specific exceptions
- Return domain objects

**Repository Layer (repositories/):**
- Encapsulate all DynamoDB operations
- Handle DynamoDB reserved keywords
- Convert DynamoDB items to domain objects
- Translate AWS ClientError to domain exceptions
- Provide clean data access interface

**Domain Models (models/domain.py):**
- Represent core business entities
- Contain domain validation rules
- Independent of API and database concerns

**API Models (models/api.py):**
- Define HTTP request/response schemas
- Handle API-specific validation
- Map to domain models

## Components and Interfaces

### Configuration Module (config.py)

```python
class Config:
    """Application configuration"""
    table_name: str
    aws_region: str
    
    @classmethod
    def from_env(cls) -> 'Config':
        """Load configuration from environment variables"""
```

### Exception Classes (exceptions.py)

```python
class DomainException(Exception):
    """Base exception for domain errors"""

class ResourceNotFoundError(DomainException):
    """Raised when a resource is not found"""

class ResourceAlreadyExistsError(DomainException):
    """Raised when attempting to create a duplicate resource"""

class CapacityExceededError(DomainException):
    """Raised when event capacity is exceeded"""

class RepositoryError(DomainException):
    """Raised when database operations fail"""
```

### Repository Interfaces

**Base Repository:**
```python
class BaseRepository:
    def __init__(self, table):
        self.table = table
```

**Event Repository:**
```python
class EventRepository(BaseRepository):
    def create(self, event: DomainEvent) -> DomainEvent
    def get_by_id(self, event_id: str) -> Optional[DomainEvent]
    def list_all(self, status_filter: Optional[str] = None) -> List[DomainEvent]
    def update(self, event_id: str, updates: Dict[str, Any]) -> DomainEvent
    def delete(self, event_id: str) -> None
    def increment_registrations(self, event_id: str) -> None
    def decrement_registrations(self, event_id: str) -> None
```

**User Repository:**
```python
class UserRepository(BaseRepository):
    def create(self, user: DomainUser) -> DomainUser
    def get_by_id(self, user_id: str) -> Optional[DomainUser]
    def exists(self, user_id: str) -> bool
```

**Registration Repository:**
```python
class RegistrationRepository(BaseRepository):
    def create_registration(self, registration: DomainRegistration) -> DomainRegistration
    def get_registration(self, user_id: str, event_id: str) -> Optional[DomainRegistration]
    def delete_registration(self, user_id: str, event_id: str) -> None
    def list_user_registrations(self, user_id: str) -> List[DomainRegistration]
    def list_event_registrations(self, event_id: str) -> List[DomainRegistration]
    def add_to_waitlist(self, user_id: str, event_id: str, timestamp: str) -> None
    def get_first_waitlisted(self, event_id: str) -> Optional[Dict[str, Any]]
    def remove_from_waitlist(self, pk: str, sk: str) -> None
    def update_registration_status(self, user_id: str, event_id: str, status: str) -> None
```

### Service Interfaces

**Event Service:**
```python
class EventService:
    def __init__(self, event_repository: EventRepository):
        self.event_repo = event_repository
    
    def create_event(self, event_data: Dict[str, Any]) -> DomainEvent
    def get_event(self, event_id: str) -> DomainEvent
    def list_events(self, status_filter: Optional[str] = None) -> List[DomainEvent]
    def update_event(self, event_id: str, updates: Dict[str, Any]) -> DomainEvent
    def delete_event(self, event_id: str) -> None
```

**User Service:**
```python
class UserService:
    def __init__(self, user_repository: UserRepository):
        self.user_repo = user_repository
    
    def create_user(self, user_data: Dict[str, Any]) -> DomainUser
    def get_user(self, user_id: str) -> DomainUser
```

**Registration Service:**
```python
class RegistrationService:
    def __init__(
        self,
        registration_repository: RegistrationRepository,
        event_repository: EventRepository,
        user_repository: UserRepository
    ):
        self.registration_repo = registration_repository
        self.event_repo = event_repository
        self.user_repo = user_repository
    
    def register_user(self, user_id: str, event_id: str) -> DomainRegistration
    def unregister_user(self, user_id: str, event_id: str) -> None
    def get_user_events(self, user_id: str) -> List[DomainEvent]
    def get_event_registrations(self, event_id: str) -> List[DomainRegistration]
    def get_user_registrations(self, user_id: str) -> List[DomainRegistration]
```

### Dependency Injection (dependencies.py)

```python
def get_config() -> Config:
    """Get application configuration"""

def get_dynamodb_table(config: Config = Depends(get_config)):
    """Get DynamoDB table instance"""

def get_event_repository(table = Depends(get_dynamodb_table)) -> EventRepository:
    """Get event repository instance"""

def get_user_repository(table = Depends(get_dynamodb_table)) -> UserRepository:
    """Get user repository instance"""

def get_registration_repository(table = Depends(get_dynamodb_table)) -> RegistrationRepository:
    """Get registration repository instance"""

def get_event_service(repo: EventRepository = Depends(get_event_repository)) -> EventService:
    """Get event service instance"""

def get_user_service(repo: UserRepository = Depends(get_user_repository)) -> UserService:
    """Get user service instance"""

def get_registration_service(
    reg_repo: RegistrationRepository = Depends(get_registration_repository),
    event_repo: EventRepository = Depends(get_event_repository),
    user_repo: UserRepository = Depends(get_user_repository)
) -> RegistrationService:
    """Get registration service instance"""
```

## Data Models

### Domain Models (models/domain.py)

```python
class DomainEvent:
    """Internal representation of an event"""
    event_id: str
    title: str
    description: str
    date: str
    location: str
    capacity: int
    organizer: str
    status: str
    current_registrations: int
    waitlist_enabled: bool
    created_at: str
    updated_at: str

class DomainUser:
    """Internal representation of a user"""
    user_id: str
    name: str
    created_at: str

class DomainRegistration:
    """Internal representation of a registration"""
    user_id: str
    event_id: str
    registration_status: str
    registered_at: str
```

### API Models (models/api.py)

API models remain largely the same as the current implementation:
- `EventBase`, `EventCreate`, `EventUpdate`, `Event`
- `User`
- `RegistrationRequest`, `Registration`
- `EventRegistrationRequest`

These models handle API-level validation and serialization.

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system-essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*


### Property Reflection

After reviewing the prework analysis, several properties can be consolidated:

- Properties 1.4 and 7.4 both test exception-to-HTTP-status-code mapping (consolidated into Property 1)
- Properties 7.2 and 7.5 both test AWS error wrapping (consolidated into Property 2)
- Properties 4.5 and 8.4 both test HTTP status code preservation (consolidated into Property 3)
- Properties 4.1-4.4 test behavioral equivalence for different HTTP methods (consolidated into Property 3)

### Correctness Properties

Property 1: Service functions return domain objects or raise domain exceptions
*For any* service function call with valid inputs, the function should either return an instance of a domain model class or raise an exception that inherits from DomainException
**Validates: Requirements 1.3**

Property 2: Repository functions return domain objects or None
*For any* repository function call, the function should return either a domain model instance, None (for not-found cases), or raise a domain exception
**Validates: Requirements 2.4**

Property 3: API behavioral equivalence after refactoring
*For any* API endpoint and valid request, the refactored implementation should return the same HTTP status code and response body structure as the original implementation
**Validates: Requirements 4.1, 4.2, 4.3, 4.4, 4.5, 8.4**

Property 4: Domain exceptions map to appropriate HTTP status codes
*For any* domain exception raised in the service layer, the API handler should translate it to the correct HTTP status code (404 for ResourceNotFoundError, 409 for ResourceAlreadyExistsError, 500 for RepositoryError)
**Validates: Requirements 1.4, 7.4**

Property 5: Repository operations with reserved keywords succeed
*For any* DynamoDB operation involving reserved keywords (status, date, location, capacity, name), the repository should handle expression attribute names internally and complete the operation successfully
**Validates: Requirements 2.5**

Property 6: AWS ClientError exceptions are wrapped in domain exceptions
*For any* AWS ClientError that occurs during repository operations, the repository should catch it and raise a corresponding domain exception
**Validates: Requirements 7.2, 7.5**

Property 7: Domain exceptions propagate through service layer
*For any* domain exception raised in a repository, the service layer should allow it to propagate to the API layer without modification
**Validates: Requirements 7.3**

Property 8: Validation occurs at both API and service layers
*For any* invalid input, both the API layer (via Pydantic) and service layer (via business rules) should enforce their respective validation rules
**Validates: Requirements 5.5**

Property 9: Custom exception types are raised for domain errors
*For any* domain error condition (not found, already exists, capacity exceeded), the system should raise the appropriate custom exception class
**Validates: Requirements 7.1**

## Error Handling

### Exception Hierarchy

```python
DomainException (base)
├── ResourceNotFoundError
├── ResourceAlreadyExistsError
├── CapacityExceededError
└── RepositoryError
```

### Exception Translation

**Repository Layer:**
- Catches `boto3.exceptions.ClientError`
- Translates to `RepositoryError` with descriptive message
- Preserves original error context for logging

**Service Layer:**
- Raises domain-specific exceptions (`ResourceNotFoundError`, `ResourceAlreadyExistsError`, `CapacityExceededError`)
- Allows repository exceptions to propagate
- Does not catch or translate exceptions

**API Layer:**
- Catches `ResourceNotFoundError` → Returns 404
- Catches `ResourceAlreadyExistsError` → Returns 409
- Catches `CapacityExceededError` → Returns 409
- Catches `RepositoryError` → Returns 500
- Catches `DomainException` (catch-all) → Returns 500

### Error Response Format

All error responses maintain the current format:
```json
{
  "detail": "Error message"
}
```

## Testing Strategy

### Unit Testing

Unit tests will verify individual components in isolation:

**Repository Tests:**
- Test CRUD operations with mock DynamoDB table
- Verify reserved keyword handling
- Test exception translation from AWS errors
- Verify domain object construction from DynamoDB items

**Service Tests:**
- Test business logic with mock repositories
- Verify domain exception raising for error conditions
- Test orchestration across multiple repositories
- Verify business rule enforcement

**API Handler Tests:**
- Test request validation
- Verify exception-to-HTTP-status-code mapping
- Test model conversion (API models ↔ domain models)
- Verify dependency injection

### Property-Based Testing

Property-based tests will verify universal properties using the `hypothesis` library for Python:

**Test Configuration:**
- Minimum 100 iterations per property test
- Use custom generators for domain models
- Test with various valid and invalid inputs

**Property Test Implementation:**
- Each property test must include a comment with the format: `**Feature: code-organization, Property {number}: {property_text}**`
- Tests will use hypothesis strategies to generate random inputs
- Tests will verify properties hold across all generated inputs

### Integration Testing

Integration tests will verify end-to-end functionality:

**API Integration Tests:**
- Test complete request-response cycles
- Verify database state changes
- Test with real DynamoDB Local or mocked table
- Compare behavior with original implementation

**Behavioral Equivalence Tests:**
- Run identical test suites against original and refactored code
- Verify responses match exactly
- Test all endpoints with various inputs
- Verify error cases produce identical results

### Testing Approach

1. **Test-After-Implementation**: Implement the refactored structure first, then write tests to verify correctness
2. **Behavioral Equivalence**: Use existing API tests as a baseline to ensure no regression
3. **Incremental Verification**: Test each layer independently before integration testing
4. **Mock Dependencies**: Use mocks for unit tests, real dependencies for integration tests

## Migration Strategy

### Incremental Refactoring Approach

1. **Create new module structure** without modifying `main.py`
2. **Extract models** into `models/domain.py` and `models/api.py`
3. **Implement repositories** with full DynamoDB operations
4. **Implement services** using repositories
5. **Create route handlers** using services
6. **Update `main.py`** to import and register routes
7. **Verify all endpoints** work identically
8. **Remove old code** from `main.py`

### Backward Compatibility

- All existing API endpoints remain at the same paths
- Request and response schemas unchanged
- HTTP status codes preserved
- Query parameters unchanged
- Error response format maintained

### Deployment Considerations

- Refactoring is code-only, no database schema changes
- No API contract changes, so no client updates needed
- Can be deployed as a standard application update
- Rollback is straightforward (revert to previous version)

## Implementation Notes

### DynamoDB Key Patterns

The refactored code will maintain the existing DynamoDB key patterns:

**Events:**
- PK: `EVENT#{event_id}`, SK: `METADATA`

**Users:**
- PK: `USER#{user_id}`, SK: `PROFILE`

**Registrations:**
- PK: `USER#{user_id}`, SK: `EVENT#{event_id}` (user → event lookup)
- PK: `EVENT#{event_id}`, SK: `REGISTRATION#{user_id}` (event → user lookup)

**Waitlist:**
- PK: `EVENT#{event_id}`, SK: `WAITLIST#{timestamp}#{user_id}`

### Reserved Keyword Handling

Repositories will internally handle DynamoDB reserved keywords:
- `status`, `date`, `location`, `capacity`, `name`

All operations will use `ExpressionAttributeNames` to avoid conflicts.

### Dependency Injection

FastAPI's `Depends()` will be used for dependency injection:
- Configuration injected into repository factories
- Repositories injected into services
- Services injected into route handlers
- Enables easy testing with mocks

### Code Reuse

Shared utilities will be extracted to `utils.py`:
- `get_timestamp()` - ISO timestamp generation
- Any other common helper functions

### FastAPI Application Structure

The `main.py` file will be simplified to:
- App initialization
- CORS middleware configuration
- Route registration
- Lambda handler export

All business logic will be removed from `main.py`.
