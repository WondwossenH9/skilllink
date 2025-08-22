#!/bin/bash

# SkillLink Application Test Script
# Tests all features before AWS deployment

set -e

echo "🧪 Testing SkillLink Application"
echo "================================"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Test counters
PASSED=0
FAILED=0

# Test function
test_endpoint() {
    local name="$1"
    local url="$2"
    local expected_status="${3:-200}"
    
    echo -n "Testing $name... "
    
    if curl -s -f "$url" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ PASS${NC}"
        ((PASSED++))
    else
        echo -e "${RED}❌ FAIL${NC}"
        ((FAILED++))
    fi
}

# Check if servers are running
echo "📋 Checking server status..."

# Test backend health
test_endpoint "Backend Health" "http://localhost:3001/api/health"

# Test backend skills endpoint
test_endpoint "Skills API" "http://localhost:3001/api/skills"

# Test frontend
test_endpoint "Frontend" "http://localhost:3000"

echo ""
echo "📊 Test Results:"
echo "Passed: $PASSED"
echo "Failed: $FAILED"

if [[ $FAILED -eq 0 ]]; then
    echo -e "${GREEN}🎉 All tests passed! Application is ready for deployment.${NC}"
    exit 0
else
    echo -e "${RED}❌ Some tests failed. Please fix issues before deployment.${NC}"
    exit 1
fi
