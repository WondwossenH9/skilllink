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

# Install and configure Nginx
echo "📦 Installing and configuring Nginx..."
sudo yum update -y
sudo yum install -y nginx

# Copy Nginx configuration
sudo cp nginx.conf /etc/nginx/conf.d/skilllink.conf
sudo systemctl enable nginx
sudo systemctl start nginx

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
