# SkillLink Simple AWS Deployment - PowerShell Version
# Total cost: ~$0-5/month (within free tier limits)

param(
    [string]$Environment = "dev"
)

$PROJECT_NAME = "skilllink"
$AWS_REGION = "us-east-1"
$AWS_CLI = "C:\Program Files\Amazon\AWSCLIV2\aws.exe"

Write-Host "🚀 SkillLink Simple AWS Deployment (Free Tier)" -ForegroundColor Cyan
Write-Host "=============================================="

# Validate prerequisites
Write-Host "🔍 Checking prerequisites..." -ForegroundColor Yellow
if (!(Test-Path $AWS_CLI)) {
    Write-Host "❌ AWS CLI not found at: $AWS_CLI" -ForegroundColor Red
    Write-Host "   Install from: https://aws.amazon.com/cli/" -ForegroundColor Yellow
    exit 1
}

try {
    & $AWS_CLI sts get-caller-identity --output text | Out-Null
} catch {
    Write-Host "❌ AWS credentials not configured. Run: aws configure" -ForegroundColor Red
    exit 1
}

if (!(Get-Command node -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Node.js not found. Install from: https://nodejs.org/" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Prerequisites check passed" -ForegroundColor Green

# Build applications
Write-Host "📦 Building applications..." -ForegroundColor Yellow
Set-Location frontend
npm ci
npm run build
Set-Location ..\backend
npm ci
Set-Location ..

# Generate unique identifiers
$TIMESTAMP = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
$S3_BUCKET = "$PROJECT_NAME-frontend-$TIMESTAMP"
$KEY_NAME = "$PROJECT_NAME-key-$TIMESTAMP"

Write-Host "🔧 Using timestamp: $TIMESTAMP" -ForegroundColor Blue

# 1. Create S3 bucket for frontend
Write-Host "Creating S3 bucket for frontend..." -ForegroundColor Yellow
& $AWS_CLI s3 mb "s3://$S3_BUCKET" --region $AWS_REGION

# Configure for static website hosting
$websiteConfig = @'
{
  "IndexDocument": {"Suffix": "index.html"},
  "ErrorDocument": {"Key": "index.html"}
}
'@

aws s3api put-bucket-website --bucket $S3_BUCKET --website-configuration $websiteConfig

# Set bucket policy for public read
$bucketPolicy = @"
{
  "Version": "2012-10-17",
  "Statement": [{
    "Sid": "PublicReadGetObject",
    "Effect": "Allow",
    "Principal": "*",
    "Action": "s3:GetObject",
    "Resource": "arn:aws:s3:::$S3_BUCKET/*"
  }]
}
"@

aws s3api put-bucket-policy --bucket $S3_BUCKET --policy $bucketPolicy

# Upload frontend build
aws s3 sync frontend/build "s3://$S3_BUCKET" --delete

$S3_WEBSITE_URL = "http://$S3_BUCKET.s3-website-$AWS_REGION.amazonaws.com"
Write-Host "✅ Frontend deployed to: $S3_WEBSITE_URL" -ForegroundColor Green

# 2. Create EC2 key pair
Write-Host "🔑 Creating EC2 key pair..." -ForegroundColor Yellow
aws ec2 create-key-pair --key-name $KEY_NAME --query 'KeyMaterial' --output text > "$KEY_NAME.pem"
Write-Host "✅ Key pair saved as: $KEY_NAME.pem" -ForegroundColor Green

# 3. Create security group
Write-Host "🛡️ Creating security group..." -ForegroundColor Yellow
$VPC_ID = aws ec2 describe-vpcs --filters "Name=isDefault,Values=true" --query "Vpcs[0].VpcId" --output text
$SG_NAME = "$PROJECT_NAME-sg-$TIMESTAMP"

$SECURITY_GROUP_ID = aws ec2 create-security-group --group-name $SG_NAME --description "SkillLink simple deployment security group" --vpc-id $VPC_ID --query 'GroupId' --output text

# Get your public IP
$MY_IP = (Invoke-WebRequest -Uri "https://checkip.amazonaws.com" -UseBasicParsing).Content.Trim()

# Allow SSH from your IP
aws ec2 authorize-security-group-ingress --group-id $SECURITY_GROUP_ID --protocol tcp --port 22 --cidr "$MY_IP/32"

# Allow HTTP
aws ec2 authorize-security-group-ingress --group-id $SECURITY_GROUP_ID --protocol tcp --port 80 --cidr "0.0.0.0/0"

Write-Host "✅ Security group created: $SECURITY_GROUP_ID" -ForegroundColor Green

# 4. Launch EC2 instance
Write-Host "💻 Launching EC2 instance..." -ForegroundColor Yellow
$AMI_ID = & $AWS_CLI ec2 describe-images --owners amazon --filters "Name=name,Values=amzn2-ami-hvm-*-x86_64-gp2" "Name=state,Values=available" --query "Images | sort_by(@, ``&CreationDate``) | [-1].ImageId" --output text

$userData = @'
#!/bin/bash
yum update -y
yum install -y git

# Install Node.js 18
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
export NVM_DIR="/root/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
nvm install 18
nvm use 18

# Install PM2
npm install -g pm2

# Install nginx
amazon-linux-extras install nginx1.12 -y
systemctl start nginx
systemctl enable nginx

echo "EC2 setup complete" > /tmp/setup-complete
'@

$INSTANCE_ID = aws ec2 run-instances --image-id $AMI_ID --count 1 --instance-type t2.micro --key-name $KEY_NAME --security-group-ids $SECURITY_GROUP_ID --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$PROJECT_NAME-server}]" --user-data $userData --query 'Instances[0].InstanceId' --output text

Write-Host "⏳ Waiting for EC2 instance to be running..." -ForegroundColor Yellow
aws ec2 wait instance-running --instance-ids $INSTANCE_ID

$EC2_PUBLIC_IP = aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].PublicIpAddress' --output text

Write-Host "✅ EC2 instance running at: $EC2_PUBLIC_IP" -ForegroundColor Green

# 5. Create RDS instance
Write-Host "🗄️ Creating RDS PostgreSQL instance..." -ForegroundColor Yellow
$DB_PASSWORD = -join ((65..90) + (97..122) + (48..57) | Get-Random -Count 12 | % {[char]$_})
$DB_IDENTIFIER = "$PROJECT_NAME-db-$TIMESTAMP"

aws rds create-db-instance --db-instance-identifier $DB_IDENTIFIER --db-instance-class db.t3.micro --engine postgres --engine-version 15.7 --master-username skilllink --master-user-password $DB_PASSWORD --allocated-storage 20 --storage-type gp2 --vpc-security-group-ids $SECURITY_GROUP_ID --backup-retention-period 0 --no-multi-az --publicly-accessible

# Allow RDS access from EC2
aws ec2 authorize-security-group-ingress --group-id $SECURITY_GROUP_ID --protocol tcp --port 5432 --source-group $SECURITY_GROUP_ID

Write-Host "⏳ Waiting for RDS instance to be available (this takes 5-10 minutes)..." -ForegroundColor Yellow
aws rds wait db-instance-available --db-instance-identifier $DB_IDENTIFIER

$DB_ENDPOINT = aws rds describe-db-instances --db-instance-identifier $DB_IDENTIFIER --query 'DBInstances[0].Endpoint.Address' --output text

Write-Host "✅ RDS instance available at: $DB_ENDPOINT" -ForegroundColor Green

# Display completion info
Write-Host ""
Write-Host "🎉 Deployment Complete!" -ForegroundColor Green
Write-Host "======================"
Write-Host "Frontend URL: $S3_WEBSITE_URL"
Write-Host "Backend IP:   $EC2_PUBLIC_IP"
Write-Host "Database:     $DB_ENDPOINT"
Write-Host ""
Write-Host "💾 Save these details:"
Write-Host "Timestamp:    $TIMESTAMP"
Write-Host "Key file:     $KEY_NAME.pem"
Write-Host "Instance ID:  $INSTANCE_ID"
Write-Host "DB Password:  $DB_PASSWORD"
Write-Host ""
Write-Host "📝 Next steps:"
Write-Host "1. Wait 2-3 minutes for EC2 to complete setup"
Write-Host "2. SSH to configure the backend:"
Write-Host "   ssh -i $KEY_NAME.pem ec2-user@$EC2_PUBLIC_IP"
Write-Host ""
Write-Host "💰 Monthly costs (within free tier):"
Write-Host "- EC2 t2.micro: `$0 (750 hours free)"
Write-Host "- RDS db.t3.micro: `$0 (750 hours free)"
Write-Host "- S3 storage: `$0 (5GB free)"
Write-Host ""
Write-Host "🧹 To cleanup when done:"
Write-Host "./cleanup-aws.sh $TIMESTAMP"