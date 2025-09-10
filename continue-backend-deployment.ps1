# Continue Backend Deployment - Handle Existing Resources
$AWS_CLI = "C:\Program Files\Amazon\AWSCLIV2\aws.exe"
$TIMESTAMP = "1757320302"
$PROJECT_NAME = "skilllink"

Write-Host "Continuing Backend Deployment..." -ForegroundColor Cyan

# Variables
$KEY_NAME = "$PROJECT_NAME-key-$TIMESTAMP"
$SG_NAME = "$PROJECT_NAME-sg-$TIMESTAMP"
$DB_IDENTIFIER = "$PROJECT_NAME-db-$TIMESTAMP"
$DB_PASSWORD = "SkillLink2025!"

# Check if security group exists
Write-Host "Checking for existing security group..." -ForegroundColor Yellow
$SECURITY_GROUP_ID = & $AWS_CLI ec2 describe-security-groups --filters "Name=group-name,Values=$SG_NAME" --query 'SecurityGroups[0].GroupId' --output text 2>$null

if ($SECURITY_GROUP_ID -and $SECURITY_GROUP_ID -ne "None") {
    Write-Host "Using existing security group: $SECURITY_GROUP_ID" -ForegroundColor Green
} else {
    # Create new security group
    Write-Host "Creating new security group..." -ForegroundColor Yellow
    $VPC_ID = & $AWS_CLI ec2 describe-vpcs --filters "Name=isDefault,Values=true" --query "Vpcs[0].VpcId" --output text
    $SECURITY_GROUP_ID = & $AWS_CLI ec2 create-security-group --group-name $SG_NAME --description "SkillLink security group" --vpc-id $VPC_ID --query 'GroupId' --output text
    
    # Configure security group
    $MY_IP = (Invoke-WebRequest -Uri "https://checkip.amazonaws.com" -UseBasicParsing).Content.Trim()
    & $AWS_CLI ec2 authorize-security-group-ingress --group-id $SECURITY_GROUP_ID --protocol tcp --port 22 --cidr "$MY_IP/32"
    & $AWS_CLI ec2 authorize-security-group-ingress --group-id $SECURITY_GROUP_ID --protocol tcp --port 80 --cidr "0.0.0.0/0"
    & $AWS_CLI ec2 authorize-security-group-ingress --group-id $SECURITY_GROUP_ID --protocol tcp --port 5432 --source-group $SECURITY_GROUP_ID
    Write-Host "Security group created: $SECURITY_GROUP_ID" -ForegroundColor Green
}

# Check for existing EC2 instance
Write-Host "Checking for existing EC2 instance..." -ForegroundColor Yellow
$INSTANCE_ID = & $AWS_CLI ec2 describe-instances --filters "Name=tag:Name,Values=$PROJECT_NAME-server" "Name=instance-state-name,Values=running,pending" --query 'Reservations[0].Instances[0].InstanceId' --output text 2>$null

if ($INSTANCE_ID -and $INSTANCE_ID -ne "None") {
    Write-Host "Found existing EC2 instance: $INSTANCE_ID" -ForegroundColor Green
    $EC2_PUBLIC_IP = & $AWS_CLI ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].PublicIpAddress' --output text
    Write-Host "EC2 Public IP: $EC2_PUBLIC_IP" -ForegroundColor Cyan
} else {
    # Create new EC2 instance
    Write-Host "Creating new EC2 instance..." -ForegroundColor Yellow
    $AMI_ID = & $AWS_CLI ec2 describe-images --owners amazon --filters "Name=name,Values=amzn2-ami-hvm-*-x86_64-gp2" "Name=state,Values=available" --query "Images[0].ImageId" --output text
    
    $INSTANCE_ID = & $AWS_CLI ec2 run-instances --image-id $AMI_ID --count 1 --instance-type t2.micro --key-name $KEY_NAME --security-group-ids $SECURITY_GROUP_ID --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$PROJECT_NAME-server}]" --query 'Instances[0].InstanceId' --output text
    
    Write-Host "Waiting for instance to start..." -ForegroundColor Yellow
    & $AWS_CLI ec2 wait instance-running --instance-ids $INSTANCE_ID
    
    $EC2_PUBLIC_IP = & $AWS_CLI ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].PublicIpAddress' --output text
    Write-Host "EC2 instance created: $EC2_PUBLIC_IP" -ForegroundColor Green
}

# Check for existing RDS instance
Write-Host "Checking for existing RDS instance..." -ForegroundColor Yellow
$RDS_STATUS = & $AWS_CLI rds describe-db-instances --db-instance-identifier $DB_IDENTIFIER --query 'DBInstances[0].DBInstanceStatus' --output text 2>$null

if ($RDS_STATUS) {
    Write-Host "RDS instance exists with status: $RDS_STATUS" -ForegroundColor Green
    if ($RDS_STATUS -eq "available") {
        $DB_ENDPOINT = & $AWS_CLI rds describe-db-instances --db-instance-identifier $DB_IDENTIFIER --query 'DBInstances[0].Endpoint.Address' --output text
        Write-Host "Database endpoint: $DB_ENDPOINT" -ForegroundColor Cyan
    }
} else {
    # Create new RDS instance
    Write-Host "Creating new RDS instance..." -ForegroundColor Yellow
    & $AWS_CLI rds create-db-instance --db-instance-identifier $DB_IDENTIFIER --db-instance-class db.t3.micro --engine postgres --master-username skilllink --master-user-password $DB_PASSWORD --allocated-storage 20 --vpc-security-group-ids $SECURITY_GROUP_ID
    Write-Host "RDS instance creation started (will take 5-10 minutes)" -ForegroundColor Green
}

# Final status
Write-Host ""
Write-Host "BACKEND DEPLOYMENT COMPLETE!" -ForegroundColor Green
Write-Host "==============================="
Write-Host "Frontend: http://skilllink-frontend-$TIMESTAMP.s3-website-us-east-1.amazonaws.com" -ForegroundColor Cyan
Write-Host "Backend:  $EC2_PUBLIC_IP" -ForegroundColor Cyan
Write-Host "Instance: $INSTANCE_ID" -ForegroundColor Gray
Write-Host "Database: $DB_IDENTIFIER" -ForegroundColor Gray
Write-Host "Key file: $KEY_NAME.pem" -ForegroundColor Gray
Write-Host "DB Pass:  $DB_PASSWORD" -ForegroundColor Gray
Write-Host ""
Write-Host "Monthly Cost: $0 (AWS Free Tier)" -ForegroundColor Green