#!/bin/bash

# SkillLink AWS Deployment Script (Free Tier)
# This script helps deploy the SkillLink application to AWS Free Tier

set -e

echo "🚀 SkillLink AWS Free Tier Deployment"
echo "====================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo -e "${RED}❌ AWS CLI is not installed. Please install it first.${NC}"
    exit 1
fi

# Check if AWS credentials are configured
if ! aws sts get-caller-identity &> /dev/null; then
    echo -e "${RED}❌ AWS credentials not configured. Run 'aws configure' first.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ AWS CLI configured${NC}"

# Configuration variables
APP_NAME="skilllink"
REGION="us-east-1"  # Free tier is best in us-east-1
EC2_INSTANCE_TYPE="t2.micro"
RDS_INSTANCE_CLASS="db.t3.micro"

echo "📋 Deployment Configuration:"
echo "  Application: $APP_NAME"
echo "  Region: $REGION"
echo "  EC2 Instance: $EC2_INSTANCE_TYPE"
echo "  RDS Instance: $RDS_INSTANCE_CLASS"
echo ""

# Create S3 bucket for frontend
create_s3_bucket() {
    echo "🪣 Creating S3 bucket for frontend..."
    
    BUCKET_NAME="$APP_NAME-frontend-$(date +%s)"
    
    if aws s3 mb s3://$BUCKET_NAME --region $REGION; then
        echo -e "${GREEN}✅ S3 bucket created: $BUCKET_NAME${NC}"
        echo "BUCKET_NAME=$BUCKET_NAME" >> .env.deployment
    else
        echo -e "${RED}❌ Failed to create S3 bucket${NC}"
        exit 1
    fi
    
    # Enable static website hosting
    aws s3 website s3://$BUCKET_NAME --index-document index.html --error-document index.html
    
    # Set bucket policy for public read access
    cat > bucket-policy.json << EOL
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "PublicReadGetObject",
            "Effect": "Allow",
            "Principal": "*",
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::$BUCKET_NAME/*"
        }
    ]
}
EOL
    
    aws s3api put-bucket-policy --bucket $BUCKET_NAME --policy file://bucket-policy.json
    rm bucket-policy.json
}

# Create RDS PostgreSQL instance
create_rds_instance() {
    echo "🗄️ Creating RDS PostgreSQL instance..."
    
    DB_INSTANCE_ID="$APP_NAME-db"
    DB_NAME="skilllink"
    DB_USERNAME="skilllink_user"
    DB_PASSWORD=$(openssl rand -base64 12)
    
    echo "DB_PASSWORD=$DB_PASSWORD" >> .env.deployment
    
    aws rds create-db-instance \
        --db-instance-identifier $DB_INSTANCE_ID \
        --db-instance-class $RDS_INSTANCE_CLASS \
        --engine postgres \
        --engine-version 13.13 \
        --master-username $DB_USERNAME \
        --master-user-password $DB_PASSWORD \
        --allocated-storage 20 \
        --db-name $DB_NAME \
        --vpc-security-group-ids $(aws ec2 describe-security-groups --group-names default --query 'SecurityGroups[0].GroupId' --output text) \
        --publicly-accessible \
        --storage-encrypted \
        --backup-retention-period 7 \
        --region $REGION
        
    echo -e "${GREEN}✅ RDS instance creation initiated: $DB_INSTANCE_ID${NC}"
    echo "DB_INSTANCE_ID=$DB_INSTANCE_ID" >> .env.deployment
    echo "DB_USERNAME=$DB_USERNAME" >> .env.deployment
    echo "DB_NAME=$DB_NAME" >> .env.deployment
    
    echo -e "${YELLOW}⏳ RDS instance is being created. This may take 5-10 minutes.${NC}"
}

# Create EC2 instance
create_ec2_instance() {
    echo "💻 Creating EC2 instance..."
    
    # Get the latest Amazon Linux 2 AMI ID
    AMI_ID=$(aws ec2 describe-images \
        --owners amazon \
        --filters "Name=name,Values=amzn2-ami-hvm-*-x86_64-gp2" "Name=state,Values=available" \
        --query "Images | sort_by(@, &CreationDate) | [-1].ImageId" \
        --output text \
        --region $REGION)
    
    echo "Using AMI: $AMI_ID"
    
    # Create key pair if it doesn't exist
    KEY_NAME="$APP_NAME-keypair"
    if ! aws ec2 describe-key-pairs --key-names $KEY_NAME &> /dev/null; then
        aws ec2 create-key-pair --key-name $KEY_NAME --query 'KeyMaterial' --output text > $KEY_NAME.pem
        chmod 400 $KEY_NAME.pem
        echo -e "${GREEN}✅ Created key pair: $KEY_NAME.pem${NC}"
    fi
    
    # Create security group
    SECURITY_GROUP_NAME="$APP_NAME-sg"
    SECURITY_GROUP_ID=$(aws ec2 create-security-group \
        --group-name $SECURITY_GROUP_NAME \
        --description "Security group for SkillLink application" \
        --query 'GroupId' \
        --output text \
        --region $REGION)
    
    # Add rules to security group
    aws ec2 authorize-security-group-ingress \
        --group-id $SECURITY_GROUP_ID \
        --protocol tcp \
        --port 22 \
        --cidr 0.0.0.0/0 \
        --region $REGION
        
    aws ec2 authorize-security-group-ingress \
        --group-id $SECURITY_GROUP_ID \
        --protocol tcp \
        --port 3001 \
        --cidr 0.0.0.0/0 \
        --region $REGION
    
    # Launch EC2 instance
    INSTANCE_ID=$(aws ec2 run-instances \
        --image-id $AMI_ID \
        --count 1 \
        --instance-type $EC2_INSTANCE_TYPE \
        --key-name $KEY_NAME \
        --security-group-ids $SECURITY_GROUP_ID \
        --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$APP_NAME-server}]" \
        --query 'Instances[0].InstanceId' \
        --output text \
        --region $REGION)
    
    echo -e "${GREEN}✅ EC2 instance created: $INSTANCE_ID${NC}"
    echo "INSTANCE_ID=$INSTANCE_ID" >> .env.deployment
    echo "KEY_NAME=$KEY_NAME" >> .env.deployment
    echo "SECURITY_GROUP_ID=$SECURITY_GROUP_ID" >> .env.deployment
    
    # Wait for instance to be running
    echo -e "${YELLOW}⏳ Waiting for instance to be running...${NC}"
    aws ec2 wait instance-running --instance-ids $INSTANCE_ID --region $REGION
    
    # Get public IP
    PUBLIC_IP=$(aws ec2 describe-instances \
        --instance-ids $INSTANCE_ID \
        --query 'Reservations[0].Instances[0].PublicIpAddress' \
        --output text \
        --region $REGION)
    
    echo -e "${GREEN}✅ Instance is running at: $PUBLIC_IP${NC}"
    echo "PUBLIC_IP=$PUBLIC_IP" >> .env.deployment
}

# Main deployment function
deploy() {
    echo "Starting deployment..."
    
    # Initialize deployment environment file
    echo "# SkillLink Deployment Environment" > .env.deployment
    echo "DEPLOYMENT_DATE=$(date)" >> .env.deployment
    
    create_s3_bucket
    create_rds_instance
    create_ec2_instance
    
    echo ""
    echo -e "${GREEN}🎉 Deployment infrastructure created successfully!${NC}"
    echo ""
    echo "📝 Next steps:"
    echo "1. Wait for RDS instance to be available (check AWS console)"
    echo "2. Build and deploy frontend to S3 bucket"
    echo "3. Deploy backend to EC2 instance"
    echo "4. Configure environment variables"
    echo ""
    echo "Check .env.deployment file for all resource details."
    echo ""
    echo -e "${YELLOW}💰 Remember: This uses AWS Free Tier resources, but monitor your usage to avoid charges.${NC}"
}

# Check command line arguments
case "${1:-deploy}" in
    "deploy")
        deploy
        ;;
    "cleanup")
        echo "🧹 Cleanup functionality would go here"
        echo "This would terminate all created resources"
        ;;
    *)
        echo "Usage: $0 [deploy|cleanup]"
        exit 1
        ;;
esac
