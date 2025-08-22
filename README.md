
# SkillLink

SkillLink is a full-stack web application for skill swapping—a mini marketplace where users can offer and request skills. The project demonstrates cloud automation, DevOps practices, and modern full-stack deployment.


## Architecture

- **Frontend:** React application (deployed on S3 + CloudFront with HTTPS/SSL)
- **Backend:** Node.js/Express API (deployed on EC2)
- **Database:** PostgreSQL (AWS RDS)
- **Infrastructure as Code:** `deploy.sh` automates AWS Free Tier deployment


## Features

- User registration and authentication
- Post skill offers (e.g., "I can teach Excel basics")
- Post skill requests (e.g., "I want to learn Git")
- Browse and search available skills
- Match skill offers with requests
- User profiles and skill ratings


## AWS Deployment Features

The `deploy.sh` script provides enhanced AWS deployment:

- **Dev/Prod environment switch:**
  - Dev: EC2 `t2.micro`, RDS `db.t3.micro` (AWS Free Tier)
  - Prod: EC2 `t3.small`, RDS `db.t3.small`
- **Automatic tagging** for all resources (Project, Owner, Environment)
- **S3 + CloudFront** with HTTPS/SSL for frontend hosting
- **Automatic environment variable generation:**
  - `.env.deployment` file contains frontend/backend URLs, EC2 IP, and RDS credentials
- **Cleanup function** to safely delete all AWS resources created by the script


## Getting Started

### 1. Install Prerequisites
- AWS CLI configured with credentials
- Node.js and npm installed
- OpenSSL installed (for generating passwords)

### 2. Run Deployment
Deploy the infrastructure to dev or prod:

```bash
# Deploy dev environment (Free Tier)
./deploy.sh deploy dev

# Deploy prod environment (larger instances)
./deploy.sh deploy prod
```

### 3. Check Environment Variables
After deployment, `.env.deployment` is automatically generated. This file contains all necessary configuration for your frontend and backend:

```bash
cat .env.deployment
```

Example entries:
```env
PROJECT_NAME=skilllink
ENVIRONMENT=dev
OWNER=Wondwossen
AWS_REGION=us-east-1

# Frontend
S3_BUCKET=skilllink-frontend-dev-1692304521
CLOUDFRONT_DOMAIN=d123example.cloudfront.net

# Backend
EC2_INSTANCE_ID=i-0abcd1234efgh5678
EC2_PUBLIC_IP=3.14.22.144

# RDS
DB_INSTANCE_ID=skilllink-rds-dev
DB_NAME=skilllink
DB_USERNAME=skilllink_user
DB_PASSWORD=<randomly-generated>
```
Use these values to configure your frontend and backend applications immediately after deployment.

### 4. Cleanup Resources
Safely delete all AWS resources created for a given environment:

```bash
# Cleanup dev environment
./deploy.sh cleanup dev

# Cleanup prod environment
./deploy.sh cleanup prod
```

## Notes
This project demonstrates:
- Automated AWS infrastructure provisioning
- Multi-environment management (dev/prod)
- Best practices with tagging, SSL, and environment variables
- Clean resource lifecycle management with a safe cleanup function
- Cloud automation, DevOps practices, and full-stack application deployment skills

See the setup instructions in each component's directory:
- [Frontend Setup](./frontend/README.md)
- [Backend Setup](./backend/README.md)
- [Deployment Guide](./docs/deployment.md)
