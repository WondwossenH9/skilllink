# Simple AWS Setup Test

$AWS_CLI = "C:\Program Files\Amazon\AWSCLIV2\aws.exe"

Write-Host "SkillLink AWS Setup Validation" -ForegroundColor Cyan
Write-Host "==============================="

$allGood = $true

# Test AWS CLI
Write-Host "1. Testing AWS CLI..." -ForegroundColor Yellow
if (Test-Path $AWS_CLI) {
    Write-Host "   AWS CLI found" -ForegroundColor Green
} else {
    Write-Host "   AWS CLI not found at: $AWS_CLI" -ForegroundColor Red
    $allGood = $false
}

# Test AWS credentials
Write-Host "2. Testing AWS credentials..." -ForegroundColor Yellow
try {
    $identity = & $AWS_CLI sts get-caller-identity --output text 2>$null
    if ($identity) {
        Write-Host "   AWS credentials configured" -ForegroundColor Green
    } else {
        Write-Host "   AWS credentials not working" -ForegroundColor Red
        $allGood = $false
    }
} catch {
    Write-Host "   AWS credentials not configured" -ForegroundColor Red
    $allGood = $false
}

# Test Node.js
Write-Host "3. Testing Node.js..." -ForegroundColor Yellow
if (Get-Command node -ErrorAction SilentlyContinue) {
    $nodeVersion = node --version
    Write-Host "   Node.js found: $nodeVersion" -ForegroundColor Green
} else {
    Write-Host "   Node.js not found" -ForegroundColor Red
    $allGood = $false
}

# Test project files
Write-Host "4. Testing project structure..." -ForegroundColor Yellow
if ((Test-Path "frontend\package.json") -and (Test-Path "backend\package.json")) {
    Write-Host "   Project structure looks good" -ForegroundColor Green
} else {
    Write-Host "   Project files missing" -ForegroundColor Red
    $allGood = $false
}

Write-Host ""
if ($allGood) {
    Write-Host "All checks passed! Ready to deploy." -ForegroundColor Green
    Write-Host "Run: .\deploy-aws-simple.ps1" -ForegroundColor White
} else {
    Write-Host "Some issues found. Please fix them first." -ForegroundColor Red
}

Write-Host ""
Write-Host "Expected AWS costs: $0-5/month (free tier)" -ForegroundColor Cyan