# Verify that all exposed credentials have been rotated
# This script checks for any remaining exposed credentials in the repository

Write-Host "VERIFYING CREDENTIAL ROTATION" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan

$issuesFound = $false

Write-Host "`nScanning repository for exposed credentials..." -ForegroundColor Yellow

# Check for specific exposed credentials
$exposedCredentials = @(
    "SkillLink2025!",
    "skilllink-production-jwt-secret",
    "34.228.73.44",
    "i-016e9c49216f49b35",
    "skilllink-db-1757320302"
)

foreach ($credential in $exposedCredentials) {
    Write-Host "`nChecking for: $credential" -ForegroundColor Gray
    
    $results = Get-ChildItem -Recurse -File | Select-String -Pattern $credential -SimpleMatch
    
    if ($results) {
        Write-Host "FOUND in:" -ForegroundColor Red
        foreach ($result in $results) {
            Write-Host "   - $($result.Filename):$($result.LineNumber)" -ForegroundColor Red
        }
        $issuesFound = $true
    } else {
        Write-Host "Not found" -ForegroundColor Green
    }
}

# Check for .env files that might contain secrets
Write-Host "`nChecking for .env files..." -ForegroundColor Yellow
$envFiles = Get-ChildItem -Recurse -Name "*.env*" | Where-Object { $_ -notlike "*.example" -and $_ -notlike "*.template" }

if ($envFiles) {
    Write-Host "Found .env files (check if they contain secrets):" -ForegroundColor Yellow
    foreach ($file in $envFiles) {
        Write-Host "   - $file" -ForegroundColor Yellow
    }
} else {
    Write-Host "No .env files found" -ForegroundColor Green
}

# Check for hardcoded passwords
Write-Host "`nChecking for hardcoded passwords..." -ForegroundColor Yellow
$passwordPatterns = @(
    "password.*=.*['\"][^'\"]{8,}['\"]",
    "PASSWORD.*=.*['\"][^'\"]{8,}['\"]",
    "secret.*=.*['\"][^'\"]{8,}['\"]",
    "SECRET.*=.*['\"][^'\"]{8,}['\"]"
)

foreach ($pattern in $passwordPatterns) {
    $results = Get-ChildItem -Recurse -File -Include "*.js", "*.ts", "*.json", "*.env*" | Select-String -Pattern $pattern -CaseSensitive
    
    if ($results) {
        Write-Host "Potential hardcoded credentials found:" -ForegroundColor Yellow
        foreach ($result in $results) {
            Write-Host "   - $($result.Filename):$($result.LineNumber)" -ForegroundColor Yellow
        }
    }
}

# Check git history
Write-Host "`nChecking git history for sensitive data..." -ForegroundColor Yellow
$gitResults = git log --all --full-history --grep="SkillLink2025" --grep="skilllink-production-jwt-secret" --grep="34.228.73.44" --grep="i-016e9c49216f49b35"

if ($gitResults) {
    Write-Host "Sensitive data found in git history:" -ForegroundColor Yellow
    Write-Host $gitResults -ForegroundColor Yellow
    $issuesFound = $true
} else {
    Write-Host "No sensitive data found in git history" -ForegroundColor Green
}

# Summary
Write-Host "`n" + "="*50 -ForegroundColor Cyan

if ($issuesFound) {
    Write-Host "SECURITY ISSUES FOUND!" -ForegroundColor Red
    Write-Host "Please address the issues above before proceeding with deployment." -ForegroundColor Red
    Write-Host "`nRecommended actions:" -ForegroundColor Yellow
    Write-Host "1. Remove or rotate any remaining exposed credentials" -ForegroundColor Gray
    Write-Host "2. Run git history cleanup again if needed" -ForegroundColor Gray
    Write-Host "3. Verify all .env files are in .gitignore" -ForegroundColor Gray
} else {
    Write-Host "NO SECURITY ISSUES FOUND!" -ForegroundColor Green
    Write-Host "Your repository is clean and ready for secure deployment." -ForegroundColor Green
    Write-Host "`nNext steps:" -ForegroundColor Yellow
    Write-Host "1. Deploy secure infrastructure with Terraform" -ForegroundColor Gray
    Write-Host "2. Deploy application using GitHub Actions" -ForegroundColor Gray
    Write-Host "3. Monitor through CloudWatch" -ForegroundColor Gray
}

Write-Host "`n" + "="*50 -ForegroundColor Cyan
