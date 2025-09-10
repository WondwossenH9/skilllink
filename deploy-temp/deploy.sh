#!/bin/bash
set -e

echo "ðŸš€ Starting SkillLink backend deployment..."

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
  .then(() => console.log('âœ… Database connection successful'))
  .catch(err => { console.error('âŒ Database connection failed:', err.message); process.exit(1); });
"

# Sync database
echo "Synchronizing database..."
node -e "
const { sequelize } = require('./src/models');
sequelize.sync({ force: false })
  .then(() => console.log('âœ… Database synchronized'))
  .catch(err => { console.error('âŒ Database sync failed:', err.message); process.exit(1); });
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

echo "âœ… SkillLink backend deployment completed!"
echo "ðŸ“Š Application status:"
pm2 status

echo "ðŸŒ API should be available at: http://$(curl -s http://checkip.amazonaws.com)/api"
