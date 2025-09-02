#!/bin/bash
set -e

# SkillLink AWS Deployment Script - WSL Compatible
PROJECT_NAME="skilllink"
AWS_REGION="us-east-1"
OWNER="Wondwossen"

# Environment validation
ENVIRONMENT="${2:-dev}"
if [[ "$ENVIRONMENT" != "dev" && "$ENVIRONMENT" != "prod" ]]; then
  echo "❌ Invalid environment: $ENVIRONMENT"
  echo "Usage: $0 {deploy|cleanup|status} {dev|prod}"
  exit 1
fi

# Validate AWS CLI and credentials
if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI is not installed"
    exit 1
fi

if ! aws sts get-caller-identity &> /dev/null; then
    echo "❌ AWS credentials not configured"
    exit 1
fi

# Instance types
if [[ "$ENVIRONMENT" == "dev" ]]; then
  EC2_TYPE="t2.micro"
  RDS_CLASS="db.t3.micro"
else
  EC2_TYPE="t3.small"
  RDS_CLASS="db.t3.small"
fi

# Resource names
S3_BUCKET="${PROJECT_NAME}-frontend-${ENVIRONMENT}-$(date +%s)"
EC2_NAME_TAG="${PROJECT_NAME}-ec2-${ENVIRONMENT}"
RDS_NAME_TAG="${PROJECT_NAME}-rds-${ENVIRONMENT}"

deploy() {
  echo "🚀 Starting deployment for $ENVIRONMENT environment..."

  # Frontend build check
  if [[ ! -d frontend/build ]]; then
    echo "⚠️ Building frontend..."
    (cd frontend && npm ci && npm run build)
  fi

  # S3 Bucket setup
  echo "📦 Setting up S3 bucket..."
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

  # Upload frontend
  aws s3 sync frontend/build "s3://$S3_BUCKET" --delete

  # EC2 setup
  echo "💻 Setting up EC2 instance..."
  AMI_ID=$(aws ec2 describe-images --owners amazon \
    --filters "Name=name,Values=amzn2-ami-hvm-*-x86_64-gp2" "Name=state,Values=available" \
    --query "Images | sort_by(@, &CreationDate) | [-1].ImageId" --output text --region $AWS_REGION)

  KEY_NAME="${PROJECT_NAME}-keypair-${ENVIRONMENT}"
  if ! aws ec2 describe-key-pairs --key-names $KEY_NAME &> /dev/null; then
      aws ec2 create-key-pair --key-name $KEY_NAME --query 'KeyMaterial' --output text > $KEY_NAME.pem
      chmod 400 $KEY_NAME.pem
  fi

  # Security group
  VPC_ID=$(aws ec2 describe-vpcs --filters "Name=isDefault,Values=true" --query "Vpcs[0].VpcId" --output text --region $AWS_REGION)
  SECURITY_GROUP_NAME="${PROJECT_NAME}-sg-${ENVIRONMENT}"
  SECURITY_GROUP_ID=$(aws ec2 describe-security-groups --filters "Name=group-name,Values=$SECURITY_GROUP_NAME" "Name=vpc-id,Values=$VPC_ID" --query 'SecurityGroups[0].GroupId' --output text --region $AWS_REGION)
  
  if [[ "$SECURITY_GROUP_ID" == "None" || -z "$SECURITY_GROUP_ID" ]]; then
    SECURITY_GROUP_ID=$(aws ec2 create-security-group \
      --group-name $SECURITY_GROUP_NAME \
      --description "Security group for $PROJECT_NAME $ENVIRONMENT" \
      --vpc-id $VPC_ID \
      --query 'GroupId' --output text)
    aws ec2 authorize-security-group-ingress --group-id $SECURITY_GROUP_ID --protocol tcp --port 22 --cidr 0.0.0.0/0
    aws ec2 authorize-security-group-ingress --group-id $SECURITY_GROUP_ID --protocol tcp --port 3001 --cidr 0.0.0.0/0
  fi

  # EC2 instance
  INSTANCE_ID=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=$EC2_NAME_TAG" "Name=instance-state-name,Values=running" --query 'Reservations[0].Instances[0].InstanceId' --output text --region $AWS_REGION)
  
  if [[ "$INSTANCE_ID" == "None" || -z "$INSTANCE_ID" ]]; then
    INSTANCE_ID=$(aws ec2 run-instances \
      --image-id $AMI_ID \
      --count 1 \
      --instance-type $EC2_TYPE \
      --key-name $KEY_NAME \
      --security-group-ids $SECURITY_GROUP_ID \
      --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$EC2_NAME_TAG},{Key=Project,Value=$PROJECT_NAME},{Key=Owner,Value=$OWNER},{Key=Environment,Value=$ENVIRONMENT}]" \
      --query 'Instances[0].InstanceId' --output text --region $AWS_REGION)
    
    echo "⏳ Waiting for EC2 instance to be running..."
    aws ec2 wait instance-running --instance-ids $INSTANCE_ID --region $AWS_REGION
  fi

  # Get EC2 public IP
  EC2_PUBLIC_IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].PublicIpAddress' --output text --region $AWS_REGION)
  echo "✅ EC2 instance running at: $EC2_PUBLIC_IP"

  # RDS setup
  echo "🗄️ Setting up RDS database..."
  DB_INSTANCE_ID="${PROJECT_NAME}-rds-${ENVIRONMENT}"
  DB_PASSWORD=$(openssl rand -base64 32)
  
  if ! aws rds describe-db-instances --db-instance-identifier $DB_INSTANCE_ID &> /dev/null; then
    aws rds create-db-instance \
      --db-instance-identifier $DB_INSTANCE_ID \
      --db-instance-class $RDS_CLASS \
      --engine postgres \
      --master-username skilllink_user \
      --master-user-password "$DB_PASSWORD" \
      --allocated-storage 20 \
      --storage-type gp2 \
      --tags Key=Project,Value=$PROJECT_NAME Key=Owner,Value=$OWNER Key=Environment,Value=$ENVIRONMENT \
      --region $AWS_REGION
    
    echo "⏳ Waiting for RDS instance to be available..."
    aws rds wait db-instance-available --db-instance-identifier $DB_INSTANCE_ID --region $AWS_REGION
  fi

  # Get RDS endpoint
  DB_ENDPOINT=$(aws rds describe-db-instances --db-instance-identifier $DB_INSTANCE_ID --query 'DBInstances[0].Endpoint.Address' --output text --region $AWS_REGION)
  echo "✅ RDS instance available at: $DB_ENDPOINT"

  # Generate deployment environment file
  echo "📝 Generating deployment configuration..."
  cat > infrastructure/.env.deployment <<EOF
PROJECT_NAME=$PROJECT_NAME
ENVIRONMENT=$ENVIRONMENT
OWNER=$OWNER
AWS_REGION=$AWS_REGION

# Frontend
S3_BUCKET=$S3_BUCKET
S3_WEBSITE_URL=http://$S3_BUCKET.s3-website-$AWS_REGION.amazonaws.com

# Backend
EC2_INSTANCE_ID=$INSTANCE_ID
EC2_PUBLIC_IP=$EC2_PUBLIC_IP
EC2_KEY_NAME=$KEY_NAME

# RDS
DB_INSTANCE_ID=$DB_INSTANCE_ID
DB_ENDPOINT=$DB_ENDPOINT
DB_NAME=skilllink
DB_USERNAME=skilllink_user
DB_PASSWORD=$DB_PASSWORD
DATABASE_URL=postgresql://skilllink_user:$DB_PASSWORD@$DB_ENDPOINT:5432/skilllink
EOF

  echo "✅ Deployment completed successfully!"
  echo ""
  echo "📋 Deployment Summary:"
  echo "Frontend URL: http://$S3_BUCKET.s3-website-$AWS_REGION.amazonaws.com"
  echo "Backend URL: http://$EC2_PUBLIC_IP:3001"
  echo "Database: $DB_ENDPOINT"
  echo ""
  echo "🔧 Next steps:"
  echo "1. SSH to EC2: ssh -i $KEY_NAME.pem ec2-user@$EC2_PUBLIC_IP"
  echo "2. Deploy backend code to EC2"
  echo "3. Configure environment variables"
  echo "4. Start the application"
}

cleanup() {
  echo "🧹 Cleaning up $ENVIRONMENT environment..."
  
  # Load deployment config
  if [[ -f infrastructure/.env.deployment ]]; then
    source infrastructure/.env.deployment
  fi
  
  # Terminate EC2 instance
  if [[ -n "$EC2_INSTANCE_ID" ]]; then
    echo "Terminating EC2 instance: $EC2_INSTANCE_ID"
    aws ec2 terminate-instances --instance-ids $EC2_INSTANCE_ID --region $AWS_REGION
  fi
  
  # Delete RDS instance
  if [[ -n "$DB_INSTANCE_ID" ]]; then
    echo "Deleting RDS instance: $DB_INSTANCE_ID"
    aws rds delete-db-instance --db-instance-identifier $DB_INSTANCE_ID --skip-final-snapshot --region $AWS_REGION
  fi
  
  # Delete S3 bucket
  if [[ -n "$S3_BUCKET" ]]; then
    echo "Deleting S3 bucket: $S3_BUCKET"
    aws s3 rb "s3://$S3_BUCKET" --force --region $AWS_REGION
  fi
  
  echo "✅ Cleanup completed"
}

status() {
  echo "📊 Checking deployment status..."
  
  if [[ -f infrastructure/.env.deployment ]]; then
    source infrastructure/.env.deployment
    echo "Frontend: $S3_WEBSITE_URL"
    echo "Backend: http://$EC2_PUBLIC_IP:3001"
    echo "Database: $DB_ENDPOINT"
  else
    echo "No deployment configuration found"
  fi
}

# Main script logic
case "${1:-}" in
  deploy)
    deploy
    ;;
  cleanup)
    cleanup
    ;;
  status)
    status
    ;;
  *)
    echo "Usage: $0 {deploy|cleanup|status} {dev|prod}"
    exit 1
    ;;
esac
