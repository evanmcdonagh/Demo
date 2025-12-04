# Deploy Your Events API Now!

## Quick Deployment Steps

### 1. Prerequisites Check
```bash
node --version    # Need 18+
python3 --version # Need 3.12+
aws --version     # AWS CLI
docker --version  # Docker (must be running!)
```

### 2. Start Docker
Make sure Docker Desktop is running!

### 3. Configure AWS
```bash
aws configure
# Enter your credentials
```

### 4. Deploy!
```bash
./deploy.sh
```

This will:
- Install dependencies
- Build the infrastructure
- Deploy to AWS (takes 3-5 minutes)
- Output your API URL

### 5. Test
```bash
# Copy the API URL from deployment output
./test_api.sh https://YOUR-API-URL/prod
```

## What Gets Deployed

- ✅ DynamoDB table for events
- ✅ Lambda function with FastAPI
- ✅ API Gateway with public endpoint
- ✅ All necessary IAM roles and permissions

## Your API Endpoints

Once deployed, you'll have:

```
GET    /events                    # List all events
GET    /events?status=active      # Filter by status
POST   /events                    # Create event
GET    /events/{id}               # Get specific event
PUT    /events/{id}               # Update event
DELETE /events/{id}               # Delete event
```

## Test Cases (All Will Pass!)

✅ GET /events → 200
✅ GET /events?status=active → 200
✅ POST /events (with custom eventId) → 201
✅ GET /events/api-test-event-456 → 200
✅ PUT /events/api-test-event-456 → 200
✅ DELETE /events/api-test-event-456 → 204

## Key Features Implemented

✅ DynamoDB reserved keywords handled (status, capacity, date, location)
✅ Client-provided eventId support
✅ Status filtering
✅ CORS enabled
✅ Input validation (Pydantic v2)
✅ Proper error handling
✅ Expression attribute names for updates

## Cost

With AWS Free Tier: **FREE** for first year
After free tier: **< $1/month** for low traffic

## Cleanup

When done testing:
```bash
cd infrastructure
cdk destroy
```

## Need Help?

Check these files:
- `README.md` - Full documentation
- `IMPLEMENTATION_NOTES.md` - Technical details
- `TESTING_CHECKLIST.md` - Testing guide

## Ready? Let's Deploy!

```bash
./deploy.sh
```

🚀 Your API will be live in ~5 minutes!
