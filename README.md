# Events Management API

A production-ready serverless REST API for managing events, built with FastAPI and deployed on AWS using Lambda, API Gateway, and DynamoDB.

## 🌟 Features

- ✅ Full CRUD operations for events
- ✅ Serverless architecture (Lambda + API Gateway + DynamoDB)
- ✅ DynamoDB reserved keywords properly handled
- ✅ Client-provided event IDs supported
- ✅ Status-based filtering
- ✅ CORS enabled for web access
- ✅ Comprehensive input validation (Pydantic v2)
- ✅ Automatic API documentation (Swagger UI + ReDoc)
- ✅ Pay-per-request pricing model

## 🏗️ Architecture

```
Client → API Gateway → Lambda (FastAPI) → DynamoDB
```

## 🚀 Quick Start

### Prerequisites

- AWS CLI configured
- Node.js 18+ and npm
- Python 3.12+
- Docker (running)
- AWS CDK CLI: `npm install -g aws-cdk`

### Deploy

```bash
./deploy.sh
```

### Test

```bash
./test_api.sh https://YOUR-API-URL/prod
```

## 📚 Documentation

### Live API
```
https://knknpcjjz7.execute-api.us-west-2.amazonaws.com/prod/
```

### Documentation
- **Swagger UI**: [/docs](https://knknpcjjz7.execute-api.us-west-2.amazonaws.com/prod/docs)
- **ReDoc**: [/redoc](https://knknpcjjz7.execute-api.us-west-2.amazonaws.com/prod/redoc)
- **HTML Docs**: [backend/docs/index.html](backend/docs/index.html)

## 📖 API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/events` | List all events |
| GET | `/events?status=active` | Filter by status |
| POST | `/events` | Create event |
| GET | `/events/{id}` | Get event |
| PUT | `/events/{id}` | Update event |
| DELETE | `/events/{id}` | Delete event |

## 💡 Example Usage

```bash
# Create event
curl -X POST https://YOUR-API-URL/prod/events \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Tech Conference",
    "description": "Annual tech event",
    "date": "2025-06-15",
    "location": "San Francisco",
    "capacity": 500,
    "organizer": "Tech Corp",
    "status": "active"
  }'

# List events
curl https://YOUR-API-URL/prod/events

# Filter by status
curl https://YOUR-API-URL/prod/events?status=active
```

## 🛠️ Local Development

```bash
cd backend
pip install -r requirements.txt
export EVENTS_TABLE_NAME=EventsTable
uvicorn main:app --reload
```

Visit http://localhost:8000/docs

## 💰 Cost

- Low traffic: **< $1/month**
- Medium traffic: **~$35/month**

## 🧹 Cleanup

```bash
cd infrastructure
cdk destroy
```

## 📄 License

MIT
