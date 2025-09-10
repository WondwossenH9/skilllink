#!/bin/bash
set -e

# SkillLink Simple AWS Deployment - Free Tier Only
# Total cost: ~$0-5/month (within free tier limits)

PROJECT_NAME="skilllink"
AWS_REGION="us-east-1"
ENVIRONMENT="${1:-dev}"

echo "🚀 SkillLink Simple AWS Deployment (Free Tier)"
echo "=============================================="

# Validate prerequisites
echo "🔍 Checking prerequisites..."
if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI not found. Install with: curl 'https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip' -o 'awscliv2.zip' && unzip awscliv2.zip && sudo ./aws/install"
    exit 1
fi

if ! aws sts get-caller-identity &> /dev/null; then
    echo "❌ AWS credentials not configured. Run: aws configure"
    exit 1
fi

if ! command -v node &> /dev/null; then
    echo "❌ Node.js not found. Install from: https://nodejs.org/"
    exit 1
fi

echo "✅ Prerequisites check passed"

# Build applications
echo "📦 Building applications..."
cd frontend
npm ci
npm run build
cd ../backend
npm ci
cd ..

# Generate unique identifiers
TIMESTAMP=$(date +%s)
S3_BUCKET="${PROJECT_NAME}-frontend-${TIMESTAMP}"
KEY_NAME="${PROJECT_NAME}-key-${TIMESTAMP}"

# 1. Create S3 bucket for frontend (Free: 5GB storage, 15GB transfer)
echo "📦 Creating S3 bucket for frontend..."
aws s3 mb "s3://$S3_BUCKET" --region "$AWS_REGION"

# Configure for static website hosting
aws s3api put-bucket-website --bucket "$S3_BUCKET" --website-configuration '{
  "IndexDocument": {"Suffix": "index.html"},
  "ErrorDocument": {"Key": "index.html"}
}'

# Set bucket policy for public read
aws s3api put-bucket-policy --bucket "$S3_BUCKET" --policy "{
  \"Version\": \"2012-10-17\",
  \"Statement\": [{
    \"Sid\": \"PublicReadGetObject\",
    \"Effect\": \"Allow\",
    \"Principal\": \"*\",
    \"Action\": \"s3:GetObject\",
    \"Resource\": \"arn:aws:s3:::$S3_BUCKET/*\"
  }]
}"

# Upload frontend build
aws s3 sync frontend/build "s3://$S3_BUCKET" --delete

# Get S3 website URL
S3_WEBSITE_URL="http://$S3_BUCKET.s3-website-$AWS_REGION.amazonaws.com"
echo "✅ Frontend deployed to: $S3_WEBSITE_URL"

# 2. Create EC2 key pair
echo "🔑 Creating EC2 key pair..."
aws ec2 create-key-pair --key-name "$KEY_NAME" --query 'KeyMaterial' --output text > "$KEY_NAME.pem"
chmod 400 "$KEY_NAME.pem"
echo "✅ Key pair saved as: $KEY_NAME.pem"

# 3. Create security group (using default VPC - free)
echo "🛡️ Creating security group..."
VPC_ID=$(aws ec2 describe-vpcs --filters "Name=isDefault,Values=true" --query "Vpcs[0].VpcId" --output text)
SG_NAME="${PROJECT_NAME}-sg-${TIMESTAMP}"

SECURITY_GROUP_ID=$(aws ec2 create-security-group \
  --group-name "$SG_NAME" \
  --description "SkillLink simple deployment security group" \
  --vpc-id "$VPC_ID" \
  --query 'GroupId' --output text)

# Allow SSH (restrict to your IP for security)
MY_IP=$(curl -s https://checkip.amazonaws.com)
aws ec2 authorize-security-group-ingress \
  --group-id "$SECURITY_GROUP_ID" \
  --protocol tcp --port 22 --cidr "$MY_IP/32"

# Allow HTTP (for the application)
aws ec2 authorize-security-group-ingress \
  --group-id "$SECURITY_GROUP_ID" \
  --protocol tcp --port 80 --cidr 0.0.0.0/0

echo "✅ Security group created: $SECURITY_GROUP_ID"

# 4. Launch EC2 instance (t2.micro - free tier: 750 hours/month)
echo "💻 Launching EC2 instance..."
AMI_ID=$(aws ec2 describe-images --owners amazon \
  --filters "Name=name,Values=amzn2-ami-hvm-*-x86_64-gp2" "Name=state,Values=available" \
  --query "Images | sort_by(@, &CreationDate) | [-1].ImageId" --output text)

INSTANCE_ID=$(aws ec2 run-instances \
  --image-id "$AMI_ID" \
  --count 1 \
  --instance-type t2.micro \
  --key-name "$KEY_NAME" \
  --security-group-ids "$SECURITY_GROUP_ID" \
  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$PROJECT_NAME-server}]" \
  --user-data "$(cat <<EOF
#!/bin/bash
yum update -y
yum install -y git

# Install Node.js 18
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
export NVM_DIR="/root/.nvm"
[ -s "\$NVM_DIR/nvm.sh" ] && \. "\$NVM_DIR/nvm.sh"
nvm install 18
nvm use 18

# Install PM2
npm install -g pm2

# Install nginx
amazon-linux-extras install nginx1.12 -y
systemctl start nginx
systemctl enable nginx

# Clone and setup application (we'll do this via SSH later)
echo "EC2 setup complete" > /tmp/setup-complete
EOF
)" \
  --query 'Instances[0].InstanceId' --output text)

echo "⏳ Waiting for EC2 instance to be running..."
aws ec2 wait instance-running --instance-ids "$INSTANCE_ID"

# Get public IP
EC2_PUBLIC_IP=$(aws ec2 describe-instances --instance-ids "$INSTANCE_ID" \
  --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)

echo "✅ EC2 instance running at: $EC2_PUBLIC_IP"

# 5. Create RDS instance (db.t3.micro - free tier: 750 hours/month)
echo "🗄️ Creating RDS PostgreSQL instance..."
DB_PASSWORD=$(openssl rand -base64 12 | tr -d "=+/" | cut -c1-12)
DB_IDENTIFIER="${PROJECT_NAME}-db-${TIMESTAMP}"

aws rds create-db-instance \
  --db-instance-identifier "$DB_IDENTIFIER" \
  --db-instance-class db.t3.micro \
  --engine postgres \
  --engine-version 15.7 \
  --master-username skilllink \
  --master-user-password "$DB_PASSWORD" \
  --allocated-storage 20 \
  --storage-type gp2 \
  --vpc-security-group-ids "$SECURITY_GROUP_ID" \
  --backup-retention-period 0 \
  --no-multi-az \
  --publicly-accessible

# Allow RDS access from EC2
aws ec2 authorize-security-group-ingress \
  --group-id "$SECURITY_GROUP_ID" \
  --protocol tcp --port 5432 --source-group "$SECURITY_GROUP_ID"

echo "⏳ Waiting for RDS instance to be available (this takes 5-10 minutes)..."
aws rds wait db-instance-available --db-instance-identifier "$DB_IDENTIFIER"

DB_ENDPOINT=$(aws rds describe-db-instances --db-instance-identifier "$DB_IDENTIFIER" \
  --query 'DBInstances[0].Endpoint.Address' --output text)

echo "✅ RDS instance available at: $DB_ENDPOINT"

# 6. Deploy application to EC2
echo "🚀 Deploying application to EC2..."

# Wait a bit more for EC2 to fully initialize
echo "⏳ Waiting for EC2 to complete initialization..."
sleep 60

# Create deployment package
rm -rf deploy-temp
mkdir deploy-temp
cp -r backend/* deploy-temp/
rm -rf deploy-temp/node_modules

# Create production environment file
cat > deploy-temp/.env <<EOF
NODE_ENV=production
PORT=3001
DATABASE_URL=postgresql://skilllink:${DB_PASSWORD}@${DB_ENDPOINT}:5432/postgres
JWT_SECRET=$(openssl rand -hex 32)
FRONTEND_URL=${S3_WEBSITE_URL}
EOF

# Create nginx configuration
cat > deploy-temp/nginx.conf <<EOF
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://localhost:3001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOF

# Upload to EC2 and deploy
echo "📤 Uploading application to EC2..."
scp -i "$KEY_NAME.pem" -o StrictHostKeyChecking=no -r deploy-temp/* ec2-user@$EC2_PUBLIC_IP:/tmp/

# Install and start application
ssh -i "$KEY_NAME.pem" -o StrictHostKeyChecking=no ec2-user@$EC2_PUBLIC_IP << 'ENDSSH'
# Wait for user data script to complete
while [ ! -f /tmp/setup-complete ]; do sleep 5; done

# Setup NVM for this session
export NVM_DIR="/home/ec2-user/.nvm"
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
nvm install 18
nvm use 18

# Install PM2
npm install -g pm2

# Move application files
sudo cp -r /tmp/* /home/ec2-user/app/ 2>/dev/null || sudo mkdir -p /home/ec2-user/app && sudo cp -r /tmp/.env /tmp/*.js /tmp/src /tmp/package*.json /home/ec2-user/app/
cd /home/ec2-user/app

# Install dependencies
npm ci --only=production

# Configure nginx
sudo cp nginx.conf /etc/nginx/conf.d/skilllink.conf
sudo rm -f /etc/nginx/nginx.conf.default
sudo systemctl restart nginx

# Start application with PM2
pm2 start src/server.js --name skilllink-backend
pm2 startup
pm2 save

echo "✅ Application deployed and running"
ENDSSH

# Clean up temporary files
rm -rf deploy-temp

# Update frontend with correct API URL
echo "🔄 Updating frontend with correct API URL..."
cd frontend
REACT_APP_API_URL="http://$EC2_PUBLIC_IP/api" npm run build
cd ..
aws s3 sync frontend/build "s3://$S3_BUCKET" --delete

echo ""
echo "🎉 Deployment Complete!"
echo "======================"
echo "Frontend URL: $S3_WEBSITE_URL"
echo "Backend URL:  http://$EC2_PUBLIC_IP"
echo "Database:     $DB_ENDPOINT"
echo ""
echo "💾 Save these details:"
echo "Key file:     $KEY_NAME.pem"
echo "Instance ID:  $INSTANCE_ID"
echo "DB Password:  $DB_PASSWORD"
echo ""
echo "💰 Monthly costs (within free tier):"
echo "- EC2 t2.micro: $0 (750 hours free)"
echo "- RDS db.t3.micro: $0 (750 hours free)"
echo "- S3 storage: $0 (5GB free)"
echo "- Data transfer: $0 (15GB free)"
echo ""
echo "🧹 To cleanup when done:"
echo "aws ec2 terminate-instances --instance-ids $INSTANCE_ID"
echo "aws rds delete-db-instance --db-instance-identifier $DB_IDENTIFIER --skip-final-snapshot"
echo "aws s3 rb s3://$S3_BUCKET --force"
echo "aws ec2 delete-security-group --group-id $SECURITY_GROUP_ID"
echo "aws ec2 delete-key-pair --key-name $KEY_NAME"