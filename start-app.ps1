# SkillLink Application Startup Script
Write-Host "Starting SkillLink Application..." -ForegroundColor Green

# Function to check if a port is in use
function Test-Port {
    param([int]$Port)
    $connection = Get-NetTCPConnection -LocalPort $Port -ErrorAction SilentlyContinue
    return $connection -ne $null
}

# Start Backend
Write-Host "Starting Backend Server..." -ForegroundColor Yellow
if (Test-Port 3001) {
    Write-Host "Port 3001 is already in use. Backend might already be running." -ForegroundColor Yellow
} else {
    Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd backend; npm start" -WindowStyle Normal
    Write-Host "Backend server starting on http://localhost:3001" -ForegroundColor Green
}

# Wait a moment for backend to start
Start-Sleep -Seconds 3

# Start Frontend
Write-Host "Starting Frontend Application..." -ForegroundColor Yellow
if (Test-Port 3000) {
    Write-Host "Port 3000 is already in use. Frontend might already be running." -ForegroundColor Yellow
} else {
    Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd frontend; npm start" -WindowStyle Normal
    Write-Host "Frontend application starting on http://localhost:3000" -ForegroundColor Green
}

Write-Host "`nSkillLink Application is starting up!" -ForegroundColor Green
Write-Host "Frontend: http://localhost:3000" -ForegroundColor Cyan
Write-Host "Backend API: http://localhost:3001/api" -ForegroundColor Cyan
Write-Host "`nYou can now:" -ForegroundColor White
Write-Host "1. Register a new account" -ForegroundColor White
Write-Host "2. Create skill offers or requests" -ForegroundColor White
Write-Host "3. Browse and match with other users" -ForegroundColor White
Write-Host "4. Manage your matches and skills" -ForegroundColor White

