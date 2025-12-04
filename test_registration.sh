#!/bin/bash

API_URL="https://knknpcjjz7.execute-api.us-west-2.amazonaws.com/prod"

echo "========================================="
echo "Testing User Registration API"
echo "========================================="
echo ""

# Test 1: Create a user
echo "Test 1: Create User"
echo "POST $API_URL/users"
curl -X POST "$API_URL/users" \
  -H "Content-Type: application/json" \
  -d '{
    "userId": "user-001",
    "name": "Alice Johnson"
  }'
echo -e "\n"

# Test 2: Get user
echo "Test 2: Get User"
echo "GET $API_URL/users/user-001"
curl -X GET "$API_URL/users/user-001"
echo -e "\n"

# Test 3: Create another user
echo "Test 3: Create Another User"
echo "POST $API_URL/users"
curl -X POST "$API_URL/users" \
  -H "Content-Type: application/json" \
  -d '{
    "userId": "user-002",
    "name": "Bob Smith"
  }'
echo -e "\n"

# Test 4: Create an event with capacity and waitlist
echo "Test 4: Create Event with Capacity"
echo "POST $API_URL/events"
curl -X POST "$API_URL/events" \
  -H "Content-Type: application/json" \
  -d '{
    "eventId": "event-001",
    "title": "Tech Conference 2024",
    "description": "Annual technology conference",
    "date": "2024-12-20",
    "location": "San Francisco",
    "capacity": 2,
    "organizer": "Tech Corp",
    "status": "active",
    "waitlistEnabled": true
  }'
echo -e "\n"

# Test 5: Register first user for event
echo "Test 5: Register User 1 for Event"
echo "POST $API_URL/registrations"
curl -X POST "$API_URL/registrations" \
  -H "Content-Type: application/json" \
  -d '{
    "userId": "user-001",
    "eventId": "event-001"
  }'
echo -e "\n"

# Test 6: Register second user for event
echo "Test 6: Register User 2 for Event"
echo "POST $API_URL/registrations"
curl -X POST "$API_URL/registrations" \
  -H "Content-Type: application/json" \
  -d '{
    "userId": "user-002",
    "eventId": "event-001"
  }'
echo -e "\n"

# Test 7: Create third user
echo "Test 7: Create Third User"
echo "POST $API_URL/users"
curl -X POST "$API_URL/users" \
  -H "Content-Type: application/json" \
  -d '{
    "userId": "user-003",
    "name": "Charlie Brown"
  }'
echo -e "\n"

# Test 8: Try to register third user (should be waitlisted)
echo "Test 8: Register User 3 for Event (Should be Waitlisted)"
echo "POST $API_URL/registrations"
curl -X POST "$API_URL/registrations" \
  -H "Content-Type: application/json" \
  -d '{
    "userId": "user-003",
    "eventId": "event-001"
  }'
echo -e "\n"

# Test 9: Get user 1's events
echo "Test 9: Get User 1's Events"
echo "GET $API_URL/users/user-001/events"
curl -X GET "$API_URL/users/user-001/events"
echo -e "\n"

# Test 10: Get user 3's events (should be empty since waitlisted)
echo "Test 10: Get User 3's Events (Should be Empty)"
echo "GET $API_URL/users/user-003/events"
curl -X GET "$API_URL/users/user-003/events"
echo -e "\n"

# Test 11: Unregister user 1 (should promote user 3 from waitlist)
echo "Test 11: Unregister User 1 (Should Promote User 3)"
echo "DELETE $API_URL/registrations/user-001/event-001"
curl -X DELETE "$API_URL/registrations/user-001/event-001"
echo -e "\n"

# Test 12: Get user 3's events again (should now have the event)
echo "Test 12: Get User 3's Events (Should Now Have Event)"
echo "GET $API_URL/users/user-003/events"
curl -X GET "$API_URL/users/user-003/events"
echo -e "\n"

# Test 13: Get event details to verify current registrations
echo "Test 13: Get Event Details"
echo "GET $API_URL/events/event-001"
curl -X GET "$API_URL/events/event-001"
echo -e "\n"

# Test 14: Try to register duplicate (should fail)
echo "Test 14: Try Duplicate Registration (Should Fail)"
echo "POST $API_URL/registrations"
curl -X POST "$API_URL/registrations" \
  -H "Content-Type: application/json" \
  -d '{
    "userId": "user-002",
    "eventId": "event-001"
  }'
echo -e "\n"

# Test 15: Create event without waitlist
echo "Test 15: Create Event Without Waitlist"
echo "POST $API_URL/events"
curl -X POST "$API_URL/events" \
  -H "Content-Type: application/json" \
  -d '{
    "eventId": "event-002",
    "title": "Workshop",
    "description": "Small workshop",
    "date": "2024-12-25",
    "location": "Seattle",
    "capacity": 1,
    "organizer": "Workshop Inc",
    "status": "active",
    "waitlistEnabled": false
  }'
echo -e "\n"

# Test 16: Register user for event without waitlist
echo "Test 16: Register User for Event Without Waitlist"
echo "POST $API_URL/registrations"
curl -X POST "$API_URL/registrations" \
  -H "Content-Type: application/json" \
  -d '{
    "userId": "user-001",
    "eventId": "event-002"
  }'
echo -e "\n"

# Test 17: Try to register when full and no waitlist (should fail)
echo "Test 17: Try to Register When Full (Should Fail)"
echo "POST $API_URL/registrations"
curl -X POST "$API_URL/registrations" \
  -H "Content-Type: application/json" \
  -d '{
    "userId": "user-002",
    "eventId": "event-002"
  }'
echo -e "\n"

echo "========================================="
echo "All tests completed!"
echo "========================================="
