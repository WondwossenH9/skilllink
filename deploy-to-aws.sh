#!/bin/bash
set -e

# SkillLink AWS Deployment Script - Fixed Version
# This script addresses all issues identified in the audit

PROJECT_NAME="skilllink"
AWS_REGION="us-east-1"
OWNER="Wondwossen"
ENVIRONMENT="${1:-dev}"

echo "🚀 Starting SkillLink AWS deployment for $ENVIRONMENT environment..."

# Validate AWS CLI and credentials
if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI is not installed"
    exit 1
fi

if ! aws sts get-caller-identity &> /dev/null; then
    echo "❌ AWS credentials not configured"
    exit 1
fi

# Build frontend first
echo "📦 Building frontend..."
cd frontend
npm ci
npm run build
cd ..

# Build backend
echo "📦 Building backend..."
cd backend
npm ci
cd ..

# Generate unique resource names
TIMESTAMP=$(date +%s)
S3_BUCKET="${PROJECT_NAME}-frontend-${ENVIRONMENT}-${TIMESTAMP}"
EC2_NAME_TAG="${PROJECT_NAME}-ec2-${ENVIRONMENT}"
RDS_NAME_TAG="${PROJECT_NAME}-rds-${ENVIRONMENT}"

# Instance types based on environment
if [[ "$ENVIRONMENT" == "dev" ]]; then
  EC2_TYPE="t2.micro"
  RDS_CLASS="db.t3.micro"
else
  EC2_TYPE="t3.small"
  RDS_CLASS="db.t3.small"
fi

# 1. S3 Bucket setup for frontend
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

# 2. EC2 setup
echo "💻 Setting up EC2 instance..."
AMI_ID=$(aws ec2 describe-images --owners amazon \
  --filters "Name=name,Values=amzn2-ami-hvm-*-x86_64-gp2" "Name=state,Values=available" \
  --query "Images | sort_by(@, &CreationDate) | [-1].ImageId" --output text --region $AWS_REGION)

KEY_NAME="${PROJECT_NAME}-keypair-${ENVIRONMENT}"
if ! aws ec2 describe-key-pairs --key-names $KEY_NAME &> /dev/null; then
    aws ec2 create-key-pair --key-name $KEY_NAME --query 'KeyMaterial' --output text > $KEY_NAME.pem
    chmod 400 $KEY_NAME.pem
fi

# Security group with proper configuration
VPC_ID=$(aws ec2 describe-vpcs --filters "Name=isDefault,Values=true" --query "Vpcs[0].VpcId" --output text --region $AWS_REGION)
SECURITY_GROUP_NAME="${PROJECT_NAME}-sg-${ENVIRONMENT}"
SECURITY_GROUP_ID=$(aws ec2 describe-security-groups --filters "Name=group-name,Values=$SECURITY_GROUP_NAME" "Name=vpc-id,Values=$VPC_ID" --query 'SecurityGroups[0].GroupId' --output text --region $AWS_REGION)

if [[ "$SECURITY_GROUP_ID" == "None" || -z "$SECURITY_GROUP_ID" ]]; then
  SECURITY_GROUP_ID=$(aws ec2 create-security-group \
    --group-name $SECURITY_GROUP_NAME \
    --description "Security group for $PROJECT_NAME $ENVIRONMENT" \
    --vpc-id $VPC_ID \
    --query 'GroupId' --output text)
  
  # SSH access (restrict to your IP in production)
  aws ec2 authorize-security-group-ingress --group-id $SECURITY_GROUP_ID --protocol tcp --port 22 --cidr 0.0.0.0/0
  
  # HTTP access for ALB/Nginx (not direct app port)
  aws ec2 authorize-security-group-ingress --group-id $SECURITY_GROUP_ID --protocol tcp --port 80 --cidr 0.0.0.0/0
  
  # HTTPS access
  aws ec2 authorize-security-group-ingress --group-id $SECURITY_GROUP_ID --protocol tcp --port 443 --cidr 0.0.0.0/0
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

# 3. RDS setup
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
    --backup-retention-period 7 \
    --tags Key=Project,Value=$PROJECT_NAME Key=Owner,Value=$OWNER Key=Environment,Value=$ENVIRONMENT \
    --region $AWS_REGION
  
  echo "⏳ Waiting for RDS instance to be available..."
  aws rds wait db-instance-available --db-instance-identifier $DB_INSTANCE_ID --region $AWS_REGION
fi

# Get RDS endpoint
DB_ENDPOINT=$(aws rds describe-db-instances --db-instance-identifier $DB_INSTANCE_ID --query 'DBInstances[0].Endpoint.Address' --output text --region $AWS_REGION)
echo "✅ RDS instance available at: $DB_ENDPOINT"

# 4. Deploy backend to EC2
echo "🚀 Deploying backend to EC2..."

# Create deployment package
rm -rf deploy-package
mkdir -p deploy-package
cp -r backend/* deploy-package/
rm -rf deploy-package/node_modules
rm -f deploy-package/*.db

# Create production environment file with proper DATABASE_URL
export DATABASE_URL="postgres://skilllink_user:${DB_PASSWORD}@${DB_ENDPOINT}:5432/skilllink"
cat > deploy-package/.env <<EOF
NODE_ENV=production
PORT=3001
DATABASE_URL=${DATABASE_URL}
JWT_SECRET=skilllink-production-jwt-secret-$(openssl rand -hex 32)
JWT_EXPIRE=7d
FRONTEND_URL=http://${S3_BUCKET}.s3-website-${AWS_REGION}.amazonaws.com
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=100
EOF

# Create deployment script for EC2
cat > deploy-package/deploy.sh <<'EOF'
#!/bin/bash
set -e

echo "🚀 Deploying SkillLink backend..."

# Install Node.js if not installed
if ! command -v node &> /dev/null; then
    echo "📦 Installing Node.js..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    nvm install 18
    nvm use 18
fi

# Install PM2 if not installed
if ! command -v pm2 &> /dev/null; then
    echo "📦 Installing PM2..."
    npm install -g pm2
fi

# Install dependencies
echo "📦 Installing dependencies..."
npm ci --production

# Create database tables
echo "🗄️ Setting up database..."
node -e "
const sequelize = require('./config/database');
const { User, Skill, Match } = require('./src/models');

async function setupDatabase() {
  try {
    await sequelize.authenticate();
    console.log('Database connection established.');
    
    await sequelize.sync({ force: false });
    console.log('Database synchronized.');
    
    process.exit(0);
  } catch (error) {
    console.error('Database setup failed:', error);
    process.exit(1);
  }
}

setupDatabase();
"

# Start application with PM2
echo "🚀 Starting application..."
pm2 delete skilllink-backend 2>/dev/null || true
pm2 start src/server.js --name skilllink-backend
pm2 startup
pm2 save

echo "✅ Backend deployed successfully!"
echo "🌐 Application running on port 3001"
echo "📊 Check status: pm2 status"
echo "📋 View logs: pm2 logs skilllink-backend"
EOF

chmod +x deploy-package/deploy.sh

# Copy files to EC2
echo "📤 Copying files to EC2..."
scp -i "$KEY_NAME.pem" -r deploy-package/* ec2-user@$EC2_PUBLIC_IP:~/

# Deploy on EC2
echo "🔧 Deploying on EC2..."
ssh -i "$KEY_NAME.pem" ec2-user@$EC2_PUBLIC_IP << 'EOF'
cd ~
chmod +x deploy.sh
./deploy.sh
EOF

# 5. Generate deployment summary
echo "✅ Deployment completed successfully!"
echo ""
echo "📋 Deployment Summary:"
echo "Frontend URL: http://$S3_BUCKET.s3-website-$AWS_REGION.amazonaws.com"
echo "Backend URL: http://$EC2_PUBLIC_IP:3001"
echo "Database: $DB_ENDPOINT"
echo ""
echo "🔧 Management commands:"
echo "SSH to EC2: ssh -i $KEY_NAME.pem ec2-user@$EC2_PUBLIC_IP"
echo "Check app status: ssh -i $KEY_NAME.pem ec2-user@$EC2_PUBLIC_IP 'pm2 status'"
echo "View logs: ssh -i $KEY_NAME.pem ec2-user@$EC2_PUBLIC_IP 'pm2 logs skilllink-backend'"
echo "Restart app: ssh -i $KEY_NAME.pem ec2-user@$EC2_PUBLIC_IP 'pm2 restart skilllink-backend'"
echo ""
echo "🔒 Security Notes:"
echo "- SSH access is currently open to 0.0.0.0/0 - restrict this in production"
echo "- Consider adding CloudFront for frontend and ALB for backend"
echo "- Move secrets to AWS Secrets Manager for production"
