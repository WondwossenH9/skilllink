#!/bin/bash

# SkillLink AWS Deployment Script
# This script deploys the entire SkillLink application to AWS

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

echo -e "${BLUE}🚀 SkillLink AWS Deployment Script${NC}"
echo "======================================"

# Check prerequisites
echo -e "${YELLOW}🔍 Checking prerequisites...${NC}"

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo -e "${RED}❌ AWS CLI is not installed. Please install it first.${NC}"
  exit 1
fi

# Check if Terraform is installed
if ! command -v terraform &> /dev/null; then
    echo -e "${RED}❌ Terraform is not installed. Please install it first.${NC}"
    exit 1
fi

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo -e "${RED}❌ Node.js is not installed. Please install it first.${NC}"
    exit 1
fi

# Check if npm is installed
if ! command -v npm &> /dev/null; then
    echo -e "${RED}❌ npm is not installed. Please install it first.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ All prerequisites are met${NC}"

# Check AWS credentials
echo -e "${YELLOW}🔐 Checking AWS credentials...${NC}"
if ! aws sts get-caller-identity &> /dev/null; then
    echo -e "${RED}❌ AWS credentials not configured. Please run 'aws configure' first.${NC}"
      exit 1
    fi

AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
AWS_REGION=$(aws configure get region)
echo -e "${GREEN}✅ AWS credentials configured for account: $AWS_ACCOUNT_ID in region: $AWS_REGION${NC}"

# Load configuration
if [ ! -f ".env.deployment" ]; then
    echo -e "${YELLOW}📝 Creating deployment configuration file...${NC}"
    cat > .env.deployment << 'ENV_EOF'
# SkillLink Deployment Configuration
# Update these values before running the deployment

# AWS Configuration
AWS_REGION=us-east-1
PROJECT_NAME=skilllink

# Domain Configuration
DOMAIN_NAME=skilllink.example.com
CERTIFICATE_EMAIL=admin@example.com

# EC2 Configuration
KEY_PAIR_NAME=skilllink-key
INSTANCE_TYPE=t3.micro

# Database Configuration
DB_NAME=skilllink
DB_USERNAME=skilllink_admin
DB_PASSWORD=ChangeMe123!

# Security
ALLOWED_SSH_CIDR=0.0.0.0/0

# Frontend Configuration
FRONTEND_DOMAIN=skilllink.example.com
ENV_EOF

    echo -e "${YELLOW}⚠️  Please edit .env.deployment with your actual values before continuing${NC}"
    echo -e "${YELLOW}   Press Enter when ready to continue...${NC}"
    read -r
fi

# Source deployment environment
source .env.deployment

# Validate configuration
echo -e "${YELLOW}🔍 Validating configuration...${NC}"
if [ "$DOMAIN_NAME" = "skilllink.example.com" ]; then
    echo -e "${RED}❌ Please update DOMAIN_NAME in .env.deployment${NC}"
    exit 1
fi

if [ "$DB_PASSWORD" = "ChangeMe123!" ]; then
    echo -e "${RED}❌ Please update DB_PASSWORD in .env.deployment${NC}"
    exit 1
fi

if [ "$ALLOWED_SSH_CIDR" = "0.0.0.0/0" ]; then
    echo -e "${YELLOW}⚠️  Warning: ALLOWED_SSH_CIDR is set to 0.0.0.0/0 (allows SSH from anywhere)${NC}"
    echo -e "${YELLOW}   Press Enter to continue or Ctrl+C to abort...${NC}"
    read -r
fi

echo -e "${GREEN}✅ Configuration validated${NC}"

# Create EC2 key pair if it doesn't exist
echo -e "${YELLOW}🔑 Checking EC2 key pair...${NC}"
if ! aws ec2 describe-key-pairs --key-names "$KEY_PAIR_NAME" &> /dev/null; then
    echo -e "${YELLOW}📝 Creating EC2 key pair: $KEY_PAIR_NAME${NC}"
    aws ec2 create-key-pair --key-name "$KEY_PAIR_NAME" --query 'KeyMaterial' --output text > "$KEY_PAIR_NAME.pem"
    chmod 400 "$KEY_PAIR_NAME.pem"
    echo -e "${GREEN}✅ Key pair created: $KEY_PAIR_NAME.pem${NC}"
    echo -e "${YELLOW}⚠️  Keep this file secure! You'll need it to SSH to your EC2 instance${NC}"
else
    echo -e "${GREEN}✅ Key pair already exists: $KEY_PAIR_NAME${NC}"
fi

# Build frontend
echo -e "${YELLOW}🏗️  Building frontend...${NC}"
cd ../frontend

# Install dependencies
echo -e "${BLUE}📦 Installing frontend dependencies...${NC}"
npm ci

# Build the application
echo -e "${BLUE}🔨 Building frontend application...${NC}"
npm run build

if [ ! -d "build" ]; then
    echo -e "${RED}❌ Frontend build failed${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Frontend built successfully${NC}"
cd "$SCRIPT_DIR"

# Deploy infrastructure with Terraform
echo -e "${YELLOW}🏗️  Deploying AWS infrastructure with Terraform...${NC}"
cd terraform

# Initialize Terraform
echo -e "${BLUE}🔧 Initializing Terraform...${NC}"
terraform init

# Plan the deployment
echo -e "${BLUE}📋 Planning Terraform deployment...${NC}"
terraform plan -var="aws_region=$AWS_REGION" \
               -var="project_name=$PROJECT_NAME" \
               -var="allowed_ssh_cidr=$ALLOWED_SSH_CIDR" \
               -var="domain_name=$DOMAIN_NAME" \
               -var="key_pair_name=$KEY_PAIR_NAME" \
               -var="db_name=$DB_NAME" \
               -var="db_username=$DB_USERNAME" \
               -var="db_password=$DB_PASSWORD" \
               -var="instance_type=$INSTANCE_TYPE"

echo -e "${YELLOW}⚠️  Review the plan above. Press Enter to apply or Ctrl+C to abort...${NC}"
read -r

# Apply the deployment
echo -e "${BLUE}🚀 Applying Terraform deployment...${NC}"
terraform apply -auto-approve \
                -var="aws_region=$AWS_REGION" \
                -var="project_name=$PROJECT_NAME" \
                -var="allowed_ssh_cidr=$ALLOWED_SSH_CIDR" \
                -var="domain_name=$DOMAIN_NAME" \
                -var="key_pair_name=$KEY_PAIR_NAME" \
                -var="db_name=$DB_NAME" \
                -var="db_username=$DB_USERNAME" \
                -var="db_password=$DB_PASSWORD" \
                -var="instance_type=$INSTANCE_TYPE"

# Get outputs
echo -e "${BLUE}📊 Getting deployment outputs...${NC}"
FRONTEND_BUCKET=$(terraform output -raw frontend_bucket_name)
BACKEND_PUBLIC_IP=$(terraform output -raw backend_public_ip)
RDS_ENDPOINT=$(terraform output -raw rds_endpoint)
ALB_DNS_NAME=$(terraform output -raw alb_dns_name)

cd "$SCRIPT_DIR"

# Deploy frontend to S3
echo -e "${YELLOW}📤 Deploying frontend to S3...${NC}"
aws s3 sync ../frontend/build/ "s3://$FRONTEND_BUCKET" --delete

echo -e "${GREEN}✅ Frontend deployed to S3 bucket: $FRONTEND_BUCKET${NC}"

# Wait for EC2 instance to be ready
echo -e "${YELLOW}⏳ Waiting for EC2 instance to be ready...${NC}"
aws ec2 wait instance-status-ok --instance-ids $(aws ec2 describe-instances --filters "Name=tag:Name,Values=$PROJECT_NAME-backend" --query 'Reservations[].Instances[].InstanceId' --output text)

echo -e "${GREEN}✅ EC2 instance is ready${NC}"

# Wait for RDS to be available
echo -e "${YELLOW}⏳ Waiting for RDS instance to be available...${NC}"
aws rds wait db-instance-available --db-instance-identifier "$PROJECT_NAME-db"

echo -e "${GREEN}✅ RDS instance is available${NC}"

# Test backend connectivity
echo -e "${YELLOW}🧪 Testing backend connectivity...${NC}"
sleep 30  # Give the instance time to finish bootstrapping

# Test health endpoint
if curl -f "http://$BACKEND_PUBLIC_IP/health" &> /dev/null; then
    echo -e "${GREEN}✅ Backend health check passed${NC}"
else
    echo -e "${YELLOW}⚠️  Backend health check failed, checking logs...${NC}"
    # SSH to instance and check logs
    ssh -i "$KEY_PAIR_NAME.pem" -o StrictHostKeyChecking=no ubuntu@"$BACKEND_PUBLIC_IP" "pm2 logs --lines 20"
fi

# Test ALB
echo -e "${YELLOW}🧪 Testing Application Load Balancer...${NC}"
if curl -f "http://$ALB_DNS_NAME/health" &> /dev/null; then
    echo -e "${GREEN}✅ ALB health check passed${NC}"
else
    echo -e "${YELLOW}⚠️  ALB health check failed${NC}"
fi

# Create deployment summary
echo -e "${GREEN}🎉 Deployment completed successfully!${NC}"
echo ""
echo -e "${BLUE}📊 Deployment Summary:${NC}"
echo "======================================"
echo -e "🌐 Frontend URL: https://$DOMAIN_NAME"
echo -e "🔗 Backend API: https://$ALB_DNS_NAME/api"
echo -e "🏠 Backend Server: $BACKEND_PUBLIC_IP"
echo -e "🗄️  Database: $RDS_ENDPOINT"
echo -e "📦 S3 Bucket: $FRONTEND_BUCKET"
echo ""
echo -e "${BLUE}🔑 Access Information:${NC}"
echo "======================================"
echo -e "SSH to backend: ssh -i $KEY_PAIR_NAME.pem ubuntu@$BACKEND_PUBLIC_IP"
echo -e "Health check: http://$BACKEND_PUBLIC_IP/health"
echo -e "Status page: http://$BACKEND_PUBLIC_IP/status.html"
echo ""
echo -e "${BLUE}📝 Next Steps:${NC}"
echo "======================================"
echo "1. Update your DNS to point $DOMAIN_NAME to the CloudFront distribution"
echo "2. Wait for ACM certificate validation (check AWS Console)"
echo "3. Test the full application end-to-end"
echo "4. Monitor logs and performance"
echo ""
echo -e "${GREEN}🚀 SkillLink is now running on AWS!${NC}"

# Save deployment info
cat > deployment-info.txt << EOF
SkillLink AWS Deployment Information
====================================
Deployment Date: $(date)
Frontend URL: https://$DOMAIN_NAME
Backend API: https://$ALB_DNS_NAME/api
Backend Server: $BACKEND_PUBLIC_IP
Database: $RDS_ENDPOINT
S3 Bucket: $FRONTEND_BUCKET
SSH Command: ssh -i $KEY_PAIR_NAME.pem ubuntu@$BACKEND_PUBLIC_IP
EOF

echo -e "${GREEN}📄 Deployment information saved to deployment-info.txt${NC}"
