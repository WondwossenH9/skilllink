#!/bin/bash

# Frontend deployment script for S3

set -e

echo "🌐 Deploying SkillLink Frontend to S3"
echo "==================================="

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Check if .env.deployment exists
if [ ! -f .env.deployment ]; then
    echo -e "${RED}❌ .env.deployment file not found. Run ./deploy.sh first.${NC}"
    exit 1
fi

# Source deployment environment
source .env.deployment

# Check if bucket name is set
if [ -z "$BUCKET_NAME" ]; then
    echo -e "${RED}❌ BUCKET_NAME not found in .env.deployment${NC}"
    exit 1
fi

# Build frontend
echo "🏗️ Building frontend..."
cd ../frontend

# Create production environment file
cat > .env.production << EOL
REACT_APP_API_URL=http://$PUBLIC_IP:3001/api
EOL

# Install dependencies and build
npm install
npm run build

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Frontend build failed${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Frontend build completed${NC}"

# Deploy to S3
echo "☁️ Uploading to S3..."
aws s3 sync build/ s3://$BUCKET_NAME --delete

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Frontend deployed successfully${NC}"
    echo ""
    echo "🌍 Your frontend is available at:"
    echo "http://$BUCKET_NAME.s3-website-us-east-1.amazonaws.com"
    echo ""
else
    echo -e "${RED}❌ Frontend deployment failed${NC}"
    exit 1
fi

cd ../infrastructure
