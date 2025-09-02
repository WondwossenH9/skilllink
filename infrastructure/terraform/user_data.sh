#!/bin/bash

# SkillLink Backend Server Bootstrap Script
# This script runs when the EC2 instance first boots up

set -e

echo "🚀 Starting SkillLink backend server bootstrap..."

# Update system packages
echo "📦 Updating system packages..."
sudo apt-get update -y
sudo apt-get upgrade -y

# Install essential packages
echo "🔧 Installing essential packages..."
sudo apt-get install -y \
    build-essential \
    curl \
    git \
    unzip \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release

# Install Node.js 18.x
echo "📱 Installing Node.js 18.x..."
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# Verify Node.js installation
echo "✅ Node.js version: $(node --version)"
echo "✅ npm version: $(npm --version)"

# Install PM2 globally
echo "⚡ Installing PM2 process manager..."
sudo npm install -g pm2

# Create application directory
echo "📁 Creating application directory..."
sudo mkdir -p /var/www/skilllink
sudo chown ubuntu:ubuntu /var/www/skilllink

# Clone the repository
echo "📥 Cloning SkillLink repository..."
cd /var/www/skilllink
if [ ! -d ".git" ]; then
    git clone https://github.com/WondwossenH9/skilllink.git . || {
        echo "⚠️  Repository clone failed, creating directory structure..."
        mkdir -p backend
    }
fi

# Navigate to backend directory
cd backend

# Install dependencies
echo "📦 Installing Node.js dependencies..."
npm ci --production || npm install --production

# Create production environment file
echo "⚙️  Creating production environment file..."
cat > .env << EOF
NODE_ENV=production
PORT=3001
JWT_SECRET=$(openssl rand -base64 32)
JWT_EXPIRE=7d

# Database Configuration
DATABASE_URL=postgresql://${db_username}:${db_password}@${db_host}:5432/${db_name}
DB_SSL=true

# CORS Configuration
FRONTEND_URL=${frontend_url}

# Rate Limiting
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=100
EOF

# Set proper permissions
sudo chown -R ubuntu:ubuntu /var/www/skilllink

# Create PM2 ecosystem file
echo "⚙️  Creating PM2 ecosystem configuration..."
cat > ecosystem.config.js << EOF
module.exports = {
  apps: [{
    name: 'skilllink-api',
    script: 'src/server.js',
    instances: 1,
    autorestart: true,
    watch: false,
    max_memory_restart: '1G',
    env: {
      NODE_ENV: 'production',
      PORT: 3001
    },
    error_file: '/var/log/skilllink/err.log',
    out_file: '/var/log/skilllink/out.log',
    log_file: '/var/log/skilllink/combined.log',
    time: true
  }]
};
EOF

# Create log directory
sudo mkdir -p /var/log/skilllink
sudo chown ubuntu:ubuntu /var/log/skilllink

# Start the application with PM2
echo "🚀 Starting SkillLink API with PM2..."
pm2 start ecosystem.config.js

# Save PM2 configuration
pm2 save

# Setup PM2 to start on boot
pm2 startup ubuntu

# Create health check endpoint
echo "🏥 Creating health check endpoint..."
if [ ! -f "src/routes/health.js" ]; then
    mkdir -p src/routes
    cat > src/routes/health.js << 'HEALTH_EOF'
const express = require('express');
const router = express.Router();

router.get('/health', (req, res) => {
    res.status(200).json({
        status: 'OK',
        timestamp: new Date().toISOString(),
        uptime: process.uptime(),
        environment: process.env.NODE_ENV,
        version: process.version
    });
});

module.exports = router;
HEALTH_EOF
fi

# Install and configure Nginx
echo "🌐 Installing and configuring Nginx..."
sudo apt-get install -y nginx

# Create Nginx configuration
echo "⚙️  Creating Nginx configuration..."
sudo tee /etc/nginx/sites-available/skilllink << 'NGINX_EOF'
server {
    listen 80;
    server_name _;

    # Health check endpoint
    location /health {
        proxy_pass http://localhost:3001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }

    # API endpoints
    location /api {
        proxy_pass http://localhost:3001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }

    # Default location
    location / {
        return 404;
    }
}
NGINX_EOF

# Enable the site
sudo ln -sf /etc/nginx/sites-available/skilllink /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default

# Test Nginx configuration
sudo nginx -t

# Restart Nginx
sudo systemctl restart nginx
sudo systemctl enable nginx

# Create a simple status page
echo "📊 Creating status page..."
sudo tee /var/www/html/status.html << 'STATUS_EOF'
<!DOCTYPE html>
<html>
<head>
    <title>SkillLink Backend Status</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        .status { padding: 20px; border-radius: 5px; margin: 10px 0; }
        .ok { background-color: #d4edda; color: #155724; border: 1px solid #c3e6cb; }
        .error { background-color: #f8d7da; color: #721c24; border: 1px solid #f5c6cb; }
        .info { background-color: #d1ecf1; color: #0c5460; border: 1px solid #bee5eb; }
    </style>
</head>
<body>
    <h1>SkillLink Backend Server Status</h1>
    <div class="status info">
        <h3>Server Information</h3>
        <p><strong>Instance ID:</strong> <span id="instance-id">Loading...</span></p>
        <p><strong>Region:</strong> <span id="region">Loading...</span></p>
        <p><strong>Uptime:</strong> <span id="uptime">Loading...</span></p>
    </div>
    <div class="status info">
        <h3>Application Status</h3>
        <p><strong>API Health:</strong> <span id="api-health">Checking...</span></p>
        <p><strong>Database:</strong> <span id="db-status">Checking...</span></p>
    </div>
    <div class="status info">
        <h3>Quick Links</h3>
        <p><a href="/health" target="_blank">Health Check Endpoint</a></p>
        <p><a href="/api" target="_blank">API Root</a></p>
    </div>
    <script>
        // Fetch instance metadata
        fetch('http://169.254.169.254/latest/meta-data/instance-id')
            .then(response => response.text())
            .then(data => document.getElementById('instance-id').textContent = data)
            .catch(() => document.getElementById('instance-id').textContent = 'Not available');
        
        fetch('http://169.254.169.254/latest/meta-data/placement/region')
            .then(response => response.text())
            .then(data => document.getElementById('region').textContent = data)
            .catch(() => document.getElementById('region').textContent = 'Not available');
        
        // Check API health
        fetch('/health')
            .then(response => response.json())
            .then(data => {
                document.getElementById('api-health').textContent = 'Healthy';
                document.getElementById('uptime').textContent = Math.floor(data.uptime / 3600) + ' hours';
            })
            .catch(() => document.getElementById('api-health').textContent = 'Unhealthy');
    </script>
</body>
</html>
STATUS_EOF

# Set up log rotation
echo "📝 Setting up log rotation..."
sudo tee /etc/logrotate.d/skilllink << 'LOGROTATE_EOF'
/var/log/skilllink/*.log {
    daily
    missingok
    rotate 7
    compress
    delaycompress
    notifempty
    create 644 ubuntu ubuntu
    postrotate
        pm2 reloadLogs
    endscript
}
LOGROTATE_EOF

# Create a simple monitoring script
echo "📊 Creating monitoring script..."
cat > /home/ubuntu/monitor.sh << 'MONITOR_EOF'
#!/bin/bash
echo "=== SkillLink Backend Status ==="
echo "Date: $(date)"
echo "Uptime: $(uptime)"
echo "Memory: $(free -h | grep Mem | awk '{print $3"/"$2}')"
echo "Disk: $(df -h / | tail -1 | awk '{print $5}') used"
echo "PM2 Status:"
pm2 status
echo "Nginx Status:"
sudo systemctl status nginx --no-pager -l
echo "========================"
MONITOR_EOF

chmod +x /home/ubuntu/monitor.sh

# Final status
echo "✅ SkillLink backend server bootstrap completed!"
echo "🌐 Server is running on port 3001"
echo "🔗 Health check: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)/health"
echo "📊 Status page: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)/status.html"
echo "📝 Logs: /var/log/skilllink/"
echo "⚡ PM2: pm2 status"
echo "🔧 Monitor: ./monitor.sh"

# Wait a moment for services to start
sleep 5

# Verify everything is running
echo "🔍 Verifying services..."
pm2 status
sudo systemctl status nginx --no-pager -l

echo "🎉 Bootstrap script completed successfully!"
