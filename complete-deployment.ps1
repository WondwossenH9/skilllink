# Complete SkillLink Deployment - Continue from S3 success

$AWS_CLI = "C:\Program Files\Amazon\AWSCLIV2\aws.exe"
$PROJECT_NAME = "skilllink"
$AWS_REGION = "us-east-1"
$TIMESTAMP = "1757320302"  # Use the same timestamp from successful S3 deployment

Write-Host "Completing SkillLink Deployment" -ForegroundColor Cyan
Write-Host "==============================="

# Get existing S3 bucket info
$S3_BUCKET = "skilllink-frontend-$TIMESTAMP"
$S3_WEBSITE_URL = "http://$S3_BUCKET.s3-website-$AWS_REGION.amazonaws.com"
Write-Host "Using existing S3 bucket: $S3_BUCKET" -ForegroundColor Green

# Generate identifiers for remaining resources
$KEY_NAME = "$PROJECT_NAME-key-$TIMESTAMP"

# 1. Create EC2 key pair
Write-Host "Creating EC2 key pair..." -ForegroundColor Yellow
try {
    & $AWS_CLI ec2 create-key-pair --key-name $KEY_NAME --query 'KeyMaterial' --output text > "$KEY_NAME.pem"
    Write-Host "✅ Key pair saved as: $KEY_NAME.pem" -ForegroundColor Green
} catch {
    Write-Host "⚠️ Key pair creation failed or already exists" -ForegroundColor Yellow
}

# 2. Create security group
Write-Host "Creating security group..." -ForegroundColor Yellow
$VPC_ID = & $AWS_CLI ec2 describe-vpcs --filters "Name=isDefault,Values=true" --query "Vpcs[0].VpcId" --output text
$SG_NAME = "$PROJECT_NAME-sg-$TIMESTAMP"

try {
    $SECURITY_GROUP_ID = & $AWS_CLI ec2 create-security-group --group-name $SG_NAME --description "SkillLink simple deployment security group" --vpc-id $VPC_ID --query 'GroupId' --output text

    # Get your public IP
    $MY_IP = (Invoke-WebRequest -Uri "https://checkip.amazonaws.com" -UseBasicParsing).Content.Trim()

    # Allow SSH from your IP
    & $AWS_CLI ec2 authorize-security-group-ingress --group-id $SECURITY_GROUP_ID --protocol tcp --port 22 --cidr "$MY_IP/32"

    # Allow HTTP
    & $AWS_CLI ec2 authorize-security-group-ingress --group-id $SECURITY_GROUP_ID --protocol tcp --port 80 --cidr "0.0.0.0/0"

    Write-Host "✅ Security group created: $SECURITY_GROUP_ID" -ForegroundColor Green
} catch {
    Write-Host "⚠️ Security group creation failed or already exists" -ForegroundColor Yellow
    # Try to find existing security group
    $SECURITY_GROUP_ID = & $AWS_CLI ec2 describe-security-groups --filters "Name=group-name,Values=$SG_NAME" --query 'SecurityGroups[0].GroupId' --output text
    if ($SECURITY_GROUP_ID -and $SECURITY_GROUP_ID -ne "None") {
        Write-Host "📋 Using existing security group: $SECURITY_GROUP_ID" -ForegroundColor Cyan
    }
}

# 3. Launch EC2 instance
Write-Host "Launching EC2 instance..." -ForegroundColor Yellow
$AMI_ID = & $AWS_CLI ec2 describe-images --owners amazon --filters "Name=name,Values=amzn2-ami-hvm-*-x86_64-gp2" "Name=state,Values=available" --query "Images | sort_by(@, \`&CreationDate\`) | [-1].ImageId" --output text

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

try {
    $tagSpec = "ResourceType=instance,Tags=[{Key=Name,Value=$PROJECT_NAME-server}]"
    $INSTANCE_ID = & $AWS_CLI ec2 run-instances --image-id $AMI_ID --count 1 --instance-type t2.micro --key-name $KEY_NAME --security-group-ids $SECURITY_GROUP_ID --tag-specifications $tagSpec --user-data $userData --query 'Instances[0].InstanceId' --output text

    Write-Host "⏳ Waiting for EC2 instance to be running..." -ForegroundColor Yellow
    & $AWS_CLI ec2 wait instance-running --instance-ids $INSTANCE_ID

    $EC2_PUBLIC_IP = & $AWS_CLI ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].PublicIpAddress' --output text

    Write-Host "✅ EC2 instance running at: $EC2_PUBLIC_IP" -ForegroundColor Green
} catch {
    Write-Host "❌ EC2 instance creation failed" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
}

# 4. Create RDS instance (if EC2 succeeded)
if ($INSTANCE_ID) {
    Write-Host "Creating RDS PostgreSQL instance..." -ForegroundColor Yellow
    $DB_PASSWORD = -join ((65..90) + (97..122) + (48..57) | Get-Random -Count 12 | % {[char]$_})
    $DB_IDENTIFIER = "$PROJECT_NAME-db-$TIMESTAMP"

    try {
        & $AWS_CLI rds create-db-instance --db-instance-identifier $DB_IDENTIFIER --db-instance-class db.t3.micro --engine postgres --engine-version 15.7 --master-username skilllink --master-user-password $DB_PASSWORD --allocated-storage 20 --storage-type gp2 --vpc-security-group-ids $SECURITY_GROUP_ID --backup-retention-period 0 --no-multi-az --publicly-accessible

        # Allow RDS access from EC2
        & $AWS_CLI ec2 authorize-security-group-ingress --group-id $SECURITY_GROUP_ID --protocol tcp --port 5432 --source-group $SECURITY_GROUP_ID

        Write-Host "⏳ Waiting for RDS instance to be available (this takes 5-10 minutes)..." -ForegroundColor Yellow
        Write-Host "📝 Note: You can continue with other tasks while RDS is creating" -ForegroundColor Cyan
        
        # Don't wait for RDS to complete - it takes too long
        Write-Host "✅ RDS creation initiated. Check status with: aws rds describe-db-instances --db-instance-identifier $DB_IDENTIFIER" -ForegroundColor Green
        
    } catch {
        Write-Host "❌ RDS instance creation failed" -ForegroundColor Red
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Display completion info
Write-Host ""
Write-Host "🎉 Deployment Status Update!" -ForegroundColor Green
Write-Host "=============================="
Write-Host "✅ Frontend URL: $S3_WEBSITE_URL" -ForegroundColor Green
if ($EC2_PUBLIC_IP) {
    Write-Host "✅ Backend IP:   $EC2_PUBLIC_IP" -ForegroundColor Green
} else {
    Write-Host "❌ Backend:      Failed to create" -ForegroundColor Red
}
if ($DB_IDENTIFIER) {
    Write-Host "⏳ Database:     Creating ($DB_IDENTIFIER)" -ForegroundColor Yellow
} else {
    Write-Host "❌ Database:     Not created" -ForegroundColor Red
}
Write-Host ""
Write-Host "💾 Save these details:"
Write-Host "Timestamp:    $TIMESTAMP"
if (Test-Path "$KEY_NAME.pem") {
    Write-Host "Key file:     $KEY_NAME.pem" -ForegroundColor Green
}
if ($INSTANCE_ID) {
    Write-Host "Instance ID:  $INSTANCE_ID"
}
if ($DB_PASSWORD) {
    Write-Host "DB Password:  $DB_PASSWORD"
}
Write-Host ""
Write-Host "💰 Monthly costs (within free tier):"
Write-Host "- EC2 t2.micro: $0 (750 hours free)"
Write-Host "- RDS db.t3.micro: $0 (750 hours free)"
Write-Host "- S3 storage: $0 (5GB free)"
Write-Host ""
Write-Host "🧹 To cleanup when done:"
Write-Host ".\cleanup-aws.sh $TIMESTAMP"

# Test frontend immediately
Write-Host ""
Write-Host "🌐 Testing frontend deployment..." -ForegroundColor Cyan
try {
    $response = Invoke-WebRequest -Uri $S3_WEBSITE_URL -Method Head -TimeoutSec 10
    if ($response.StatusCode -eq 200) {
        Write-Host "✅ Frontend is accessible!" -ForegroundColor Green
        Write-Host "🔗 Visit: $S3_WEBSITE_URL" -ForegroundColor Cyan
    }
} catch {
    Write-Host "⚠️ Frontend not yet accessible (may need a few minutes)" -ForegroundColor Yellow
}