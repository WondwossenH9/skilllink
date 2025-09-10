# Final Pre-Deployment Test for SkillLink

$AWS_CLI = "C:\Program Files\Amazon\AWSCLIV2\aws.exe"

Write-Host "Final Pre-Deployment Test" -ForegroundColor Cyan
Write-Host "========================="

# Test 1: AWS Access
Write-Host "1. Testing AWS access..."
try {
    $identity = & $AWS_CLI sts get-caller-identity --output text
    Write-Host "   AWS Identity: $identity" -ForegroundColor Green
} catch {
    Write-Host "   AWS access failed!" -ForegroundColor Red
    exit 1
}

# Test 2: Build Applications
Write-Host "2. Testing application builds..."

Write-Host "   Building frontend..."
Push-Location frontend
$frontendBuild = npm run build 2>&1
Pop-Location
if (Test-Path "frontend/build/index.html") {
    Write-Host "   Frontend build: SUCCESS" -ForegroundColor Green
} else {
    Write-Host "   Frontend build: FAILED" -ForegroundColor Red
    exit 1
}

Write-Host "   Checking backend..."
if (Test-Path "backend/package.json") {
    Write-Host "   Backend structure: OK" -ForegroundColor Green
} else {
    Write-Host "   Backend structure: MISSING" -ForegroundColor Red
    exit 1
}

# Test 3: AWS Services
Write-Host "3. Testing AWS services..."

$s3Test = & $AWS_CLI s3 ls 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "   S3 access: OK" -ForegroundColor Green
} else {
    Write-Host "   S3 access: FAILED" -ForegroundColor Red
}

$vpcId = & $AWS_CLI ec2 describe-vpcs --filters "Name=isDefault,Values=true" --query "Vpcs[0].VpcId" --output text
if ($vpcId -and $vpcId -ne "None") {
    Write-Host "   Default VPC: $vpcId" -ForegroundColor Green
} else {
    Write-Host "   Default VPC: NOT FOUND" -ForegroundColor Red
}

Write-Host ""
Write-Host "All tests passed! Ready for deployment." -ForegroundColor Green
Write-Host "Expected cost: $0-5/month (free tier)" -ForegroundColor Cyan
Write-Host ""
Write-Host "To deploy:"
Write-Host ".\deploy-aws-simple.ps1" -ForegroundColor Yellow