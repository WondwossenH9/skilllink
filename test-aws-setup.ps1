# SkillLink AWS Setup Validation Script

Write-Host "🔍 SkillLink AWS Setup Validation" -ForegroundColor Cyan
Write-Host "================================="

$allGood = $true

# Test AWS CLI
Write-Host "1. Testing AWS CLI..." -ForegroundColor Yellow
if (Get-Command aws -ErrorAction SilentlyContinue) {
    $awsVersion = aws --version
    Write-Host "✅ AWS CLI found: $awsVersion" -ForegroundColor Green
} else {
    Write-Host "❌ AWS CLI not found" -ForegroundColor Red
    Write-Host "   Install from: https://aws.amazon.com/cli/" -ForegroundColor Yellow
    $allGood = $false
}

# Test AWS credentials
Write-Host "2. Testing AWS credentials..." -ForegroundColor Yellow
try {
    $identity = aws sts get-caller-identity --output text 2>$null
    if ($identity) {
        $account = ($identity -split "`t")[0]
        $user = ($identity -split "`t")[1]
        Write-Host "✅ AWS credentials configured" -ForegroundColor Green
        Write-Host "   Account: $account" -ForegroundColor Gray
        Write-Host "   User: $user" -ForegroundColor Gray
    } else {
        Write-Host "❌ AWS credentials not working" -ForegroundColor Red
        Write-Host "   Run: aws configure" -ForegroundColor Yellow
        $allGood = $false
    }
} catch {
    Write-Host "❌ AWS credentials not configured" -ForegroundColor Red
    Write-Host "   Run: aws configure" -ForegroundColor Yellow
    $allGood = $false
}

# Test Node.js
Write-Host "3. Testing Node.js..." -ForegroundColor Yellow
if (Get-Command node -ErrorAction SilentlyContinue) {
    $nodeVersion = node --version
    if ($nodeVersion -match "v(\d+)\.") {
        $majorVersion = [int]$matches[1]
        if ($majorVersion -ge 18) {
            Write-Host "✅ Node.js found: $nodeVersion" -ForegroundColor Green
        } else {
            Write-Host "⚠️ Node.js version too old: $nodeVersion (need 18+)" -ForegroundColor Yellow
            Write-Host "   Update from: https://nodejs.org/" -ForegroundColor Yellow
            $allGood = $false
        }
    }
} else {
    Write-Host "❌ Node.js not found" -ForegroundColor Red
    Write-Host "   Install from: https://nodejs.org/" -ForegroundColor Yellow
    $allGood = $false
}

# Test npm
Write-Host "4. Testing npm..." -ForegroundColor Yellow
if (Get-Command npm -ErrorAction SilentlyContinue) {
    $npmVersion = npm --version
    Write-Host "✅ npm found: $npmVersion" -ForegroundColor Green
} else {
    Write-Host "❌ npm not found (should come with Node.js)" -ForegroundColor Red
    $allGood = $false
}

# Test project structure
Write-Host "5. Testing project structure..." -ForegroundColor Yellow
if (Test-Path "frontend\package.json") {
    Write-Host "✅ Frontend found" -ForegroundColor Green
} else {
    Write-Host "❌ Frontend package.json not found" -ForegroundColor Red
    $allGood = $false
}

if (Test-Path "backend\package.json") {
    Write-Host "✅ Backend found" -ForegroundColor Green
} else {
    Write-Host "❌ Backend package.json not found" -ForegroundColor Red
    $allGood = $false
}

# Test AWS region
Write-Host "6. Testing AWS region..." -ForegroundColor Yellow
try {
    $region = aws configure get region
    if ($region -eq "us-east-1") {
        Write-Host "✅ AWS region set to us-east-1" -ForegroundColor Green
    } else {
        Write-Host "⚠️ AWS region is '$region', recommended: us-east-1" -ForegroundColor Yellow
        Write-Host "   Change with: aws configure set region us-east-1" -ForegroundColor Yellow
    }
} catch {
    Write-Host "⚠️ No default region set" -ForegroundColor Yellow
    Write-Host "   Set with: aws configure set region us-east-1" -ForegroundColor Yellow
}

# Summary
Write-Host ""
if ($allGood) {
    Write-Host "🎉 All checks passed! Ready to deploy." -ForegroundColor Green
    Write-Host ""
    Write-Host "Next step:" -ForegroundColor Cyan
    Write-Host "  .\deploy-aws-simple.ps1" -ForegroundColor White
} else {
    Write-Host "❌ Some issues found. Please fix them before deploying." -ForegroundColor Red
}

Write-Host ""
Write-Host "Expected AWS costs (free tier):" -ForegroundColor Cyan
Write-Host "- EC2 t2.micro: `$0 - 750 hours/month free" -ForegroundColor Gray
Write-Host "- RDS db.t3.micro: `$0 - 750 hours/month free" -ForegroundColor Gray
Write-Host "- S3 storage: `$0 - 5GB free" -ForegroundColor Gray
Write-Host "- Data transfer: `$0 - 15GB free" -ForegroundColor Gray
Write-Host "Total: `$0 to `$5 per month" -ForegroundColor Green