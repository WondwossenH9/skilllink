# Deploy SkillLink Backend Application to EC2
# This script deploys the actual application code and configures the environment

$AWS_CLI = "C:\Program Files\Amazon\AWSCLIV2\aws.exe"
$TIMESTAMP = "1757320302"
$PROJECT_NAME = "skilllink"

# Configuration
$INSTANCE_ID = "i-016e9c49216f49b35"
$EC2_PUBLIC_IP = "34.228.73.44"
$KEY_NAME = "$PROJECT_NAME-key-$TIMESTAMP"
$DB_ENDPOINT = "skilllink-db-1757320302.ccra4a804f4g.us-east-1.rds.amazonaws.com"
$DB_PASSWORD = "SkillLink2025!"

Write-Host "🚀 Deploying SkillLink Backend Application" -ForegroundColor Cyan
Write-Host "==========================================="

# Check if we have the key file
if (-not (Test-Path "$KEY_NAME.pem")) {
    Write-Host "❌ Key file $KEY_NAME.pem not found!" -ForegroundColor Red
    Write-Host "   Downloading key from AWS..." -ForegroundColor Yellow
    
    # Note: Key material can't be retrieved after creation, we need to use existing connection
    Write-Host "   Using EC2 Instance Connect or Session Manager instead..." -ForegroundColor Yellow
}

Write-Host "📋 Deployment Configuration:" -ForegroundColor Cyan
Write-Host "   EC2 Instance: $INSTANCE_ID"
Write-Host "   Public IP: $EC2_PUBLIC_IP"
Write-Host "   Database: $DB_ENDPOINT"
Write-Host ""

# Create deployment package
Write-Host "📦 Creating deployment package..." -ForegroundColor Yellow
if (Test-Path "deploy-temp") { Remove-Item "deploy-temp" -Recurse -Force }
New-Item -ItemType Directory -Path "deploy-temp" | Out-Null

# Copy backend files
Copy-Item "backend/*" "deploy-temp/" -Recurse -Force
Remove-Item "deploy-temp/node_modules" -Recurse -Force -ErrorAction SilentlyContinue

# Create production environment file
$envContent = @"
NODE_ENV=production
PORT=3001
DATABASE_URL=postgresql://skilllink:${DB_PASSWORD}@${DB_ENDPOINT}:5432/postgres
JWT_SECRET=skilllink-production-jwt-secret-$(Get-Random -Minimum 100000 -Maximum 999999)
JWT_EXPIRE=7d
FRONTEND_URL=http://skilllink-frontend-${TIMESTAMP}.s3-website-us-east-1.amazonaws.com
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=100
"@

$envContent | Out-File -FilePath "deploy-temp/.env" -Encoding utf8
Write-Host "   ✅ Environment configuration created" -ForegroundColor Green

# Create deployment script for EC2
$deployScript = @'
#!/bin/bash
set -e

echo "🚀 Starting SkillLink backend deployment..."

# Update system
sudo yum update -y
sudo yum install -y git nginx

# Install Node.js 18
if ! command -v node &> /dev/null; then
    echo "Installing Node.js..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    nvm install 18
    nvm use 18
    nvm alias default 18
fi

# Install PM2
if ! command -v pm2 &> /dev/null; then
    echo "Installing PM2..."
    npm install -g pm2
fi

# Create application directory
sudo mkdir -p /home/ec2-user/skilllink
sudo chown ec2-user:ec2-user /home/ec2-user/skilllink

# Move application files
cp -r /tmp/backend-deploy/* /home/ec2-user/skilllink/
cd /home/ec2-user/skilllink

# Install dependencies
echo "Installing Node.js dependencies..."
npm install --production

# Test database connection
echo "Testing database connection..."
node -e "
const { Sequelize } = require('sequelize');
const sequelize = new Sequelize(process.env.DATABASE_URL);
sequelize.authenticate()
  .then(() => console.log('✅ Database connection successful'))
  .catch(err => { console.error('❌ Database connection failed:', err.message); process.exit(1); });
"

# Sync database
echo "Synchronizing database..."
node -e "
const { sequelize } = require('./src/models');
sequelize.sync({ force: false })
  .then(() => console.log('✅ Database synchronized'))
  .catch(err => { console.error('❌ Database sync failed:', err.message); process.exit(1); });
"

# Configure Nginx
sudo tee /etc/nginx/conf.d/skilllink.conf > /dev/null <<EOF
server {
    listen 80;
    server_name _;

    # Security headers
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";

    location / {
        proxy_pass http://localhost:3001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
        
        # CORS headers
        add_header Access-Control-Allow-Origin "http://skilllink-frontend-1757320302.s3-website-us-east-1.amazonaws.com" always;
        add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS" always;
        add_header Access-Control-Allow-Headers "Content-Type, Authorization" always;
        add_header Access-Control-Allow-Credentials true always;
        
        if (\$request_method = 'OPTIONS') {
            return 204;
        }
    }
}
EOF

# Remove default nginx configuration
sudo rm -f /etc/nginx/conf.d/default.conf

# Test nginx configuration
sudo nginx -t

# Start and enable nginx
sudo systemctl start nginx
sudo systemctl enable nginx

# Start the application
echo "Starting SkillLink backend..."
pm2 start src/server.js --name skilllink-backend
pm2 startup
pm2 save

echo "✅ SkillLink backend deployment completed!"
echo "📊 Application status:"
pm2 status

echo "🌐 API should be available at: http://$(curl -s http://checkip.amazonaws.com)/api"
'@

$deployScript | Out-File -FilePath "deploy-temp/deploy.sh" -Encoding utf8
Write-Host "   ✅ Deployment script created" -ForegroundColor Green

Write-Host ""
Write-Host "📤 Ready to deploy to EC2!" -ForegroundColor Green
Write-Host ""
Write-Host "Manual deployment steps:" -ForegroundColor Yellow
Write-Host "1. Copy files to EC2 using AWS Session Manager or SCP" -ForegroundColor Gray
Write-Host "2. Connect to EC2 instance" -ForegroundColor Gray
Write-Host "3. Run the deployment script" -ForegroundColor Gray
Write-Host ""
Write-Host "🔗 Connect to EC2 using AWS Console:" -ForegroundColor Cyan
Write-Host "   - Go to EC2 Console" -ForegroundColor Gray
Write-Host "   - Select instance: $INSTANCE_ID" -ForegroundColor Gray
Write-Host "   - Click 'Connect' > 'Session Manager'" -ForegroundColor Gray
Write-Host ""
Write-Host "💡 Alternative: Use EC2 Instance Connect in AWS Console" -ForegroundColor Cyan