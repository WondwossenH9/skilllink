#!/bin/bash
set -e

# Load deployment configuration
if [[ ! -f infrastructure/deployment-config.env ]]; then
  echo "❌ Deployment configuration not found. Run deploy-wsl.sh first."
  exit 1
fi

source infrastructure/deployment-config.env

echo "🚀 Deploying backend to EC2 using direct AWS CLI..."

# Create deployment package
echo "📦 Creating deployment package..."
rm -rf deploy-package
mkdir -p deploy-package
cp -r backend/* deploy-package/
rm -rf deploy-package/node_modules
rm -f deploy-package/*.db

# Create production environment file
cat > deploy-package/.env <<EOF
NODE_ENV=production
PORT=3001
DATABASE_URL=$DATABASE_URL
JWT_SECRET=skilllink-production-jwt-secret-$(openssl rand -hex 32)
JWT_EXPIRE=7d
FRONTEND_URL=$S3_WEBSITE_URL
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=100
EOF

# Upload to S3
echo "📤 Uploading to S3..."
S3_DEPLOY_BUCKET="${S3_BUCKET}-deploy"
aws s3 mb "s3://$S3_DEPLOY_BUCKET" --region "$AWS_REGION" 2>/dev/null || true
aws s3 sync deploy-package "s3://$S3_DEPLOY_BUCKET" --delete

echo "✅ Deployment package uploaded to S3"
echo ""
echo "🔧 Manual deployment steps required:"
echo ""
echo "1. Connect to EC2 instance via AWS Console:"
echo "   - Go to EC2 Console"
echo "   - Select instance: $EC2_INSTANCE_ID"
echo "   - Click 'Connect' -> 'EC2 Instance Connect'"
echo ""
echo "2. Run these commands on the EC2 instance:"
echo "   cd /home/ec2-user"
echo "   aws s3 sync s3://$S3_DEPLOY_BUCKET ."
echo "   curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash"
echo "   export NVM_DIR=\"\$HOME/.nvm\""
echo "   [ -s \"\$NVM_DIR/nvm.sh\" ] && \. \"\$NVM_DIR/nvm.sh\""
echo "   nvm install 18"
echo "   nvm use 18"
echo "   npm install -g pm2"
echo "   npm ci --production"
echo "   node -e \"const sequelize = require('./config/database'); sequelize.sync({force: false}).then(() => process.exit(0)).catch(e => {console.error(e); process.exit(1)});\""
echo "   pm2 start src/server.js --name skilllink-backend"
echo "   pm2 startup"
echo "   pm2 save"
echo ""
echo "3. Test the application:"
echo "   curl http://localhost:3001/api/health"
echo ""
echo "🌐 Your application URLs:"
echo "Frontend: $S3_WEBSITE_URL"
echo "Backend: http://$EC2_PUBLIC_IP:3001"
