#!/bin/bash

# SkillLink Frontend Deployment Script
# This script builds and deploys the frontend to S3 and CloudFront

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo -e "${BLUE}🎨 SkillLink Frontend Deployment Script${NC}"
echo "============================================="

# Check if .env.deployment exists
if [ ! -f ".env.deployment" ]; then
    echo -e "${RED}❌ .env.deployment file not found. Run ./deploy.sh first.${NC}"
    exit 1
fi

# Source deployment environment
source .env.deployment

# Check required variables
if [ -z "$FRONTEND_DOMAIN" ] || [ -z "$AWS_REGION" ]; then
    echo -e "${RED}❌ Required deployment variables not found${NC}"
    exit 1
fi

echo -e "${YELLOW}🔍 Checking prerequisites...${NC}"

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo -e "${RED}❌ Node.js is not installed${NC}"
    exit 1
fi

# Check if npm is installed
if ! command -v npm &> /dev/null; then
    echo -e "${RED}❌ npm is not installed${NC}"
    exit 1
fi

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo -e "${RED}❌ AWS CLI is not installed${NC}"
    exit 1
fi

echo -e "${GREEN}✅ All prerequisites are met${NC}"

# Navigate to frontend directory
cd ../frontend

echo -e "${YELLOW}📦 Installing dependencies...${NC}"
npm ci

echo -e "${YELLOW}🔨 Building frontend application...${NC}"
npm run build

if [ ! -d "build" ]; then
    echo -e "${RED}❌ Frontend build failed${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Frontend built successfully${NC}"

# Get S3 bucket name from Terraform output
echo -e "${YELLOW}🔍 Getting S3 bucket name from Terraform...${NC}"
cd ../infrastructure/terraform

if [ ! -f "terraform.tfstate" ]; then
    echo -e "${RED}❌ Terraform state file not found. Run terraform apply first.${NC}"
    exit 1
fi

FRONTEND_BUCKET=$(terraform output -raw frontend_bucket_name 2>/dev/null || echo "")

if [ -z "$FRONTEND_BUCKET" ]; then
    echo -e "${RED}❌ Could not get S3 bucket name from Terraform${NC}"
    exit 1
fi

echo -e "${GREEN}✅ S3 bucket: $FRONTEND_BUCKET${NC}"

# Deploy to S3
echo -e "${YELLOW}📤 Deploying to S3...${NC}"
cd ../../frontend

aws s3 sync build/ "s3://$FRONTEND_BUCKET" --delete

echo -e "${GREEN}✅ Frontend deployed to S3 successfully${NC}"

# Invalidate CloudFront cache
echo -e "${YELLOW}🔄 Invalidating CloudFront cache...${NC}"
cd ../infrastructure/terraform

CLOUDFRONT_DISTRIBUTION_ID=$(terraform output -raw cloudfront_distribution_id 2>/dev/null || echo "")

if [ -n "$CLOUDFRONT_DISTRIBUTION_ID" ]; then
    aws cloudfront create-invalidation \
        --distribution-id "$CLOUDFRONT_DISTRIBUTION_ID" \
        --paths "/*"
    
    echo -e "${GREEN}✅ CloudFront cache invalidation initiated${NC}"
    echo -e "${YELLOW}⏳ Cache invalidation may take 5-10 minutes to complete${NC}"
else
    echo -e "${YELLOW}⚠️  Could not get CloudFront distribution ID${NC}"
fi

# Return to script directory
cd "$SCRIPT_DIR"

echo -e "${GREEN}🎉 Frontend deployment completed!${NC}"
echo ""
echo -e "${BLUE}📊 Deployment Summary:${NC}"
echo "======================================"
echo -e "🌐 Frontend URL: https://$FRONTEND_DOMAIN"
echo -e "📦 S3 Bucket: $FRONTEND_BUCKET"
if [ -n "$CLOUDFRONT_DISTRIBUTION_ID" ]; then
    echo -e "☁️  CloudFront Distribution: $CLOUDFRONT_DISTRIBUTION_ID"
fi
echo ""
echo -e "${BLUE}📝 Next Steps:${NC}"
echo "======================================"
echo "1. Wait for CloudFront cache invalidation to complete"
echo "2. Test the frontend at https://$FRONTEND_DOMAIN"
echo "3. Verify all functionality works correctly"
echo ""
echo -e "${GREEN}🚀 Frontend is now live on AWS!${NC}"
