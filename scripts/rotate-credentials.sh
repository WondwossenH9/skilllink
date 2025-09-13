#!/bin/bash
# CRITICAL: Rotate all exposed credentials immediately
# This script helps you rotate the exposed credentials found in your repository

set -e

echo "🚨 CRITICAL SECURITY ACTION: Rotating Exposed Credentials"
echo "========================================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${RED}⚠️  WARNING: The following credentials were found exposed in your repository:${NC}"
echo "   - Database password: SkillLink2025!"
echo "   - JWT secrets: skilllink-production-jwt-secret-*"
echo "   - RDS endpoint: skilllink-db-1757320302.ccra4a804f4g.us-east-1.rds.amazonaws.com"
echo "   - EC2 instance: i-016e9c49216f49b35"
echo "   - EC2 IP: 34.228.73.44"
echo ""

echo -e "${YELLOW}📋 IMMEDIATE ACTIONS REQUIRED:${NC}"
echo ""

echo "1. 🔐 ROTATE DATABASE PASSWORD:"
echo "   - Log into AWS Console"
echo "   - Go to RDS → Databases"
echo "   - Find: skilllink-db-1757320302"
echo "   - Click 'Modify' → Change master password"
echo "   - Generate new secure password (32+ characters)"
echo ""

echo "2. 🔑 ROTATE JWT SECRETS:"
echo "   - Generate new JWT secret:"
echo "   openssl rand -base64 64"
echo ""

echo "3. 🗑️ TERMINATE EXPOSED EC2 INSTANCE:"
echo "   - Go to EC2 → Instances"
echo "   - Find: i-016e9c49216f49b35"
echo "   - Terminate the instance"
echo ""

echo "4. 🔄 ROTATE AWS ACCESS KEYS:"
echo "   - Go to IAM → Users → Your User"
echo "   - Security credentials → Access keys"
echo "   - Deactivate old keys"
echo "   - Create new access keys"
echo ""

echo "5. 🗄️ UPDATE SECRETS MANAGER:"
echo "   - Go to AWS Secrets Manager"
echo "   - Update all secrets with new values"
echo ""

echo -e "${GREEN}✅ After completing these steps, run:${NC}"
echo "   ./scripts/verify-credentials.sh"
echo ""

echo -e "${RED}🚨 DO NOT PROCEED WITH DEPLOYMENT UNTIL ALL CREDENTIALS ARE ROTATED!${NC}"
