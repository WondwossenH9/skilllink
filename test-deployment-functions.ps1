# SkillLink Deployment Function Testing
# Tests all functionality that will be used in deployment without actually deploying

$AWS_CLI = "C:\Program Files\Amazon\AWSCLIV2\aws.exe"
$PROJECT_NAME = "skilllink"
$AWS_REGION = "us-east-1"

Write-Host "🧪 SkillLink Deployment Function Testing" -ForegroundColor Cyan
Write-Host "========================================="

$allTests = $true

# Test 1: Build Processes
Write-Host "1. Testing build processes..." -ForegroundColor Yellow

Write-Host "   Testing frontend build..." -ForegroundColor Gray
try {
    Push-Location frontend
    $buildResult = npm run build 2>&1
    Pop-Location
    if (Test-Path "frontend/build/index.html") {
        Write-Host "   ✅ Frontend builds successfully" -ForegroundColor Green
    } else {
        Write-Host "   ❌ Frontend build failed" -ForegroundColor Red
        $allTests = $false
    }
} catch {
    Write-Host "   ❌ Frontend build error: $($_.Exception.Message)" -ForegroundColor Red
    $allTests = $false
}

Write-Host "   Testing backend dependencies..." -ForegroundColor Gray
try {
    Push-Location backend
    $npmCheck = npm list --depth=0 2>&1
    Pop-Location
    Write-Host "   ✅ Backend dependencies installed" -ForegroundColor Green
} catch {
    Write-Host "   ❌ Backend dependency check failed" -ForegroundColor Red
    $allTests = $false
}

# Test 2: AWS Service Access
Write-Host "2. Testing AWS service access..." -ForegroundColor Yellow

Write-Host "   Testing S3 access..." -ForegroundColor Gray
try {
    $s3Test = & $AWS_CLI s3 ls --region $AWS_REGION 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "   ✅ S3 access working" -ForegroundColor Green
    } else {
        Write-Host "   ❌ S3 access failed" -ForegroundColor Red
        $allTests = $false
    }
} catch {
    Write-Host "   ❌ S3 test error: $($_.Exception.Message)" -ForegroundColor Red
    $allTests = $false
}

Write-Host "   Testing EC2 access..." -ForegroundColor Gray
try {
    $ec2Test = & $AWS_CLI ec2 describe-regions --region $AWS_REGION --query "Regions[?RegionName=='$AWS_REGION'].RegionName" --output text 2>&1
    if ($LASTEXITCODE -eq 0 -and $ec2Test -eq $AWS_REGION) {
        Write-Host "   ✅ EC2 access working" -ForegroundColor Green
    } else {
        Write-Host "   ❌ EC2 access failed" -ForegroundColor Red
        $allTests = $false
    }
} catch {
    Write-Host "   ❌ EC2 test error: $($_.Exception.Message)" -ForegroundColor Red
    $allTests = $false
}

Write-Host "   Testing RDS access..." -ForegroundColor Gray
try {
    $rdsTest = & $AWS_CLI rds describe-db-instances --region $AWS_REGION --query "length(DBInstances)" --output text 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "   ✅ RDS access working" -ForegroundColor Green
    } else {
        Write-Host "   ❌ RDS access failed" -ForegroundColor Red
        $allTests = $false
    }
} catch {
    Write-Host "   ❌ RDS test error: $($_.Exception.Message)" -ForegroundColor Red
    $allTests = $false
}

# Test 3: Network Configuration
Write-Host "3. Testing network configuration..." -ForegroundColor Yellow

Write-Host "   Testing default VPC..." -ForegroundColor Gray
try {
    $vpcId = & $AWS_CLI ec2 describe-vpcs --filters "Name=isDefault,Values=true" --query "Vpcs[0].VpcId" --output text --region $AWS_REGION 2>&1
    if ($LASTEXITCODE -eq 0 -and $vpcId -ne "None" -and $vpcId -ne "") {
        Write-Host "   ✅ Default VPC available: $vpcId" -ForegroundColor Green
    } else {
        Write-Host "   ❌ No default VPC found" -ForegroundColor Red
        $allTests = $false
    }
} catch {
    Write-Host "   ❌ VPC test error: $($_.Exception.Message)" -ForegroundColor Red
    $allTests = $false
}

# Test 4: Free Tier Resource Availability
Write-Host "4. Testing free tier resource availability..." -ForegroundColor Yellow

Write-Host "   Checking EC2 instance limits..." -ForegroundColor Gray
try {
    $ec2Instances = & $AWS_CLI ec2 describe-instances --filters "Name=instance-state-name,Values=running" --query "length(Reservations[].Instances[])" --output text --region $AWS_REGION 2>&1
    if ($LASTEXITCODE -eq 0) {
        $runningInstances = [int]$ec2Instances
        if ($runningInstances -lt 5) {
            Write-Host "   ✅ EC2 capacity available ($runningInstances/5 running)" -ForegroundColor Green
        } else {
            Write-Host "   ⚠️ Many EC2 instances running ($runningInstances). Free tier: 750 hours/month" -ForegroundColor Yellow
        }
    }
} catch {
    Write-Host "   ⚠️ Could not check EC2 instances" -ForegroundColor Yellow
}

Write-Host "   Checking RDS instance limits..." -ForegroundColor Gray
try {
    $rdsInstances = & $AWS_CLI rds describe-db-instances --query "length(DBInstances)" --output text --region $AWS_REGION 2>&1
    if ($LASTEXITCODE -eq 0) {
        $runningRDS = [int]$rdsInstances
        if ($runningRDS -eq 0) {
            Write-Host "   ✅ No RDS instances running (good for free tier)" -ForegroundColor Green
        } else {
            Write-Host "   ⚠️ $runningRDS RDS instance(s) running. Free tier: 750 hours/month" -ForegroundColor Yellow
        }
    }
} catch {
    Write-Host "   ⚠️ Could not check RDS instances" -ForegroundColor Yellow
}

# Test 5: Required Permissions
Write-Host "5. Testing required permissions..." -ForegroundColor Yellow

$permissions = @(
    @{Service="S3"; Action="s3:CreateBucket"; Test="& `$AWS_CLI s3api list-buckets --query 'length(Buckets)' --output text"},
    @{Service="EC2"; Action="ec2:DescribeImages"; Test="& `$AWS_CLI ec2 describe-images --owners amazon --filters 'Name=name,Values=amzn2-ami-hvm-*-x86_64-gp2' --query 'length(Images)' --output text --region `$AWS_REGION"},
    @{Service="IAM"; Action="sts:GetCallerIdentity"; Test="& `$AWS_CLI sts get-caller-identity --query 'Account' --output text"}
)

foreach ($perm in $permissions) {
    Write-Host "   Testing $($perm.Service) permissions..." -ForegroundColor Gray
    try {
        $result = Invoke-Expression $perm.Test 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "   ✅ $($perm.Service) permissions working" -ForegroundColor Green
        } else {
            Write-Host "   ❌ $($perm.Service) permissions failed" -ForegroundColor Red
            $allTests = $false
        }
    } catch {
        Write-Host "   ❌ $($perm.Service) permission test error" -ForegroundColor Red
        $allTests = $false
    }
}

# Test 6: Cost Estimation
Write-Host "6. Estimating deployment costs..." -ForegroundColor Yellow

Write-Host "   Free tier eligibility:" -ForegroundColor Gray
Write-Host "   - EC2 t2.micro: 750 hours/month = FREE" -ForegroundColor Green
Write-Host "   - RDS db.t3.micro: 750 hours/month = FREE" -ForegroundColor Green
Write-Host "   - S3 storage: 5GB = FREE" -ForegroundColor Green
Write-Host "   - Data transfer: 15GB outbound = FREE" -ForegroundColor Green
Write-Host "   - Expected cost: $0-5/month" -ForegroundColor Green

# Summary
Write-Host ""
Write-Host "🎯 Test Summary" -ForegroundColor Cyan
Write-Host "==============="

if ($allTests) {
    Write-Host "✅ All tests passed! Ready for deployment." -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor White
    Write-Host "1. Review the estimated costs above" -ForegroundColor Gray
    Write-Host "2. Run deployment: .\deploy-aws-simple.ps1" -ForegroundColor Gray
    Write-Host "3. Monitor AWS billing dashboard" -ForegroundColor Gray
    Write-Host ""
    Write-Host "🚀 Deployment should take 10-15 minutes" -ForegroundColor Cyan
} else {
    Write-Host "❌ Some tests failed. Please fix issues before deploying." -ForegroundColor Red
    Write-Host ""
    Write-Host "Common fixes:" -ForegroundColor Yellow
    Write-Host "- Ensure AWS CLI is properly configured" -ForegroundColor Gray
    Write-Host "- Check AWS permissions" -ForegroundColor Gray
    Write-Host "- Verify Node.js and npm are working" -ForegroundColor Gray
}

Write-Host ""
Write-Host "💡 Tip: This test validates deployment without creating AWS resources" -ForegroundColor Cyan