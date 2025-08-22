# SkillLink Quick Deployment Script (PowerShell)
# Deploy to Vercel (Frontend) + Railway (Backend)

Write-Host "🚀 SkillLink Quick Deployment" -ForegroundColor Cyan
Write-Host "=============================" -ForegroundColor Cyan

# Check if git is available
if (!(Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Git is not installed. Please install git first." -ForegroundColor Red
    exit 1
}

# Check if all changes are committed
$gitStatus = git status --porcelain
if ($gitStatus) {
    Write-Host "⚠️  You have uncommitted changes. Please commit them first:" -ForegroundColor Yellow
    git status
    Write-Host ""
    Write-Host "Run: git add . && git commit -m 'Ready for deployment'" -ForegroundColor Yellow
    exit 1
}

# Build frontend
Write-Host "📦 Building frontend..." -ForegroundColor Yellow
Set-Location frontend
npm run build
Set-Location ..

if (!(Test-Path "frontend/build")) {
    Write-Host "❌ Frontend build failed" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Frontend built successfully" -ForegroundColor Green

# Push to GitHub
Write-Host "📤 Pushing to GitHub..." -ForegroundColor Yellow
git push origin main

Write-Host ""
Write-Host "🎉 Ready for deployment!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Go to https://vercel.com and connect your GitHub account" -ForegroundColor White
Write-Host "2. Import the skilllink repository" -ForegroundColor White
Write-Host "3. Configure build settings:" -ForegroundColor White
Write-Host "   - Framework: Create React App" -ForegroundColor Gray
Write-Host "   - Build Command: cd frontend && npm install && npm run build" -ForegroundColor Gray
Write-Host "   - Output Directory: frontend/build" -ForegroundColor Gray
Write-Host ""
Write-Host "4. Go to https://railway.app and connect your GitHub account" -ForegroundColor White
Write-Host "5. Deploy from the backend directory" -ForegroundColor White
Write-Host "6. Set environment variables in Railway:" -ForegroundColor White
Write-Host "   - NODE_ENV=production" -ForegroundColor Gray
Write-Host "   - PORT=3001" -ForegroundColor Gray
Write-Host "   - JWT_SECRET=your-secret-key" -ForegroundColor Gray
Write-Host ""
Write-Host "7. Update REACT_APP_API_URL in Vercel with your Railway URL" -ForegroundColor White
Write-Host ""
Write-Host "📖 See DEPLOYMENT_GUIDE.md for detailed instructions" -ForegroundColor Cyan
