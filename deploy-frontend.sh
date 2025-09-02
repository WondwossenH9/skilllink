#!/bin/bash
set -e

# SkillLink Frontend Deployment Script
# This script builds and deploys the frontend with proper environment configuration

PROJECT_NAME="skilllink"
AWS_REGION="us-east-1"
ENVIRONMENT="${1:-dev}"

echo "🚀 Starting SkillLink frontend deployment for $ENVIRONMENT environment..."

# Validate required environment variables
if [ -z "$BACKEND_URL" ]; then
    echo "❌ BACKEND_URL environment variable is required"
    echo "Usage: BACKEND_URL=https://your-backend-domain.com ./deploy-frontend.sh [environment]"
    exit 1
fi

# Build frontend with proper environment configuration
echo "📦 Building frontend..."
cd frontend

# Create production environment file
cat > .env.production <<EOF
REACT_APP_API_URL=${BACKEND_URL}/api
REACT_APP_ENV=production
REACT_APP_VERSION=1.0.0
EOF

echo "🔧 Environment configured:"
echo "  API URL: ${BACKEND_URL}/api"
echo "  Environment: production"

# Install dependencies and build
npm ci
npm run build

# Generate unique bucket name
TIMESTAMP=$(date +%s)
S3_BUCKET="${PROJECT_NAME}-frontend-${ENVIRONMENT}-${TIMESTAMP}"

# Create S3 bucket
echo "📦 Creating S3 bucket..."
aws s3 mb "s3://$S3_BUCKET" --region "$AWS_REGION" || {
  ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
  S3_BUCKET="${S3_BUCKET}-${ACCOUNT_ID}"
  aws s3 mb "s3://$S3_BUCKET" --region "$AWS_REGION"
}

# Configure S3 for static website hosting
aws s3api put-bucket-website --bucket "$S3_BUCKET" --website-configuration '{
  "IndexDocument": {"Suffix": "index.html"},
  "ErrorDocument": {"Key": "index.html"}
}'

# Make bucket publicly accessible for website hosting
aws s3api put-public-access-block --bucket "$S3_BUCKET" --public-access-block-configuration "BlockPublicAcls=false,IgnorePublicAcls=false,BlockPublicPolicy=false,RestrictPublicBuckets=false"

# Add bucket policy for public read access
aws s3api put-bucket-policy --bucket "$S3_BUCKET" --policy "{
    \"Version\": \"2012-10-17\",
    \"Statement\": [
        {
            \"Sid\": \"PublicReadGetObject\",
            \"Effect\": \"Allow\",
            \"Principal\": \"*\",
            \"Action\": \"s3:GetObject\",
            \"Resource\": \"arn:aws:s3:::$S3_BUCKET/*\"
        }
    ]
}"

# Upload frontend files
echo "📤 Uploading frontend files..."
aws s3 sync build "s3://$S3_BUCKET" --delete

# Clean up environment file
rm -f .env.production

cd ..

echo "✅ Frontend deployment completed successfully!"
echo ""
echo "📋 Deployment Summary:"
echo "Frontend URL: http://$S3_BUCKET.s3-website-$AWS_REGION.amazonaws.com"
echo "Backend API: ${BACKEND_URL}/api"
echo ""
echo "🔧 Next steps:"
echo "1. Update your backend deployment to use this frontend URL"
echo "2. Test the application by visiting the frontend URL"
echo "3. Consider setting up CloudFront for better performance and HTTPS"


