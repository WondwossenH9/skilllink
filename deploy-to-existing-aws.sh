#!/bin/bash

# SkillLink Deployment to Existing AWS Infrastructure
# This script deploys to your existing EC2, S3, and RDS setup

set -e

echo "🚀 Deploying SkillLink to Existing AWS Infrastructure"
echo "====================================================="

# Load existing deployment configuration
if [[ -f infrastructure/.env.deployment ]]; then
    source infrastructure/.env.deployment
    echo "✅ Loaded existing deployment configuration"
else
    echo "❌ infrastructure/.env.deployment file not found"
    exit 1
fi

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Validate required variables
if [[ -z "$S3_BUCKET" || -z "$EC2_PUBLIC_IP" || -z "$DB_PASSWORD" ]]; then
    echo -e "${RED}❌ Missing required configuration variables${NC}"
    echo "Required: S3_BUCKET, EC2_PUBLIC_IP, DB_PASSWORD"
    exit 1
fi

echo -e "${GREEN}✅ Configuration validated${NC}"
echo "S3 Bucket: $S3_BUCKET"
echo "EC2 IP: $EC2_PUBLIC_IP"
echo "RDS Instance: $DB_INSTANCE_ID"

# Step 1: Build Frontend
echo -e "${YELLOW}📦 Building frontend...${NC}"
cd frontend
npm run build
cd ..

if [[ ! -d frontend/build ]]; then
    echo -e "${RED}❌ Frontend build failed${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Frontend built successfully${NC}"

# Step 2: Deploy Frontend to S3
echo -e "${YELLOW}📤 Deploying frontend to S3...${NC}"
aws s3 sync frontend/build "s3://$S3_BUCKET" --delete

echo -e "${GREEN}✅ Frontend deployed to S3${NC}"
echo -e "${GREEN}🌐 Frontend URL: http://$S3_BUCKET.s3-website-us-east-1.amazonaws.com${NC}"

# Step 3: Deploy Backend to EC2
echo -e "${YELLOW}💻 Deploying backend to EC2...${NC}"

# Create deployment package
echo -e "${YELLOW}📦 Creating deployment package...${NC}"
tar -czf backend-deploy.tar.gz backend/

# Upload to EC2
echo -e "${YELLOW}📤 Uploading to EC2...${NC}"
scp -i "skilllink-keypair-dev.pem" backend-deploy.tar.gz ec2-user@"$EC2_PUBLIC_IP":~/

# Deploy on EC2
echo -e "${YELLOW}🔧 Deploying on EC2...${NC}"
ssh -i "skilllink-keypair-dev.pem" ec2-user@"$EC2_PUBLIC_IP" << EOF
    # Stop existing process
    pm2 stop skilllink-backend 2>/dev/null || true
    pm2 delete skilllink-backend 2>/dev/null || true
    
    # Extract new deployment
    tar -xzf backend-deploy.tar.gz
    cd backend
    
    # Install dependencies
    npm install
    
    # Create environment file
    cat > .env << 'ENVEOF'
NODE_ENV=production
PORT=3001
JWT_SECRET=skilllink-super-secret-jwt-key-2024
DATABASE_URL=postgresql://$DB_USERNAME:$DB_PASSWORD@$DB_INSTANCE_ID.cqjqjqjqjqjq.us-east-1.rds.amazonaws.com:5432/$DB_NAME
ENVEOF
    
    # Start with PM2
    pm2 start src/server.js --name skilllink-backend
    pm2 save
    pm2 startup
EOF

# Clean up local files
rm -f backend-deploy.tar.gz

echo -e "${GREEN}✅ Backend deployed to EC2${NC}"
echo -e "${GREEN}🔗 Backend API: http://$EC2_PUBLIC_IP:3001/api${NC}"

# Step 4: Test Deployment
echo -e "${YELLOW}🧪 Testing deployment...${NC}"

# Test backend health
echo -n "Testing backend health... "
if curl -s "http://$EC2_PUBLIC_IP:3001/api/health" > /dev/null; then
    echo -e "${GREEN}✅ PASS${NC}"
else
    echo -e "${RED}❌ FAIL${NC}"
fi

# Test frontend
echo -n "Testing frontend... "
if curl -s "http://$S3_BUCKET.s3-website-us-east-1.amazonaws.com" > /dev/null; then
    echo -e "${GREEN}✅ PASS${NC}"
else
    echo -e "${RED}❌ FAIL${NC}"
fi

echo ""
echo -e "${GREEN}🎉 Deployment completed!${NC}"
echo ""
echo -e "${GREEN}📊 Deployment Summary:${NC}"
echo -e "Frontend: http://$S3_BUCKET.s3-website-us-east-1.amazonaws.com"
echo -e "Backend API: http://$EC2_PUBLIC_IP:3001/api"
echo -e "Health Check: http://$EC2_PUBLIC_IP:3001/api/health"
echo ""
echo -e "${YELLOW}⚠️  Remember to update the frontend environment variable:${NC}"
echo -e "REACT_APP_API_URL=http://$EC2_PUBLIC_IP:3001/api"
