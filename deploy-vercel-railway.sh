#!/bin/bash

# SkillLink Quick Deployment Script
# Deploy to Vercel (Frontend) + Railway (Backend)

echo "🚀 SkillLink Quick Deployment"
echo "============================="

# Check if git is available
if ! command -v git &> /dev/null; then
    echo "❌ Git is not installed. Please install git first."
    exit 1
fi

# Check if all changes are committed
if [[ -n $(git status --porcelain) ]]; then
    echo "⚠️  You have uncommitted changes. Please commit them first:"
    git status
    echo ""
    echo "Run: git add . && git commit -m 'Ready for deployment'"
    exit 1
fi

# Build frontend
echo "📦 Building frontend..."
cd frontend
npm run build
cd ..

if [[ ! -d frontend/build ]]; then
    echo "❌ Frontend build failed"
    exit 1
fi

echo "✅ Frontend built successfully"

# Push to GitHub
echo "📤 Pushing to GitHub..."
git push origin main

echo ""
echo "🎉 Ready for deployment!"
echo ""
echo "Next steps:"
echo "1. Go to https://vercel.com and connect your GitHub account"
echo "2. Import the skilllink repository"
echo "3. Configure build settings:"
echo "   - Framework: Create React App"
echo "   - Build Command: cd frontend && npm install && npm run build"
echo "   - Output Directory: frontend/build"
echo ""
echo "4. Go to https://railway.app and connect your GitHub account"
echo "5. Deploy from the backend directory"
echo "6. Set environment variables in Railway:"
echo "   - NODE_ENV=production"
echo "   - PORT=3001"
echo "   - JWT_SECRET=your-secret-key"
echo ""
echo "7. Update REACT_APP_API_URL in Vercel with your Railway URL"
echo ""
echo "📖 See DEPLOYMENT_GUIDE.md for detailed instructions"
