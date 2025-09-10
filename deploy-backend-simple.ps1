# Simple Backend Deployment Script
$AWS_CLI = "C:\Program Files\Amazon\AWSCLIV2\aws.exe"
$TIMESTAMP = "1757320302"
$PROJECT_NAME = "skilllink"

Write-Host "Deploying SkillLink Backend..." -ForegroundColor Cyan

# Variables
$KEY_NAME = "$PROJECT_NAME-key-$TIMESTAMP"
$SG_NAME = "$PROJECT_NAME-sg-$TIMESTAMP"
$DB_IDENTIFIER = "$PROJECT_NAME-db-$TIMESTAMP"
$DB_PASSWORD = "SkillLink2025!"

# Create key pair
Write-Host "Creating key pair..." -ForegroundColor Yellow
& $AWS_CLI ec2 create-key-pair --key-name $KEY_NAME --query 'KeyMaterial' --output text > "$KEY_NAME.pem"

# Get VPC
$VPC_ID = & $AWS_CLI ec2 describe-vpcs --filters "Name=isDefault,Values=true" --query "Vpcs[0].VpcId" --output text
Write-Host "Using VPC: $VPC_ID" -ForegroundColor Blue

# Create security group
$SECURITY_GROUP_ID = & $AWS_CLI ec2 create-security-group --group-name $SG_NAME --description "SkillLink security group" --vpc-id $VPC_ID --query 'GroupId' --output text
Write-Host "Security group: $SECURITY_GROUP_ID" -ForegroundColor Green

# Configure security group
$MY_IP = (Invoke-WebRequest -Uri "https://checkip.amazonaws.com" -UseBasicParsing).Content.Trim()
& $AWS_CLI ec2 authorize-security-group-ingress --group-id $SECURITY_GROUP_ID --protocol tcp --port 22 --cidr "$MY_IP/32"
& $AWS_CLI ec2 authorize-security-group-ingress --group-id $SECURITY_GROUP_ID --protocol tcp --port 80 --cidr "0.0.0.0/0"
& $AWS_CLI ec2 authorize-security-group-ingress --group-id $SECURITY_GROUP_ID --protocol tcp --port 5432 --source-group $SECURITY_GROUP_ID

# Get AMI
$AMI_ID = & $AWS_CLI ec2 describe-images --owners amazon --filters "Name=name,Values=amzn2-ami-hvm-*-x86_64-gp2" "Name=state,Values=available" --query "Images[0].ImageId" --output text
Write-Host "Using AMI: $AMI_ID" -ForegroundColor Blue

# Create EC2 instance  
Write-Host "Creating EC2 instance..." -ForegroundColor Yellow
$INSTANCE_ID = & $AWS_CLI ec2 run-instances --image-id $AMI_ID --count 1 --instance-type t2.micro --key-name $KEY_NAME --security-group-ids $SECURITY_GROUP_ID --query 'Instances[0].InstanceId' --output text

Write-Host "Waiting for instance..." -ForegroundColor Yellow
& $AWS_CLI ec2 wait instance-running --instance-ids $INSTANCE_ID

$EC2_PUBLIC_IP = & $AWS_CLI ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].PublicIpAddress' --output text
Write-Host "EC2 running at: $EC2_PUBLIC_IP" -ForegroundColor Green

# Create RDS
Write-Host "Creating RDS database..." -ForegroundColor Yellow
& $AWS_CLI rds create-db-instance --db-instance-identifier $DB_IDENTIFIER --db-instance-class db.t3.micro --engine postgres --master-username skilllink --master-user-password $DB_PASSWORD --allocated-storage 20 --vpc-security-group-ids $SECURITY_GROUP_ID

Write-Host ""
Write-Host "Deployment Complete!" -ForegroundColor Green
Write-Host "Frontend: http://skilllink-frontend-$TIMESTAMP.s3-website-us-east-1.amazonaws.com"
Write-Host "Backend:  $EC2_PUBLIC_IP"
Write-Host "Instance: $INSTANCE_ID"
Write-Host "Database: $DB_IDENTIFIER (creating...)"
Write-Host "Key file: $KEY_NAME.pem"
Write-Host "DB Pass:  $DB_PASSWORD"
Write-Host "Cost: $0/month (free tier)"