# 🚀 SkillLink Production Deployment Guide

## Overview
This guide provides step-by-step instructions for deploying SkillLink to AWS with enterprise-grade security, monitoring, and reliability.

## Prerequisites

### 1. AWS Account Setup
- AWS Account with appropriate permissions
- AWS CLI configured with credentials
- Terraform installed (version 1.6+)
- Docker installed for local testing

### 2. Required AWS Permissions
Your AWS user/role needs the following permissions:
- EC2 (instances, security groups, key pairs)
- RDS (databases, subnet groups)
- S3 (buckets, policies)
- IAM (roles, policies, instance profiles)
- Secrets Manager (secrets, policies)
- CloudWatch (logs, metrics, alarms)
- SNS (topics, subscriptions)
- Application Load Balancer
- Auto Scaling Groups
- VPC (networking components)

### 3. GitHub Secrets Configuration
Configure the following secrets in your GitHub repository:
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `REACT_APP_API_URL` (will be set automatically)

## Security Features Implemented

### ✅ Secrets Management
- All sensitive data stored in AWS Secrets Manager
- No hardcoded credentials in code
- Automatic credential rotation
- IAM roles for service access

### ✅ Network Security
- VPC with public/private subnets
- Security groups with least-privilege access
- Application Load Balancer with SSL termination
- No direct database access from internet

### ✅ Application Security
- Helmet.js for security headers
- Rate limiting on all endpoints
- Input validation and sanitization
- CORS properly configured
- JWT token validation
- Password strength requirements

### ✅ Monitoring & Alerting
- CloudWatch logs and metrics
- Custom dashboards
- Automated alerts for:
  - High CPU/Memory usage
  - Database performance
  - Load balancer errors
  - Response time issues
- Budget alerts for cost control

## Deployment Steps

### Step 1: Infrastructure Deployment

1. **Clone the repository:**
   ```bash
   git clone <your-repo-url>
   cd skilllink
   ```

2. **Configure Terraform variables:**
   ```bash
   cd infrastructure/terraform
   cp terraform.tfvars.example terraform.tfvars
   ```

3. **Edit terraform.tfvars:**
   ```hcl
   project_name = "skilllink"
   environment = "prod"
   aws_region = "us-east-1"
   domain_name = "your-domain.com"
   alert_email = "your-email@example.com"
   budget_limit = 100
   ```

4. **Deploy infrastructure:**
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

### Step 2: Application Deployment

1. **Push to main branch:**
   ```bash
   git add .
   git commit -m "Deploy to production"
   git push origin main
   ```

2. **Monitor deployment:**
   - Check GitHub Actions for deployment status
   - Monitor CloudWatch logs
   - Verify health checks pass

### Step 3: Post-Deployment Verification

1. **Health Check:**
   ```bash
   curl https://your-load-balancer-url/api/health
   ```

2. **Test API Endpoints:**
   ```bash
   # Test skills endpoint
   curl https://your-load-balancer-url/api/skills
   
   # Test registration
   curl -X POST https://your-load-balancer-url/api/auth/register \
     -H "Content-Type: application/json" \
     -d '{"name":"Test User","email":"test@example.com","password":"SecurePass123!"}'
   ```

3. **Check Monitoring:**
   - Access CloudWatch dashboard
   - Verify all alarms are in OK state
   - Check application logs

## Architecture Overview

```
Internet
    ↓
Application Load Balancer (ALB)
    ↓
Auto Scaling Group (ASG)
    ↓
EC2 Instances (Private Subnets)
    ↓
RDS PostgreSQL (Private Subnets)
    ↓
AWS Secrets Manager
```

## Security Best Practices

### 1. Regular Security Updates
- Keep all dependencies updated
- Monitor security advisories
- Apply security patches promptly

### 2. Access Control
- Use IAM roles, not access keys
- Implement least-privilege access
- Regular access reviews

### 3. Monitoring
- Monitor all security events
- Set up alerts for suspicious activity
- Regular security audits

### 4. Backup & Recovery
- Automated database backups
- Test recovery procedures
- Document recovery processes

## Troubleshooting

### Common Issues

1. **Deployment Fails:**
   - Check GitHub Actions logs
   - Verify AWS permissions
   - Check Terraform state

2. **Application Not Starting:**
   - Check CloudWatch logs
   - Verify secrets are accessible
   - Check security group rules

3. **Database Connection Issues:**
   - Verify RDS is running
   - Check security group rules
   - Verify secrets are correct

### Getting Help

1. **Check Logs:**
   ```bash
   aws logs describe-log-groups
   aws logs get-log-events --log-group-name /aws/ec2/skilllink-prod-application
   ```

2. **Monitor Resources:**
   - CloudWatch Dashboard
   - EC2 Instance Status
   - RDS Performance Insights

## Cost Optimization

### 1. Right-Sizing
- Monitor resource utilization
- Adjust instance types as needed
- Use Spot instances for non-critical workloads

### 2. Storage Optimization
- Enable S3 lifecycle policies
- Clean up old logs regularly
- Use appropriate storage classes

### 3. Monitoring Costs
- Set up budget alerts
- Regular cost reviews
- Use AWS Cost Explorer

## Maintenance

### 1. Regular Tasks
- Security updates
- Dependency updates
- Log rotation
- Backup verification

### 2. Monitoring
- Daily health checks
- Weekly security reviews
- Monthly cost analysis

### 3. Scaling
- Monitor performance metrics
- Scale based on demand
- Plan for traffic spikes

## Support

For issues or questions:
1. Check this documentation
2. Review CloudWatch logs
3. Check GitHub Issues
4. Contact the development team

---

**Remember:** This is a production system handling real data. Always test changes in a development environment first and follow proper change management procedures.
