#!/bin/bash
set -e

# Load deployment configuration
if [[ ! -f infrastructure/deployment-config.env ]]; then
  echo "❌ Deployment configuration not found. Run deploy-wsl.sh first."
  exit 1
fi

source infrastructure/deployment-config.env

echo "🚀 Deploying backend to EC2 using AWS Systems Manager..."

# Check if SSM agent is available on the instance
echo "🔍 Checking SSM agent status..."
if ! aws ssm describe-instance-information --filters "Key=InstanceIds,Values=$EC2_INSTANCE_ID" --query 'InstanceInformationList[0].PingStatus' --output text | grep -q "Online"; then
  echo "❌ SSM agent not available on instance. Installing SSM agent..."
  
  # Install SSM agent using user data (if instance is running)
  aws ssm send-command \
    --instance-ids "$EC2_INSTANCE_ID" \
    --document-name "AWS-ConfigureAWSPackage" \
    --parameters '{"action":["Install"],"name":["AmazonSSMAgent"]}' \
    --region "$AWS_REGION"
  
  echo "⏳ Waiting for SSM agent to be ready..."
  sleep 30
fi

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

# Create deployment script for EC2
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

# Upload files to S3 for EC2 to download
echo "📤 Uploading deployment package to S3..."
S3_DEPLOY_BUCKET="${S3_BUCKET}-deploy"
aws s3 mb "s3://$S3_DEPLOY_BUCKET" --region "$AWS_REGION" 2>/dev/null || true
aws s3 sync deploy-package "s3://$S3_DEPLOY_BUCKET" --delete

# Create SSM document for deployment
echo "📝 Creating SSM deployment document..."
aws ssm create-document \
  --name "SkillLinkDeploy" \
  --content '{
    "schemaVersion": "2.2",
    "description": "Deploy SkillLink backend",
    "parameters": {
      "S3Bucket": {
        "type": "String",
        "description": "S3 bucket containing deployment files"
      }
    },
    "mainSteps": [
      {
        "action": "aws:runShellScript",
        "name": "downloadAndDeploy",
        "inputs": {
          "runCommand": [
            "cd /home/ec2-user",
            "aws s3 sync s3://{{ S3Bucket }} .",
            "chmod +x deploy.sh",
            "./deploy.sh"
          ]
        }
      }
    ]
  }' \
  --document-type "Command" \
  --region "$AWS_REGION" 2>/dev/null || true

# Execute deployment via SSM
echo "🔧 Executing deployment via SSM..."
aws ssm send-command \
  --instance-ids "$EC2_INSTANCE_ID" \
  --document-name "SkillLinkDeploy" \
  --parameters "S3Bucket=$S3_DEPLOY_BUCKET" \
  --region "$AWS_REGION"

echo "⏳ Waiting for deployment to complete..."
sleep 60

# Check deployment status
echo "🔍 Checking deployment status..."
aws ssm send-command \
  --instance-ids "$EC2_INSTANCE_ID" \
  --document-name "AWS-RunShellScript" \
  --parameters 'commands=["pm2 status", "curl -s http://localhost:3001/api/health || echo \"Health check failed\""]' \
  --region "$AWS_REGION"

echo "✅ Backend deployment completed!"
echo ""
echo "🌐 Your SkillLink application is now live!"
echo "Frontend: $S3_WEBSITE_URL"
echo "Backend API: http://$EC2_PUBLIC_IP:3001"
echo ""
echo "🔧 Management commands:"
echo "Check app status: aws ssm send-command --instance-ids $EC2_INSTANCE_ID --document-name AWS-RunShellScript --parameters 'commands=[\"pm2 status\"]' --region $AWS_REGION"
echo "View logs: aws ssm send-command --instance-ids $EC2_INSTANCE_ID --document-name AWS-RunShellScript --parameters 'commands=[\"pm2 logs skilllink-backend\"]' --region $AWS_REGION"
echo "Restart app: aws ssm send-command --instance-ids $EC2_INSTANCE_ID --document-name AWS-RunShellScript --parameters 'commands=[\"pm2 restart skilllink-backend\"]' --region $AWS_REGION"
