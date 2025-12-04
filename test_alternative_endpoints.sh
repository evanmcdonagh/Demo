#!/bin/bash

API_URL="https://knknpcjjz7.execute-api.us-west-2.amazonaws.com/prod"

echo "========================================="
echo "Testing Alternative Registration Endpoints"
echo "========================================="
echo ""

# Setup: Create users and event
echo "Setup: Creating users and event"
curl -s -X POST "$API_URL/users" -H "Content-Type: application/json" -d '{"userId": "test-user-1", "name": "Test User 1"}' > /dev/null
curl -s -X POST "$API_URL/users" -H "Content-Type: application/json" -d '{"userId": "test-user-2", "name": "Test User 2"}' > /dev/null
curl -s -X POST "$API_URL/users" -H "Content-Type: application/json" -d '{"userId": "test-user-3", "name": "Test User 3"}' > /dev/null

curl -s -X POST "$API_URL/events" -H "Content-Type: application/json" -d '{
  "eventId": "test-event-1",
  "title": "Test Event",
  "description": "Test event for alternative endpoints",
  "date": "2024-12-30",
  "location": "Test Location",
  "capacity": 2,
  "organizer": "Test Organizer",
  "status": "active",
  "waitlistEnabled": true
}' > /dev/null

echo "Setup complete"
echo ""

# Test 1: POST /events/{id}/registrations - Register user 1
echo "Test 1: POST /events/test-event-1/registrations (User 1)"
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$API_URL/events/test-event-1/registrations" \
  -H "Content-Type: application/json" \
  -d '{"userId": "test-user-1"}')
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | head -n-1)
echo "Status: $HTTP_CODE"
echo "Response: $BODY"
if [ "$HTTP_CODE" = "201" ] || [ "$HTTP_CODE" = "200" ]; then
  echo "✅ PASS"
else
  echo "❌ FAIL"
fi
echo ""

# Test 2: POST /events/{id}/registrations - Register user 2 (fills capacity)
echo "Test 2: POST /events/test-event-1/registrations (User 2 - fills capacity)"
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$API_URL/events/test-event-1/registrations" \
  -H "Content-Type: application/json" \
  -d '{"userId": "test-user-2"}')
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | head -n-1)
echo "Status: $HTTP_CODE"
echo "Response: $BODY"
if [ "$HTTP_CODE" = "201" ] || [ "$HTTP_CODE" = "200" ]; then
  echo "✅ PASS"
else
  echo "❌ FAIL"
fi
echo ""

# Test 3: POST /events/{id}/registrations - Register user 3 (waitlisted)
echo "Test 3: POST /events/test-event-1/registrations (User 3 - should be waitlisted)"
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$API_URL/events/test-event-1/registrations" \
  -H "Content-Type: application/json" \
  -d '{"userId": "test-user-3"}')
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | head -n-1)
echo "Status: $HTTP_CODE"
echo "Response: $BODY"
if [ "$HTTP_CODE" = "201" ] || [ "$HTTP_CODE" = "200" ]; then
  echo "✅ PASS"
else
  echo "❌ FAIL"
fi
echo ""

# Test 4: GET /events/{id}/registrations
echo "Test 4: GET /events/test-event-1/registrations"
RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$API_URL/events/test-event-1/registrations")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | head -n-1)
echo "Status: $HTTP_CODE"
echo "Response: $BODY"
if [ "$HTTP_CODE" = "200" ]; then
  echo "✅ PASS"
else
  echo "❌ FAIL"
fi
echo ""

# Test 5: GET /users/{id}/registrations
echo "Test 5: GET /users/test-user-1/registrations"
RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$API_URL/users/test-user-1/registrations")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | head -n-1)
echo "Status: $HTTP_CODE"
echo "Response: $BODY"
if [ "$HTTP_CODE" = "200" ]; then
  echo "✅ PASS"
else
  echo "❌ FAIL"
fi
echo ""

# Test 6: DELETE /events/{id}/registrations/{userId}
echo "Test 6: DELETE /events/test-event-1/registrations/test-user-1"
RESPONSE=$(curl -s -w "\n%{http_code}" -X DELETE "$API_URL/events/test-event-1/registrations/test-user-1")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
echo "Status: $HTTP_CODE"
if [ "$HTTP_CODE" = "204" ] || [ "$HTTP_CODE" = "200" ]; then
  echo "✅ PASS"
else
  echo "❌ FAIL"
fi
echo ""

# Verify user 3 was promoted from waitlist
echo "Verification: Check if user 3 was promoted from waitlist"
RESPONSE=$(curl -s -X GET "$API_URL/users/test-user-3/events")
echo "User 3's events: $RESPONSE"
if echo "$RESPONSE" | grep -q "test-event-1"; then
  echo "✅ User 3 was promoted from waitlist"
else
  echo "⚠️  User 3 still on waitlist or not found"
fi
echo ""

echo "========================================="
echo "All alternative endpoint tests completed!"
echo "========================================="
