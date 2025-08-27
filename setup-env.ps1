# SkillLink Environment Setup Script
# This script creates the necessary .env files for both backend and frontend

Write-Host "Setting up SkillLink environment files..." -ForegroundColor Green

# Backend .env file
$backendEnv = @"
# Server Configuration
PORT=3001
NODE_ENV=development

# Database Configuration
DB_DIALECT=postgres
DB_HOST=52.23.173.223
DB_PORT=5432
DB_NAME=skilllink
DB_USER=skilllink_user
DB_PASS=QJjVaWKu1IfMfJND

# JWT Configuration
JWT_SECRET=your-super-secret-jwt-key-change-this-in-production
JWT_EXPIRE=7d

# CORS Configuration
FRONTEND_URL=http://localhost:3000

# Rate Limiting
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=100
"@

# Frontend .env file
$frontendEnv = @"
# API Configuration
REACT_APP_API_URL=http://52.23.173.223:3001/api

# Environment
REACT_APP_ENV=development
"@

# Create backend .env file
$backendEnv | Out-File -FilePath "backend\.env" -Encoding UTF8
Write-Host "Created backend/.env" -ForegroundColor Yellow

# Create frontend .env file
$frontendEnv | Out-File -FilePath "frontend\.env" -Encoding UTF8
Write-Host "Created frontend/.env" -ForegroundColor Yellow

Write-Host "Environment files created successfully!" -ForegroundColor Green
Write-Host "You can now start the backend and frontend applications." -ForegroundColor Green
