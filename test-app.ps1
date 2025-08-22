# SkillLink Application Test Script (PowerShell)
# Tests all features before AWS deployment

Write-Host "🧪 Testing SkillLink Application" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan

# Test counters
$PASSED = 0
$FAILED = 0

# Test function
function Test-Endpoint {
    param(
        [string]$Name,
        [string]$Url,
        [int]$ExpectedStatus = 200
    )
    
    Write-Host "Testing $Name... " -NoNewline
    
    try {
        $response = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 10
        if ($response.StatusCode -eq $ExpectedStatus) {
            Write-Host "✅ PASS" -ForegroundColor Green
            $script:PASSED++
        } else {
            Write-Host "❌ FAIL (Status: $($response.StatusCode))" -ForegroundColor Red
            $script:FAILED++
        }
    }
    catch {
        Write-Host "❌ FAIL" -ForegroundColor Red
        $script:FAILED++
    }
}

# Check if servers are running
Write-Host "📋 Checking server status..." -ForegroundColor Yellow

# Test backend health
Test-Endpoint -Name "Backend Health" -Url "http://localhost:3001/api/health"

# Test backend skills endpoint
Test-Endpoint -Name "Skills API" -Url "http://localhost:3001/api/skills"

# Test frontend
Test-Endpoint -Name "Frontend" -Url "http://localhost:3000"

Write-Host ""
Write-Host "📊 Test Results:" -ForegroundColor Cyan
Write-Host "Passed: $PASSED" -ForegroundColor Green
Write-Host "Failed: $FAILED" -ForegroundColor Red

if ($FAILED -eq 0) {
    Write-Host "🎉 All tests passed! Application is ready for deployment." -ForegroundColor Green
    exit 0
} else {
    Write-Host "❌ Some tests failed. Please fix issues before deployment." -ForegroundColor Red
    exit 1
}
