---
inclusion: fileMatch
fileMatchPattern: '**/*api*.{py,ts,js}|**/main.py|**/routes/**/*.py'
---

# REST API Standards and Conventions

This steering file defines REST API standards for the Events Management API project. Apply these conventions when creating or modifying API endpoints.

## HTTP Methods

Use standard HTTP methods with their intended semantics:

- **GET** - Retrieve resources (read-only, idempotent, cacheable)
- **POST** - Create new resources (non-idempotent)
- **PUT** - Update entire resource (idempotent)
- **PATCH** - Partial update of resource (idempotent)
- **DELETE** - Remove resource (idempotent)

### Method Usage Examples

```python
@app.get("/events")           # List/retrieve
@app.post("/events")          # Create
@app.get("/events/{id}")      # Retrieve single
@app.put("/events/{id}")      # Full update
@app.patch("/events/{id}")    # Partial update (if needed)
@app.delete("/events/{id}")   # Delete
```

## HTTP Status Codes

Use appropriate status codes to indicate the result of operations:

### Success Codes (2xx)
- **200 OK** - Successful GET, PUT, PATCH, or DELETE
- **201 Created** - Successful POST that creates a resource
- **204 No Content** - Successful DELETE or operation with no response body

### Client Error Codes (4xx)
- **400 Bad Request** - Invalid request syntax or validation error
- **404 Not Found** - Resource doesn't exist
- **422 Unprocessable Entity** - Validation error (Pydantic)

### Server Error Codes (5xx)
- **500 Internal Server Error** - Unexpected server error

## URL Structure

Follow RESTful URL conventions:

```
GET    /events              # Collection
POST   /events              # Create in collection
GET    /events/{id}         # Single resource
PUT    /events/{id}         # Update resource
DELETE /events/{id}         # Delete resource
```

### URL Guidelines
- Use **plural nouns** for collections (`/events`, not `/event`)
- Use **lowercase** with hyphens for multi-word resources
- Keep URLs **simple and intuitive**
- Use **path parameters** for resource IDs
- Use **query parameters** for filtering, sorting, pagination

## JSON Response Format

### Success Response Structure

```json
{
  "field1": "value1",
  "field2": "value2"
}
```

For collections:
```json
[
  {"id": "1", "name": "Item 1"},
  {"id": "2", "name": "Item 2"}
]
```

### Error Response Structure

Use consistent error format:

```json
{
  "detail": "Error message describing what went wrong"
}
```

For validation errors (422):
```json
{
  "detail": [
    {
      "loc": ["body", "field_name"],
      "msg": "error message",
      "type": "error_type"
    }
  ]
}
```

## Field Naming Conventions

- Use **camelCase** for JSON field names (FastAPI default)
- Use **snake_case** for Python variables
- Be **consistent** across all endpoints
- Use **descriptive names** (avoid abbreviations)

Example:
```python
class Event(BaseModel):
    event_id: str        # Python: snake_case
    # JSON output: eventId (camelCase via alias or default)
```

## Query Parameters

For filtering and pagination:

```
GET /events?status=active           # Filter by status
GET /events?limit=10&offset=20      # Pagination (if implemented)
GET /events?sort=date&order=desc    # Sorting (if implemented)
```

## Request/Response Examples

### Create Resource (POST)

**Request:**
```http
POST /events
Content-Type: application/json

{
  "title": "Event Name",
  "date": "2025-12-25",
  "capacity": 100
}
```

**Response (201 Created):**
```json
{
  "eventId": "generated-uuid",
  "title": "Event Name",
  "date": "2025-12-25",
  "capacity": 100,
  "createdAt": "2025-12-04T10:00:00Z"
}
```

### Update Resource (PUT)

**Request:**
```http
PUT /events/{id}
Content-Type: application/json

{
  "title": "Updated Name",
  "capacity": 150
}
```

**Response (200 OK):**
```json
{
  "eventId": "existing-id",
  "title": "Updated Name",
  "capacity": 150,
  "updatedAt": "2025-12-04T11:00:00Z"
}
```

### Error Response

**Response (404 Not Found):**
```json
{
  "detail": "Event with ID abc123 not found"
}
```

## Validation Rules

- **Required fields** - Return 422 if missing
- **Type validation** - Ensure correct data types
- **Range validation** - Check min/max values
- **Format validation** - Validate dates, emails, etc.
- **Business rules** - Validate domain-specific constraints

## CORS Headers

For web API access, include CORS headers:

```python
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Restrict in production
    allow_methods=["*"],
    allow_headers=["*"],
)
```

## Content-Type

- **Request**: `Content-Type: application/json`
- **Response**: `Content-Type: application/json`

## Idempotency

- **GET, PUT, DELETE** - Must be idempotent
- **POST** - May not be idempotent (creates new resources)
- Consider supporting **idempotency keys** for POST if needed

## API Versioning (Future)

When versioning becomes necessary:
- Use URL versioning: `/v1/events`, `/v2/events`
- Or header versioning: `Accept: application/vnd.api.v1+json`

## Documentation

- Use **FastAPI's automatic documentation** (`/docs`, `/redoc`)
- Add **docstrings** to endpoint functions
- Include **examples** in Pydantic models
- Document **error cases**

## Quick Checklist

When creating/updating API endpoints:

- [ ] Use correct HTTP method
- [ ] Return appropriate status code
- [ ] Follow URL naming conventions
- [ ] Use consistent JSON structure
- [ ] Include proper error handling
- [ ] Add input validation
- [ ] Test with various inputs
- [ ] Update API documentation

## Notes

- This is a **prototype application** - focus on core REST principles
- Keep it **simple and consistent**
- Prioritize **developer experience**
- Follow **FastAPI best practices**
