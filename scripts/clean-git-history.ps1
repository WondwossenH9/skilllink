# CRITICAL: Remove sensitive files from git history
# This script removes all files containing exposed credentials from git history

Write-Host "🚨 CRITICAL SECURITY ACTION: Cleaning Git History" -ForegroundColor Red
Write-Host "===============================================" -ForegroundColor Red

Write-Host "`n⚠️  WARNING: This will remove sensitive files from your git history." -ForegroundColor Yellow
Write-Host "This action cannot be undone and will rewrite git history." -ForegroundColor Yellow

$confirm = Read-Host "`nAre you sure you want to proceed? (yes/no)"
if ($confirm -ne "yes") {
    Write-Host "`n❌ Operation cancelled." -ForegroundColor Red
    exit 1
}

Write-Host "`n🧹 Starting git history cleanup..." -ForegroundColor Cyan

# List of files to remove from git history
$filesToRemove = @(
    "deploy-backend-app.ps1",
    "quick-backend-deploy.sh", 
    "infrastructure/deployment-config.env",
    "deploy-temp/.env",
    "deploy-temp/env.*",
    "*.env.deployment"
)

Write-Host "`n📋 Files to be removed from git history:" -ForegroundColor Yellow
foreach ($file in $filesToRemove) {
    Write-Host "   - $file" -ForegroundColor Gray
}

Write-Host "`n🔄 Running git filter-branch..." -ForegroundColor Cyan

# Create the filter-branch command
$filterCommand = "git filter-branch --force --index-filter '"
foreach ($file in $filesToRemove) {
    $filterCommand += "git rm --cached --ignore-unmatch `"$file`" && "
}
$filterCommand = $filterCommand.TrimEnd(" && ")
$filterCommand += "' --prune-empty --tag-name-filter cat -- --all"

Write-Host "`nExecuting: $filterCommand" -ForegroundColor Gray

try {
    # Execute the filter-branch command
    Invoke-Expression $filterCommand
    
    Write-Host "`n✅ Git history cleaned successfully!" -ForegroundColor Green
    
    Write-Host "`n🔄 Force pushing to remote..." -ForegroundColor Cyan
    git push origin --force --all
    
    Write-Host "`n✅ Remote repository updated!" -ForegroundColor Green
    
    Write-Host "`n🧹 Cleaning up local references..." -ForegroundColor Cyan
    git for-each-ref --format="delete %(refname)" refs/original | git update-ref --stdin
    git reflog expire --expire=now --all
    git gc --prune=now --aggressive
    
    Write-Host "`n✅ Local cleanup completed!" -ForegroundColor Green
    
    Write-Host "`n🎉 Git history cleanup completed successfully!" -ForegroundColor Green
    Write-Host "All sensitive files have been removed from git history." -ForegroundColor Green
    
} catch {
    Write-Host "`n❌ Error during git history cleanup:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host "`nPlease check the error and try again." -ForegroundColor Yellow
    exit 1
}

Write-Host "`n📋 Next steps:" -ForegroundColor Yellow
Write-Host "1. Verify no sensitive data remains: git log --all --full-history -- ." -ForegroundColor Gray
Write-Host "2. Run credential rotation script" -ForegroundColor Gray
Write-Host "3. Deploy secure infrastructure" -ForegroundColor Gray
