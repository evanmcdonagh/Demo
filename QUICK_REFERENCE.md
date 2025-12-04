# Quick Reference Card

## Deploy
```bash
./deploy.sh
```

## Test
```bash
./test_api.sh https://YOUR-API-URL/prod
```

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/events` | List all events |
| GET | `/events?status=active` | Filter by status |
| POST | `/events` | Create event |
| GET | `/events/{id}` | Get event |
| PUT | `/events/{id}` | Update event |
| DELETE | `/events/{id}` | Delete event |

## Test Data
```json
{
  "eventId": "api-test-event-456",
  "title": "API Gateway Test Event",
  "description": "Testing API Gateway integration",
  "date": "2024-12-15",
  "location": "API Test Location",
  "capacity": 200,
  "organizer": "API Test Organizer",
  "status": "active"
}
```

## Update Data
```json
{
  "title": "Updated API Gateway Test Event",
  "capacity": 250
}
```

## Expected Results
- GET /events → 200
- GET /events?status=active → 200
- POST /events → 201
- GET /events/api-test-event-456 → 200
- PUT /events/api-test-event-456 → 200
- DELETE /events/api-test-event-456 → 204

## Cleanup
```bash
cd infrastructure && cdk destroy
```

## Key Features
✅ DynamoDB reserved keywords handled
✅ Client-provided eventId
✅ Status filtering
✅ CORS enabled
✅ Pydantic v2 validation
✅ Expression attribute names

## Prerequisites
- Docker running
- AWS CLI configured
- Node.js 18+
- Python 3.12+
- AWS CDK installed
