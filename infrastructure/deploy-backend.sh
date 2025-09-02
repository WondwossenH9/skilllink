#!/bin/bash
set -e

# Load deployment configuration
if [[ ! -f infrastructure/deployment-config.env ]]; then
  echo "❌ Deployment configuration not found. Run deploy-wsl.sh first."
  exit 1
fi

source infrastructure/deployment-config.env

echo "🚀 Deploying backend to EC2..."

# Check if key file exists
if [[ ! -f "infrastructure/$EC2_KEY_NAME.pem" ]]; then
  echo "❌ Key file infrastructure/$EC2_KEY_NAME.pem not found"
  exit 1
fi

# Create deployment package
echo "📦 Creating deployment package..."
rm -rf deploy-package
mkdir -p deploy-package
cp -r backend/* deploy-package/
rm -rf deploy-package/node_modules
rm -f deploy-package/*.db

# Create production environment file
export DATABASE_URL="postgres://${DB_USERNAME}:${DB_PASSWORD}@${DB_ENDPOINT}:5432/${DB_NAME}"
cat > deploy-package/.env <<EOF
NODE_ENV=production
PORT=3001
DATABASE_URL=${DATABASE_URL}
JWT_SECRET=skilllink-production-jwt-secret-$(openssl rand -hex 32)
JWT_EXPIRE=7d
FRONTEND_URL=https://${FRONTEND_DOMAIN}
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=100
EOF

# Create deployment script
cat > deploy-package/deploy.sh <<'EOF'
#!/bin/bash
set -e

echo "🚀 Deploying SkillLink backend..."

# Install Node.js if not installed
if ! command -v node &> /dev/null; then
    echo "📦 Installing Node.js..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    nvm install 18
    nvm use 18
fi

# Install PM2 if not installed
if ! command -v pm2 &> /dev/null; then
    echo "📦 Installing PM2..."
    npm install -g pm2
fi

# Install dependencies
echo "📦 Installing dependencies..."
npm ci --production

# Create database tables
echo "🗄️ Setting up database..."
node -e "
const sequelize = require('./config/database');
const { User, Skill, Match } = require('./src/models');

async function setupDatabase() {
  try {
    await sequelize.authenticate();
    console.log('Database connection established.');
    
    await sequelize.sync({ force: false });
    console.log('Database synchronized.');
    
    process.exit(0);
  } catch (error) {
    console.error('Database setup failed:', error);
    process.exit(1);
  }
}

setupDatabase();
"

# Start application with PM2
echo "🚀 Starting application..."
pm2 delete skilllink-backend 2>/dev/null || true
pm2 start src/server.js --name skilllink-backend
pm2 startup
pm2 save

echo "✅ Backend deployed successfully!"
echo "🌐 Application running on port 3001"
echo "📊 Check status: pm2 status"
echo "📋 View logs: pm2 logs skilllink-backend"
EOF

chmod +x deploy-package/deploy.sh

# Copy files to EC2
echo "📤 Copying files to EC2..."
scp -i "infrastructure/$EC2_KEY_NAME.pem" -r deploy-package/* ec2-user@$EC2_PUBLIC_IP:~/

# Deploy on EC2
echo "🔧 Deploying on EC2..."
ssh -i "infrastructure/$EC2_KEY_NAME.pem" ec2-user@$EC2_PUBLIC_IP << 'EOF'
cd ~
chmod +x deploy.sh
./deploy.sh
EOF

echo "✅ Backend deployment completed!"
echo ""
echo "🌐 Your SkillLink application is now live!"
echo "Frontend: http://$S3_BUCKET.s3-website-$AWS_REGION.amazonaws.com"
echo "Backend API: http://$EC2_PUBLIC_IP:3001"
echo ""
echo "🔧 Management commands:"
echo "SSH to EC2: ssh -i infrastructure/$EC2_KEY_NAME.pem ec2-user@$EC2_PUBLIC_IP"
echo "Check app status: ssh -i infrastructure/$EC2_KEY_NAME.pem ec2-user@$EC2_PUBLIC_IP 'pm2 status'"
echo "View logs: ssh -i infrastructure/$EC2_KEY_NAME.pem ec2-user@$EC2_PUBLIC_IP 'pm2 logs skilllink-backend'"
echo "Restart app: ssh -i infrastructure/$EC2_KEY_NAME.pem ec2-user@$EC2_PUBLIC_IP 'pm2 restart skilllink-backend'"
