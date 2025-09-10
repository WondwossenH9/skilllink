# Complete SkillLink Backend Deployment
# Uses same timestamp as successful frontend deployment

$AWS_CLI = "C:\Program Files\Amazon\AWSCLIV2\aws.exe"
$PROJECT_NAME = "skilllink"
$AWS_REGION = "us-east-1"
$TIMESTAMP = "1757320302"

Write-Host "🚀 Completing SkillLink Backend Deployment" -ForegroundColor Cyan
Write-Host "==========================================="

# Variables
$KEY_NAME = "$PROJECT_NAME-key-$TIMESTAMP"
$SG_NAME = "$PROJECT_NAME-sg-$TIMESTAMP"
$DB_IDENTIFIER = "$PROJECT_NAME-db-$TIMESTAMP"
$DB_PASSWORD = "SkillLink2025!"

Write-Host "📋 Using timestamp: $TIMESTAMP" -ForegroundColor Blue

# 1. Create or verify key pair
Write-Host "🔑 Setting up EC2 key pair..." -ForegroundColor Yellow
if (-not (Test-Path "$KEY_NAME.pem")) {
    try {
        & $AWS_CLI ec2 create-key-pair --key-name $KEY_NAME --query 'KeyMaterial' --output text > "$KEY_NAME.pem"
        Write-Host "   ✅ Key pair created: $KEY_NAME.pem" -ForegroundColor Green
    } catch {
        Write-Host "   ⚠️ Key pair may already exist" -ForegroundColor Yellow
    }
} else {
    Write-Host "   ✅ Key pair already exists: $KEY_NAME.pem" -ForegroundColor Green
}

# 2. Get VPC and create security group
Write-Host "🛡️ Setting up security group..." -ForegroundColor Yellow
$VPC_ID = & $AWS_CLI ec2 describe-vpcs --filters "Name=isDefault,Values=true" --query "Vpcs[0].VpcId" --output text
Write-Host "   📍 Using VPC: $VPC_ID" -ForegroundColor Blue

try {
    $SECURITY_GROUP_ID = & $AWS_CLI ec2 create-security-group --group-name $SG_NAME --description "SkillLink security group" --vpc-id $VPC_ID --query 'GroupId' --output text
    
    # Configure security rules
    $MY_IP = (Invoke-WebRequest -Uri "https://checkip.amazonaws.com" -UseBasicParsing).Content.Trim()
    & $AWS_CLI ec2 authorize-security-group-ingress --group-id $SECURITY_GROUP_ID --protocol tcp --port 22 --cidr "$MY_IP/32"
    & $AWS_CLI ec2 authorize-security-group-ingress --group-id $SECURITY_GROUP_ID --protocol tcp --port 80 --cidr "0.0.0.0/0"
    & $AWS_CLI ec2 authorize-security-group-ingress --group-id $SECURITY_GROUP_ID --protocol tcp --port 5432 --source-group $SECURITY_GROUP_ID
    
    Write-Host "   ✅ Security group created: $SECURITY_GROUP_ID" -ForegroundColor Green
    Write-Host "   🌐 Your IP: $MY_IP (SSH access)" -ForegroundColor Cyan
} catch {
    Write-Host "   ⚠️ Security group may already exist, finding existing..." -ForegroundColor Yellow
    $SECURITY_GROUP_ID = & $AWS_CLI ec2 describe-security-groups --filters "Name=group-name,Values=$SG_NAME" --query 'SecurityGroups[0].GroupId' --output text
    if ($SECURITY_GROUP_ID -and $SECURITY_GROUP_ID -ne "None") {
        Write-Host "   ✅ Using existing security group: $SECURITY_GROUP_ID" -ForegroundColor Green
    } else {
        Write-Host "   ❌ Could not create or find security group" -ForegroundColor Red
        exit 1
    }
}

# 3. Create EC2 instance
Write-Host "💻 Launching EC2 instance..." -ForegroundColor Yellow
$AMI_ID = & $AWS_CLI ec2 describe-images --owners amazon --filters "Name=name,Values=amzn2-ami-hvm-*-x86_64-gp2" "Name=state,Values=available" --query "Images[0].ImageId" --output text
Write-Host "   🖼️ Using AMI: $AMI_ID" -ForegroundColor Blue

$userData = @'
#!/bin/bash
yum update -y
yum install -y git nginx

# Install Node.js
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
export NVM_DIR="/root/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
nvm install 18
nvm use 18

# Install PM2
npm install -g pm2

# Start nginx
systemctl start nginx
systemctl enable nginx

# Create completion marker
echo "$(date): EC2 setup completed" > /var/log/user-data.log
'@

try {
    $INSTANCE_ID = & $AWS_CLI ec2 run-instances `
        --image-id $AMI_ID `
        --count 1 `
        --instance-type t2.micro `
        --key-name $KEY_NAME `
        --security-group-ids $SECURITY_GROUP_ID `
        --user-data $userData `
        --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$PROJECT_NAME-server},{Key=Project,Value=$PROJECT_NAME}]" `
        --query 'Instances[0].InstanceId' `
        --output text

    Write-Host "   ⏳ Instance launching: $INSTANCE_ID" -ForegroundColor Cyan
    Write-Host "   ⏳ Waiting for instance to be running..." -ForegroundColor Yellow
    
    & $AWS_CLI ec2 wait instance-running --instance-ids $INSTANCE_ID
    
    $EC2_PUBLIC_IP = & $AWS_CLI ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].PublicIpAddress' --output text
    
    Write-Host "   ✅ EC2 instance running!" -ForegroundColor Green
    Write-Host "   🌐 Public IP: $EC2_PUBLIC_IP" -ForegroundColor Cyan
    
} catch {
    Write-Host "   ❌ EC2 creation failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# 4. Create RDS database
Write-Host "🗄️ Creating RDS PostgreSQL database..." -ForegroundColor Yellow
try {
    & $AWS_CLI rds create-db-instance `
        --db-instance-identifier $DB_IDENTIFIER `
        --db-instance-class db.t3.micro `
        --engine postgres `
        --engine-version 15.7 `
        --master-username skilllink `
        --master-user-password $DB_PASSWORD `
        --allocated-storage 20 `
        --storage-type gp2 `
        --vpc-security-group-ids $SECURITY_GROUP_ID `
        --backup-retention-period 0 `
        --no-multi-az `
        --publicly-accessible
    
    Write-Host "   ✅ RDS creation initiated: $DB_IDENTIFIER" -ForegroundColor Green
    Write-Host "   ⏳ Database will be ready in 5-10 minutes" -ForegroundColor Yellow
    
} catch {
    if ($_.Exception.Message -like "*DBInstanceAlreadyExists*") {
        Write-Host "   ✅ RDS instance already exists: $DB_IDENTIFIER" -ForegroundColor Green
    } else {
        Write-Host "   ❌ RDS creation failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# 5. Display deployment results
Write-Host ""
Write-Host "🎉 Backend Deployment Completed!" -ForegroundColor Green
Write-Host "================================="
Write-Host ""
Write-Host "📋 Deployment Summary:" -ForegroundColor Cyan
Write-Host "✅ Frontend:     http://skilllink-frontend-$TIMESTAMP.s3-website-$AWS_REGION.amazonaws.com" -ForegroundColor Green
Write-Host "✅ Backend:      $EC2_PUBLIC_IP (EC2 t2.micro)" -ForegroundColor Green
Write-Host "⏳ Database:     $DB_IDENTIFIER (creating...)" -ForegroundColor Yellow
Write-Host ""
Write-Host "🔧 Connection Details:" -ForegroundColor Cyan
Write-Host "Instance ID:     $INSTANCE_ID"
Write-Host "Security Group:  $SECURITY_GROUP_ID"
Write-Host "SSH Key:         $KEY_NAME.pem"
Write-Host "DB Password:     $DB_PASSWORD"
Write-Host ""
Write-Host "💰 Monthly Cost: $0 (AWS Free Tier)" -ForegroundColor Green
Write-Host ""
Write-Host "🚀 Next Steps:" -ForegroundColor Yellow
Write-Host "1. Wait 5-10 minutes for RDS to become available"
Write-Host "2. SSH to EC2: ssh -i $KEY_NAME.pem ec2-user@$EC2_PUBLIC_IP"
Write-Host "3. Deploy application code to EC2"
Write-Host "4. Configure environment variables"
Write-Host ""
Write-Host "🧹 Cleanup Command:" -ForegroundColor Cyan
Write-Host "   AWS Console or use timestamp: $TIMESTAMP"