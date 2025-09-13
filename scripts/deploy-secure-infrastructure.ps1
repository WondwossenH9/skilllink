# Deploy secure infrastructure using Terraform
# This script deploys the production-ready infrastructure with all security measures

Write-Host "🚀 DEPLOYING SECURE INFRASTRUCTURE" -ForegroundColor Cyan
Write-Host "==================================" -ForegroundColor Cyan

# Check if AWS CLI is installed
Write-Host "`n🔍 Checking AWS CLI..." -ForegroundColor Yellow
try {
    $awsVersion = aws --version
    Write-Host "✅ AWS CLI found: $awsVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ AWS CLI not found. Please install AWS CLI first." -ForegroundColor Red
    Write-Host "Download from: https://aws.amazon.com/cli/" -ForegroundColor Yellow
    exit 1
}

# Check if Terraform is installed
Write-Host "`n🔍 Checking Terraform..." -ForegroundColor Yellow
try {
    $terraformVersion = terraform --version
    Write-Host "✅ Terraform found: $terraformVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Terraform not found. Please install Terraform first." -ForegroundColor Red
    Write-Host "Download from: https://www.terraform.io/downloads" -ForegroundColor Yellow
    exit 1
}

# Check AWS credentials
Write-Host "`n🔍 Checking AWS credentials..." -ForegroundColor Yellow
try {
    $awsIdentity = aws sts get-caller-identity
    Write-Host "✅ AWS credentials configured" -ForegroundColor Green
    Write-Host "Account: $($awsIdentity.Account)" -ForegroundColor Gray
    Write-Host "User: $($awsIdentity.Arn)" -ForegroundColor Gray
} catch {
    Write-Host "❌ AWS credentials not configured. Please run 'aws configure'" -ForegroundColor Red
    exit 1
}

# Navigate to Terraform directory
Write-Host "`n📁 Navigating to Terraform directory..." -ForegroundColor Yellow
Set-Location "infrastructure/terraform"

# Check if terraform.tfvars exists
if (-not (Test-Path "terraform.tfvars")) {
    Write-Host "`n⚠️  terraform.tfvars not found. Creating from template..." -ForegroundColor Yellow
    
    $tfvarsContent = @"
# SkillLink Production Configuration
project_name = "skilllink"
environment = "prod"
aws_region = "us-east-1"
domain_name = "your-domain.com"  # Change this to your actual domain
alert_email = "your-email@example.com"  # Change this to your email
budget_limit = 100

# Security Configuration
allowed_ssh_cidr = "0.0.0.0/0"  # Change this to your IP for security

# Database Configuration
db_name = "skilllink"
db_username = "skilllink_admin"

# Instance Configuration
instance_type = "t3.micro"
db_instance_class = "db.t3.micro"
db_allocated_storage = 20
"@
    
    $tfvarsContent | Out-File -FilePath "terraform.tfvars" -Encoding UTF8
    Write-Host "✅ Created terraform.tfvars template" -ForegroundColor Green
    Write-Host "⚠️  Please edit terraform.tfvars with your actual values before proceeding" -ForegroundColor Yellow
    
    $edit = Read-Host "`nDo you want to edit terraform.tfvars now? (y/n)"
    if ($edit -eq "y" -or $edit -eq "Y") {
        notepad terraform.tfvars
    }
}

# Initialize Terraform
Write-Host "`n🔧 Initializing Terraform..." -ForegroundColor Yellow
terraform init

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Terraform initialization failed" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Terraform initialized successfully" -ForegroundColor Green

# Plan Terraform deployment
Write-Host "`n📋 Planning Terraform deployment..." -ForegroundColor Yellow
terraform plan -out=tfplan

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Terraform plan failed" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Terraform plan completed successfully" -ForegroundColor Green

# Show plan summary
Write-Host "`n📊 Plan Summary:" -ForegroundColor Cyan
Write-Host "This will create:" -ForegroundColor Gray
Write-Host "  - VPC with public/private subnets" -ForegroundColor Gray
Write-Host "  - Application Load Balancer" -ForegroundColor Gray
Write-Host "  - Auto Scaling Group with EC2 instances" -ForegroundColor Gray
Write-Host "  - RDS PostgreSQL database (Multi-AZ)" -ForegroundColor Gray
Write-Host "  - S3 bucket for frontend" -ForegroundColor Gray
Write-Host "  - CloudWatch monitoring and alerts" -ForegroundColor Gray
Write-Host "  - AWS Secrets Manager for credentials" -ForegroundColor Gray
Write-Host "  - IAM roles and policies" -ForegroundColor Gray

$confirm = Read-Host "`nDo you want to proceed with the deployment? (yes/no)"
if ($confirm -ne "yes") {
    Write-Host "`n❌ Deployment cancelled." -ForegroundColor Red
    exit 0
}

# Apply Terraform deployment
Write-Host "`n🚀 Applying Terraform deployment..." -ForegroundColor Yellow
terraform apply tfplan

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Terraform deployment failed" -ForegroundColor Red
    exit 1
}

Write-Host "`n✅ Infrastructure deployed successfully!" -ForegroundColor Green

# Get outputs
Write-Host "`n📊 Deployment Outputs:" -ForegroundColor Cyan
terraform output

Write-Host "`n🎉 SECURE INFRASTRUCTURE DEPLOYED!" -ForegroundColor Green
Write-Host "Your SkillLink platform is now running on AWS with:" -ForegroundColor Green
Write-Host "  ✅ High availability architecture" -ForegroundColor Green
Write-Host "  ✅ Security groups and VPC" -ForegroundColor Green
Write-Host "  ✅ Load balancer and auto-scaling" -ForegroundColor Green
Write-Host "  ✅ Encrypted database" -ForegroundColor Green
Write-Host "  ✅ Secrets management" -ForegroundColor Green
Write-Host "  ✅ Monitoring and alerting" -ForegroundColor Green

Write-Host "`n📋 Next steps:" -ForegroundColor Yellow
Write-Host "1. Deploy application using GitHub Actions" -ForegroundColor Gray
Write-Host "2. Configure your domain name" -ForegroundColor Gray
Write-Host "3. Set up monitoring dashboards" -ForegroundColor Gray
Write-Host "4. Test all functionality" -ForegroundColor Gray

# Return to original directory
Set-Location "../.."
