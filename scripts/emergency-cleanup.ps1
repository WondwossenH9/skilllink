# EMERGENCY CLEANUP: Remove all files containing exposed credentials
Write-Host "EMERGENCY SECURITY CLEANUP" -ForegroundColor Red
Write-Host "=========================" -ForegroundColor Red

Write-Host "`nWARNING: This will remove files containing exposed credentials." -ForegroundColor Yellow
Write-Host "This action cannot be undone!" -ForegroundColor Yellow

$confirm = Read-Host "`nAre you sure you want to proceed? (yes/no)"
if ($confirm -ne "yes") {
    Write-Host "`nOperation cancelled." -ForegroundColor Red
    exit 1
}

Write-Host "`nStarting emergency cleanup..." -ForegroundColor Cyan

# List of files to remove (containing exposed credentials)
$filesToRemove = @(
    "continue-backend-deployment.ps1",
    "deploy-backend-complete.ps1", 
    "deploy-backend-simple.ps1",
    "simple-complete-deployment.ps1",
    "deploy-to-aws-modern.sh",
    "deploy-to-aws.sh",
    "deploy-backend-direct.sh",
    "deploy-backend-ssm.sh",
    "deploy-backend.sh",
    "CELEBRATION_SUMMARY.md",
    "main.5d233c5a.js",
    "main.5d233c5a.js.map",
    "30c7588d257b7b29b7dff35f346c4563fa2e4f8a34751f48d075e952da0326b1.json",
    "86e883472564a3ffc63d59fa16dc0ccca8cfaa0d0e64c06087f1b031c5808321.json",
    "0.pack"
)

Write-Host "`nFiles to be removed:" -ForegroundColor Yellow
foreach ($file in $filesToRemove) {
    if (Test-Path $file) {
        Write-Host "   - $file" -ForegroundColor Gray
    }
}

$removedCount = 0
$notFoundCount = 0

foreach ($file in $filesToRemove) {
    if (Test-Path $file) {
        try {
            Remove-Item $file -Force
            Write-Host "   Removed: $file" -ForegroundColor Green
            $removedCount++
        } catch {
            Write-Host "   Failed to remove: $file - $($_.Exception.Message)" -ForegroundColor Red
        }
    } else {
        $notFoundCount++
    }
}

Write-Host "`nCleanup Summary:" -ForegroundColor Cyan
Write-Host "   Files removed: $removedCount" -ForegroundColor Green
Write-Host "   Files not found: $notFoundCount" -ForegroundColor Gray

# Clean up frontend build files that might contain credentials
Write-Host "`nCleaning frontend build files..." -ForegroundColor Yellow
if (Test-Path "frontend/build") {
    Remove-Item "frontend/build" -Recurse -Force
    Write-Host "   Removed frontend/build directory" -ForegroundColor Green
}

# Clean up any remaining .env files
Write-Host "`nCleaning .env files..." -ForegroundColor Yellow
Get-ChildItem -Recurse -Name "*.env*" | Where-Object { $_ -notlike "*.example" -and $_ -notlike "*.template" } | ForEach-Object {
    try {
        Remove-Item $_ -Force
        Write-Host "   Removed: $_" -ForegroundColor Green
    } catch {
        Write-Host "   Failed to remove: $_" -ForegroundColor Red
    }
}

Write-Host "`nEmergency cleanup completed!" -ForegroundColor Green
Write-Host "`nNext steps:" -ForegroundColor Yellow
Write-Host "1. Run git add . && git commit -m 'Remove files with exposed credentials'" -ForegroundColor Gray
Write-Host "2. Run git push to update remote repository" -ForegroundColor Gray
Write-Host "3. Run verification script again" -ForegroundColor Gray
Write-Host "4. Deploy secure infrastructure" -ForegroundColor Gray
