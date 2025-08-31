#!/bin/bash
set -e

# Test script for SkillLink deployment
echo "🧪 Testing SkillLink deployment..."

# Test backend health
echo "Testing backend health endpoint..."
BACKEND_URL="http://localhost:3001"
if curl -f "$BACKEND_URL/api/health" > /dev/null 2>&1; then
    echo "✅ Backend health check passed"
else
    echo "❌ Backend health check failed"
    exit 1
fi

# Test skills endpoint
echo "Testing skills endpoint..."
if curl -f "$BACKEND_URL/api/skills" > /dev/null 2>&1; then
    echo "✅ Skills endpoint working"
else
    echo "❌ Skills endpoint failed"
    exit 1
fi

# Test frontend build
echo "Testing frontend build..."
cd frontend
if npm run build > /dev/null 2>&1; then
    echo "✅ Frontend builds successfully"
else
    echo "❌ Frontend build failed"
    exit 1
fi
cd ..

echo "🎉 All tests passed! Deployment is ready."
