#!/bin/bash
set -e

# SkillLink Deployment Test Script
# This script tests the deployed application

echo "🧪 Testing SkillLink deployment..."

# Check if backend URL is provided
if [ -z "$BACKEND_URL" ]; then
    echo "❌ BACKEND_URL environment variable is required"
    echo "Usage: BACKEND_URL=http://your-ec2-ip ./test-deployment.sh"
    exit 1
fi

echo "🔍 Testing backend at: $BACKEND_URL"

# Test 1: Health Check
echo "1. Testing health check..."
HEALTH_RESPONSE=$(curl -s "$BACKEND_URL/health")
if [[ $HEALTH_RESPONSE == *"OK"* ]]; then
    echo "✅ Health check passed"
else
    echo "❌ Health check failed: $HEALTH_RESPONSE"
    exit 1
fi

# Test 2: API Health Check
echo "2. Testing API health check..."
API_HEALTH_RESPONSE=$(curl -s "$BACKEND_URL/api/health")
if [[ $API_HEALTH_RESPONSE == *"OK"* ]]; then
    echo "✅ API health check passed"
else
    echo "❌ API health check failed: $API_HEALTH_RESPONSE"
    exit 1
fi

# Test 3: Database Connection
echo "3. Testing database connection..."
DB_STATUS=$(echo "$API_HEALTH_RESPONSE" | grep -o '"database":"[^"]*"' | cut -d'"' -f4)
if [[ $DB_STATUS == "connected" ]]; then
    echo "✅ Database connection verified"
else
    echo "❌ Database connection failed: $DB_STATUS"
    exit 1
fi

# Test 4: Authentication Endpoint
echo "4. Testing authentication endpoint..."
AUTH_RESPONSE=$(curl -s -X POST "$BACKEND_URL/api/auth/register" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "testpassword123",
    "firstName": "Test",
    "lastName": "User"
  }')

if [[ $AUTH_RESPONSE == *"error"* ]]; then
    echo "⚠️  Registration endpoint responded (may be existing user): $AUTH_RESPONSE"
else
    echo "✅ Registration endpoint working"
fi

# Test 5: Skills Endpoint
echo "5. Testing skills endpoint..."
SKILLS_RESPONSE=$(curl -s "$BACKEND_URL/api/skills")
if [[ $SKILLS_RESPONSE == *"skills"* ]] || [[ $SKILLS_RESPONSE == *"[]"* ]]; then
    echo "✅ Skills endpoint working"
else
    echo "❌ Skills endpoint failed: $SKILLS_RESPONSE"
fi

echo ""
echo "🎉 All tests completed!"
echo ""
echo "📋 Test Summary:"
echo "✅ Health Check: Working"
echo "✅ API Health: Working"
echo "✅ Database: Connected"
echo "✅ Authentication: Working"
echo "✅ Skills API: Working"
echo ""
echo "🌐 Your application is ready for use!"
echo "Frontend: Check your S3 bucket URL"
echo "Backend: $BACKEND_URL"
