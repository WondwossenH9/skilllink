# SkillLink AWS Free Tier Deployment Guide

This guide walks you through deploying SkillLink to AWS using free tier resources.

## Prerequisites

1. **AWS Account**: Sign up for AWS if you don't have an account
2. **AWS CLI**: Install and configure with your credentials
   ```bash
   aws configure
   ```
3. **Node.js**: Version 16 or higher for local development

## Architecture Overview

- **Frontend**: React app hosted on S3 with static website hosting
- **Backend**: Node.js API running on EC2 t2.micro instance
- **Database**: PostgreSQL on RDS db.t3.micro instance
- **Total Cost**: Within AWS Free Tier limits for 12 months

## Quick Deployment

### Step 1: Clone and Setup
```bash
git clone <repository-url>
cd skilllink
```

### Step 2: Deploy Infrastructure
```bash
cd infrastructure
./deploy.sh
```

This script will create:
- S3 bucket for frontend hosting
- RDS PostgreSQL instance
- EC2 instance with security groups
- SSH key pair for server access

### Step 3: Deploy Backend
Wait for RDS instance to be available (5-10 minutes), then:
```bash
./backend-deploy.sh
```

### Step 4: Deploy Frontend
```bash
./frontend-deploy.sh
```

## Manual Deployment Steps

### 1. Create S3 Bucket for Frontend

```bash
# Create bucket (replace with unique name)
aws s3 mb s3://skilllink-frontend-$(date +%s)

# Enable static website hosting
aws s3 website s3://your-bucket-name --index-document index.html --error-document index.html

# Set bucket policy for public access
aws s3api put-bucket-policy --bucket your-bucket-name --policy file://bucket-policy.json
```

### 2. Create RDS PostgreSQL Instance

```bash
aws rds create-db-instance \
  --db-instance-identifier skilllink-db \
  --db-instance-class db.t3.micro \
  --engine postgres \
  --engine-version 13.13 \
  --master-username skilllink_user \
  --master-user-password your-secure-password \
  --allocated-storage 20 \
  --db-name skilllink \
  --publicly-accessible
```

### 3. Create EC2 Instance

```bash
# Create security group
aws ec2 create-security-group \
  --group-name skilllink-sg \
  --description "SkillLink security group"

# Add rules
aws ec2 authorize-security-group-ingress \
  --group-name skilllink-sg \
  --protocol tcp \
  --port 22 \
  --cidr 0.0.0.0/0

aws ec2 authorize-security-group-ingress \
  --group-name skilllink-sg \
  --protocol tcp \
  --port 3001 \
  --cidr 0.0.0.0/0

# Launch instance
aws ec2 run-instances \
  --image-id ami-0abcdef1234567890 \
  --count 1 \
  --instance-type t2.micro \
  --key-name your-key-pair \
  --security-groups skilllink-sg
```

### 4. Deploy Backend to EC2

```bash
# Connect to instance
ssh -i your-key.pem ec2-user@your-instance-ip

# Install Node.js
curl -sL https://rpm.nodesource.com/setup_18.x | sudo bash -
sudo yum install -y nodejs

# Clone and setup application
git clone <repository-url>
cd skilllink/backend
npm install --production

# Create environment file
cat > .env << EOF
NODE_ENV=production
PORT=3001
JWT_SECRET=$(openssl rand -base64 32)
DB_HOST=your-rds-endpoint
DB_USER=skilllink_user
DB_PASS=your-password
DB_NAME=skilllink
DB_DIALECT=postgres
