#!/bin/bash
set -e

echo "🚀 Deploying SkillLink backend with modern Node.js..."

# Install Node.js 20 LTS using NodeSource
echo "📦 Installing Node.js 20 LTS..."
curl -fsSL https://rpm.nodesource.com/setup_20.x | sudo bash -
sudo yum install -y nodejs

# Verify Node.js installation
echo "Node.js version: $(node --version)"
echo "npm version: $(npm --version)"

# Install PM2 globally
echo "📦 Installing PM2..."
sudo npm install -g pm2

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
