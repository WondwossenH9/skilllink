# Simple script to check for exposed secrets
Write-Host "Checking for exposed secrets..." -ForegroundColor Cyan

# Check for specific exposed credentials
$secrets = @(
    "SkillLink2025!",
    "skilllink-production-jwt-secret",
    "34.228.73.44",
    "i-016e9c49216f49b35",
    "skilllink-db-1757320302"
)

$found = $false

foreach ($secret in $secrets) {
    Write-Host "`nChecking for: $secret" -ForegroundColor Yellow
    
    $results = Get-ChildItem -Recurse -File | Select-String -Pattern $secret -SimpleMatch
    
    if ($results) {
        Write-Host "FOUND in:" -ForegroundColor Red
        foreach ($result in $results) {
            Write-Host "   - $($result.Filename):$($result.LineNumber)" -ForegroundColor Red
        }
        $found = $true
    } else {
        Write-Host "Not found" -ForegroundColor Green
    }
}

if ($found) {
    Write-Host "`nSECURITY ISSUES FOUND!" -ForegroundColor Red
    Write-Host "Please remove or rotate these credentials before proceeding." -ForegroundColor Red
} else {
    Write-Host "`nNO SECURITY ISSUES FOUND!" -ForegroundColor Green
    Write-Host "Repository is clean and ready for deployment." -ForegroundColor Green
}
