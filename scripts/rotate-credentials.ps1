# CRITICAL: Rotate all exposed credentials immediately
# This script helps you rotate the exposed credentials found in your repository

Write-Host "🚨 CRITICAL SECURITY ACTION: Rotating Exposed Credentials" -ForegroundColor Red
Write-Host "========================================================" -ForegroundColor Red

Write-Host "`n⚠️  WARNING: The following credentials were found exposed in your repository:" -ForegroundColor Red
Write-Host "   - Database password: SkillLink2025!" -ForegroundColor Yellow
Write-Host "   - JWT secrets: skilllink-production-jwt-secret-*" -ForegroundColor Yellow
Write-Host "   - RDS endpoint: skilllink-db-1757320302.ccra4a804f4g.us-east-1.rds.amazonaws.com" -ForegroundColor Yellow
Write-Host "   - EC2 instance: i-016e9c49216f49b35" -ForegroundColor Yellow
Write-Host "   - EC2 IP: 34.228.73.44" -ForegroundColor Yellow

Write-Host "`n📋 IMMEDIATE ACTIONS REQUIRED:" -ForegroundColor Yellow

Write-Host "`n1. 🔐 ROTATE DATABASE PASSWORD:" -ForegroundColor Cyan
Write-Host "   - Log into AWS Console" -ForegroundColor Gray
Write-Host "   - Go to RDS → Databases" -ForegroundColor Gray
Write-Host "   - Find: skilllink-db-1757320302" -ForegroundColor Gray
Write-Host "   - Click 'Modify' → Change master password" -ForegroundColor Gray
Write-Host "   - Generate new secure password (32+ characters)" -ForegroundColor Gray

Write-Host "`n2. 🔑 ROTATE JWT SECRETS:" -ForegroundColor Cyan
Write-Host "   - Generate new JWT secret:" -ForegroundColor Gray
Write-Host "   openssl rand -base64 64" -ForegroundColor White

Write-Host "`n3. 🗑️ TERMINATE EXPOSED EC2 INSTANCE:" -ForegroundColor Cyan
Write-Host "   - Go to EC2 → Instances" -ForegroundColor Gray
Write-Host "   - Find: i-016e9c49216f49b35" -ForegroundColor Gray
Write-Host "   - Terminate the instance" -ForegroundColor Gray

Write-Host "`n4. 🔄 ROTATE AWS ACCESS KEYS:" -ForegroundColor Cyan
Write-Host "   - Go to IAM → Users → Your User" -ForegroundColor Gray
Write-Host "   - Security credentials → Access keys" -ForegroundColor Gray
Write-Host "   - Deactivate old keys" -ForegroundColor Gray
Write-Host "   - Create new access keys" -ForegroundColor Gray

Write-Host "`n5. 🗄️ UPDATE SECRETS MANAGER:" -ForegroundColor Cyan
Write-Host "   - Go to AWS Secrets Manager" -ForegroundColor Gray
Write-Host "   - Update all secrets with new values" -ForegroundColor Gray

Write-Host "`n✅ After completing these steps, run:" -ForegroundColor Green
Write-Host "   .\scripts\verify-credentials.ps1" -ForegroundColor White

Write-Host "`n🚨 DO NOT PROCEED WITH DEPLOYMENT UNTIL ALL CREDENTIALS ARE ROTATED!" -ForegroundColor Red
