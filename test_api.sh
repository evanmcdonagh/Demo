#!/bin/bash

# Events API Testing Script

if [ -z "$1" ]; then
    echo "Usage: ./test_api.sh <API_URL>"
    echo "Example: ./test_api.sh https://abc123.execute-api.us-east-1.amazonaws.com/prod"
    exit 1
fi

API_URL=$1
echo "Testing Events API at: $API_URL"
echo "========================================="
echo ""

# Test 1: GET /events (Expected: 200)
echo "Test 1: GET /events"
echo "Expected Status: 200"
HTTP_CODE=$(curl -s -o /tmp/response.json -w "%{http_code}" "$API_URL/events")
echo "Actual Status: $HTTP_CODE"
cat /tmp/response.json | python3 -m json.tool 2>/dev/null || cat /tmp/response.json
echo -e "\n"

# Test 2: GET /events?status=active (Expected: 200)
echo "Test 2: GET /events?status=active"
echo "Expected Status: 200"
HTTP_CODE=$(curl -s -o /tmp/response.json -w "%{http_code}" "$API_URL/events?status=active")
echo "Actual Status: $HTTP_CODE"
cat /tmp/response.json | python3 -m json.tool 2>/dev/null || cat /tmp/response.json
echo -e "\n"

# Test 3: POST /events (Expected: 201)
echo "Test 3: POST /events"
echo "Expected Status: 201"
echo "Request Body:"
cat << 'EOF' | python3 -m json.tool
{
  "date": "2024-12-15",
  "eventId": "api-test-event-456",
  "organizer": "API Test Organizer",
  "description": "Testing API Gateway integration",
  "location": "API Test Location",
  "title": "API Gateway Test Event",
  "capacity": 200,
  "status": "active"
}
EOF
HTTP_CODE=$(curl -s -o /tmp/response.json -w "%{http_code}" -X POST "$API_URL/events" \
  -H "Content-Type: application/json" \
  -d '{
    "date": "2024-12-15",
    "eventId": "api-test-event-456",
    "organizer": "API Test Organizer",
    "description": "Testing API Gateway integration",
    "location": "API Test Location",
    "title": "API Gateway Test Event",
    "capacity": 200,
    "status": "active"
  }')
echo "Actual Status: $HTTP_CODE"
cat /tmp/response.json | python3 -m json.tool 2>/dev/null || cat /tmp/response.json
echo -e "\n"

# Test 4: GET /events/api-test-event-456 (Expected: 200)
echo "Test 4: GET /events/api-test-event-456"
echo "Expected Status: 200"
HTTP_CODE=$(curl -s -o /tmp/response.json -w "%{http_code}" "$API_URL/events/api-test-event-456")
echo "Actual Status: $HTTP_CODE"
cat /tmp/response.json | python3 -m json.tool 2>/dev/null || cat /tmp/response.json
echo -e "\n"

# Test 5: PUT /events/api-test-event-456 (Expected: 200)
echo "Test 5: PUT /events/api-test-event-456"
echo "Expected Status: 200"
echo "Request Body:"
cat << 'EOF' | python3 -m json.tool
{
  "title": "Updated API Gateway Test Event",
  "capacity": 250
}
EOF
HTTP_CODE=$(curl -s -o /tmp/response.json -w "%{http_code}" -X PUT "$API_URL/events/api-test-event-456" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Updated API Gateway Test Event",
    "capacity": 250
  }')
echo "Actual Status: $HTTP_CODE"
cat /tmp/response.json | python3 -m json.tool 2>/dev/null || cat /tmp/response.json
echo -e "\n"

# Test 6: DELETE /events/api-test-event-456 (Expected: 200 or 204)
echo "Test 6: DELETE /events/api-test-event-456"
echo "Expected Status: 200, 204"
HTTP_CODE=$(curl -s -o /tmp/response.json -w "%{http_code}" -X DELETE "$API_URL/events/api-test-event-456")
echo "Actual Status: $HTTP_CODE"
if [ -s /tmp/response.json ]; then
    cat /tmp/response.json | python3 -m json.tool 2>/dev/null || cat /tmp/response.json
fi
echo -e "\n"

echo "========================================="
echo "✅ All tests completed!"
echo "========================================="
echo ""
echo "Summary:"
echo "- All endpoints tested according to specification"
echo "- Check status codes above to verify expected behavior"
