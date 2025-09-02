# SkillLink AWS Deployment Guide

This guide will walk you through deploying SkillLink to AWS using Infrastructure as Code (Terraform) and automated CI/CD pipelines.

## 🏗️ Architecture Overview

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Frontend      │    │   Backend       │    │   Database      │
│   (React)       │    │   (Node.js)     │    │   (PostgreSQL)  │
│                 │    │                 │    │                 │
│ S3 + CloudFront │◄──►│   EC2 + ALB     │◄──►│   RDS          │
│   + ACM         │    │   + Nginx       │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 📋 Prerequisites

Before starting the deployment, ensure you have:

- [ ] AWS CLI installed and configured with appropriate permissions
- [ ] Terraform installed (version >= 1.2.0)
- [ ] Node.js 18+ and npm installed
- [ ] A domain name (for SSL certificate)
- [ ] SSH key pair for EC2 access
- [ ] GitHub repository with your code

### Required AWS Permissions

Your AWS user/role needs the following permissions:
- EC2 (create, manage instances)
- RDS (create, manage databases)
- S3 (create, manage buckets)
- CloudFront (create distributions)
- ACM (create certificates)
- IAM (create roles and policies)
- VPC (create networking resources)
- SSM Parameter Store (store secrets)

## 🚀 Quick Start Deployment

### 1. Clone and Setup

```bash
git clone https://github.com/WondwossenH9/skilllink.git
cd skilllink
```

### 2. Configure Deployment

```bash
cd infrastructure
cp .env.deployment.example .env.deployment
# Edit .env.deployment with your values
```

Update the following variables in `.env.deployment`:
- `DOMAIN_NAME`: Your actual domain (e.g., `skilllink.yourdomain.com`)
- `DB_PASSWORD`: A secure database password
- `ALLOWED_SSH_CIDR`: Your IP address for SSH access (e.g., `203.0.113.5/32`)
- `KEY_PAIR_NAME`: Your EC2 key pair name

### 3. Run Full Deployment

```bash
chmod +x deploy.sh
./deploy.sh
```

This script will:
- Create all AWS infrastructure using Terraform
- Build and deploy the frontend to S3/CloudFront
- Deploy the backend to EC2
- Configure Nginx reverse proxy
- Set up monitoring and logging

## 🔧 Manual Deployment Steps

If you prefer to deploy step by step:

### Step 1: Deploy Infrastructure

```bash
cd infrastructure/terraform

# Initialize Terraform
terraform init

# Plan the deployment
terraform plan -var="domain_name=yourdomain.com" -var="db_password=yourpassword"

# Apply the deployment
terraform apply -var="domain_name=yourdomain.com" -var="db_password=yourpassword"
```

### Step 2: Deploy Frontend

```bash
cd ../../frontend
npm ci
npm run build

# Deploy to S3
aws s3 sync build/ s3://your-bucket-name --delete

# Invalidate CloudFront cache
aws cloudfront create-invalidation --distribution-id YOUR_DISTRIBUTION_ID --paths "/*"
```

### Step 3: Deploy Backend

```bash
cd ../infrastructure
./backend-deploy.sh
```

## 🌐 Domain Configuration

### DNS Setup

After deployment, update your DNS records:

1. **Frontend**: Point your domain to the CloudFront distribution
   - Type: `CNAME`
   - Name: `@` or your subdomain
   - Value: CloudFront domain (from Terraform output)

2. **Backend API**: Point your API subdomain to the ALB
   - Type: `CNAME`
   - Name: `api` or your preferred subdomain
   - Value: ALB DNS name (from Terraform output)

### SSL Certificate

The ACM certificate will be created automatically. DNS validation records will be created in Route 53 if you're using it, or you'll need to add them manually to your DNS provider.

## 🔐 Security Configuration

### SSH Access

- SSH access is restricted to your IP address (configured in `ALLOWED_SSH_CIDR`)
- Use your EC2 key pair for authentication
- Default user: `ubuntu`

### Database Security

- RDS is in a private subnet
- Only accessible from the EC2 instance
- SSL encryption enabled
- Credentials stored in SSM Parameter Store

### Network Security

- VPC with public and private subnets
- Security groups restrict access appropriately
- ALB handles HTTPS termination
- No direct access to EC2 on port 3001

## 📊 Monitoring and Logs

### Application Logs

```bash
# SSH to your EC2 instance
ssh -i your-key.pem ubuntu@your-ec2-ip

# Check PM2 logs
pm2 logs skilllink-api

# Check Nginx logs
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log

# Check system logs
sudo journalctl -u nginx -f
```

### CloudWatch Integration

- EC2 metrics automatically collected
- RDS metrics available in CloudWatch
- Application logs can be sent to CloudWatch Logs

### Health Checks

- Backend health endpoint: `http://your-ec2-ip/health`
- ALB health checks: `http://your-alb-dns/health`
- Status page: `http://your-ec2-ip/status.html`

## 🔄 CI/CD Pipeline

### GitHub Actions Setup

1. **Add Repository Secrets**:
   - `AWS_ACCESS_KEY_ID`: Your AWS access key
   - `AWS_SECRET_ACCESS_KEY`: Your AWS secret key
   - `DOMAIN_NAME`: Your domain name
   - `DB_PASSWORD`: Database password
   - `ALLOWED_SSH_CIDR`: Your IP CIDR
   - `KEY_PAIR_NAME`: Your EC2 key pair name
   - `EC2_SSH_KEY`: Your EC2 private key content

2. **Enable GitHub Actions**:
   - Push to `main` branch triggers automatic deployment
   - Manual deployment available via GitHub Actions UI

### Pipeline Stages

1. **Test**: Run tests on both frontend and backend
2. **Infrastructure**: Deploy AWS resources with Terraform
3. **Frontend**: Build and deploy to S3/CloudFront
4. **Backend**: Deploy to EC2 instance
5. **Health Check**: Verify all services are running

## 🛠️ Troubleshooting

### Common Issues

#### Frontend Not Loading
- Check S3 bucket permissions
- Verify CloudFront distribution is enabled
- Check DNS configuration
- Verify ACM certificate validation

#### Backend Not Responding
- Check EC2 instance status
- Verify security group rules
- Check PM2 process status
- Review application logs

#### Database Connection Issues
- Verify RDS instance is available
- Check security group rules
- Verify environment variables
- Check SSL configuration

#### SSL Certificate Issues
- Ensure certificate is in `us-east-1` region
- Verify DNS validation records
- Check certificate status in ACM console

### Debug Commands

```bash
# Check EC2 instance status
aws ec2 describe-instances --filters "Name=tag:Name,Values=skilllink-backend"

# Check RDS status
aws rds describe-db-instances --db-instance-identifier skilllink-db

# Check ALB health
aws elbv2 describe-target-health --target-group-arn your-target-group-arn

# Check CloudFront distribution
aws cloudfront get-distribution --id your-distribution-id
```

## 💰 Cost Optimization

### Free Tier Usage

- EC2: `t3.micro` (750 hours/month free)
- RDS: `db.t3.micro` (750 hours/month free)
- S3: 5GB storage free
- CloudFront: 1TB data transfer free

### Cost Monitoring

- Set up AWS Cost Explorer
- Configure billing alerts
- Monitor resource usage
- Use AWS Budgets for cost control

## 🔄 Updates and Maintenance

### Application Updates

```bash
# Frontend updates
cd frontend
npm run build
aws s3 sync build/ s3://your-bucket --delete

# Backend updates
cd infrastructure
./backend-deploy.sh
```

### Infrastructure Updates

```bash
cd infrastructure/terraform
terraform plan
terraform apply
```

### Database Maintenance

- Automated backups enabled (7 days retention)
- Maintenance window: Sunday 4:00-5:00 AM UTC
- Monitor storage usage and performance

## 📚 Additional Resources

- [AWS Documentation](https://docs.aws.amazon.com/)
- [Terraform Documentation](https://www.terraform.io/docs)
- [Node.js Best Practices](https://nodejs.org/en/docs/guides/)
- [React Deployment Guide](https://create-react-app.dev/docs/deployment/)

## 🆘 Support

If you encounter issues:

1. Check the troubleshooting section above
2. Review AWS CloudTrail for API errors
3. Check GitHub Actions logs
4. Review application and system logs
5. Verify all prerequisites are met

## 📝 License

This deployment guide is part of the SkillLink project. Please refer to the main project license for usage terms.


