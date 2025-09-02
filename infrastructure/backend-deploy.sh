#!/bin/bash

# Backend deployment script for EC2

set -e

echo "🖥️ Deploying SkillLink Backend to EC2"
echo "===================================="

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Check if .env.deployment exists
if [ ! -f .env.deployment ]; then
    echo -e "${RED}❌ .env.deployment file not found. Run ./deploy.sh first.${NC}"
    exit 1
fi

# Source deployment environment
source .env.deployment

# Check required variables
if [ -z "$PUBLIC_IP" ] || [ -z "$KEY_NAME" ]; then
    echo -e "${RED}❌ Required deployment variables not found${NC}"
    exit 1
fi

echo "📤 Deploying to EC2 instance: $PUBLIC_IP"

# Create deployment package
echo "📦 Creating deployment package..."
cd ../backend
tar -czf ../infrastructure/backend.tar.gz --exclude=node_modules --exclude=.env --exclude=*.db .
cd ../infrastructure

# Create server setup script
cat > server-setup.sh << 'SETUP_EOF'
#!/bin/bash

# Update system
sudo apt-get update -y

# Install Node.js 18
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# Install PM2 for process management
sudo npm install -g pm2

# Create application directory
sudo mkdir -p /var/www/skilllink
sudo chown ubuntu:ubuntu /var/www/skilllink

# Extract and setup application
cd /var/www/skilllink
tar -xzf /tmp/backend.tar.gz

# Install dependencies
npm install --production

# Create environment file with DATABASE_URL
cat > .env << ENV_EOF
NODE_ENV=production
PORT=3001
JWT_SECRET=$(openssl rand -base64 32)
JWT_EXPIRE=7d

# Database Configuration - Use DATABASE_URL for production
DATABASE_URL=postgresql://${DB_USERNAME}:${DB_PASSWORD}@${DB_ENDPOINT}:5432/${DB_NAME}
DB_SSL=true

# CORS Configuration
FRONTEND_URL=https://${FRONTEND_DOMAIN}

# Rate Limiting
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=100
ENV_EOF

# Start application with PM2
pm2 start src/server.js --name skilllink-api
pm2 save
pm2 startup

echo "✅ Backend setup completed!"
SETUP_EOF

# Wait for RDS to be available
echo -e "${YELLOW}⏳ Checking RDS instance status...${NC}"
RDS_STATUS=$(aws rds describe-db-instances --db-instance-identifier $DB_INSTANCE_ID --query 'DBInstances[0].DBInstanceStatus' --output text)

if [ "$RDS_STATUS" != "available" ]; then
    echo -e "${YELLOW}⏳ RDS instance is not ready yet. Status: $RDS_STATUS${NC}"
    echo "Please wait for RDS instance to be available and run this script again."
    exit 1
fi

# Get RDS endpoint
DB_ENDPOINT=$(aws rds describe-db-instances --db-instance-identifier $DB_INSTANCE_ID --query 'DBInstances[0].Endpoint.Address' --output text)

# Update setup script with RDS details
sed -i "s/\${DB_ENDPOINT}/$DB_ENDPOINT/g" server-setup.sh
sed -i "s/\${DB_NAME}/$DB_NAME/g" server-setup.sh
sed -i "s/\${DB_USERNAME}/$DB_USERNAME/g" server-setup.sh
sed -i "s/\${DB_PASSWORD}/$DB_PASSWORD/g" server-setup.sh
sed -i "s/\${FRONTEND_DOMAIN}/$FRONTEND_DOMAIN/g" server-setup.sh

# Deploy to EC2
echo "🚀 Deploying to EC2..."

# Copy files to server
scp -i $KEY_NAME.pem -o StrictHostKeyChecking=no backend.tar.gz ubuntu@$PUBLIC_IP:/tmp/
scp -i $KEY_NAME.pem -o StrictHostKeyChecking=no server-setup.sh ubuntu@$PUBLIC_IP:/tmp/

# Run setup script on server
ssh -i $KEY_NAME.pem -o StrictHostKeyChecking=no ubuntu@$PUBLIC_IP 'chmod +x /tmp/server-setup.sh && /tmp/server-setup.sh'

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Backend deployed successfully${NC}"
    echo ""
    echo "🌐 Your API is available at:"
    echo "http://$PUBLIC_IP:3001/api"
    echo ""
    echo "📊 Health check:"
    echo "http://$PUBLIC_IP:3001/api/health"
    echo ""
    echo "🔗 To connect to your server:"
    echo "ssh -i $KEY_NAME.pem ubuntu@$PUBLIC_IP"
    echo ""
else
    echo -e "${RED}❌ Backend deployment failed${NC}"
    exit 1
fi

# Cleanup
rm -f backend.tar.gz server-setup.sh
