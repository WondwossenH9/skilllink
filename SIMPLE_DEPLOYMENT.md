# SkillLink - Simplified AWS Deployment

A skill-swapping marketplace deployed on AWS Free Tier with **near-zero cost**.

## 🎯 Simple Architecture

- **Frontend**: React app on S3 Static Website (Free: 5GB storage)
- **Backend**: Node.js on EC2 t2.micro (Free: 750 hours/month)
- **Database**: PostgreSQL on RDS db.t3.micro (Free: 750 hours/month)
- **Total Cost**: $0-5/month (within free tier limits)

## 🚀 One-Command Deployment

```bash
# Make script executable
chmod +x deploy-aws-simple.sh

# Deploy everything
./deploy-aws-simple.sh

# Access your app at the provided URLs
```

## 📋 Prerequisites

1. **AWS CLI configured**:
   ```bash
   aws configure
   # Enter your Access Key, Secret Key, Region (us-east-1), Output format (json)
   ```

2. **Node.js 18+**:
   ```bash
   node --version  # Should be 18+
   ```

3. **Git** (for cloning if needed)

## 🎯 What The Script Does

1. **Builds** frontend and backend
2. **Creates S3 bucket** and uploads React app
3. **Launches EC2 instance** (t2.micro) with auto-setup
4. **Creates RDS PostgreSQL** (db.t3.micro)
5. **Configures security groups** and networking
6. **Deploys backend** with PM2 and Nginx
7. **Links everything together** with proper URLs

## 📊 Free Tier Usage

| Service | Free Tier Limit | Monthly Cost |
|---------|----------------|--------------|
| EC2 t2.micro | 750 hours | $0 |
| RDS db.t3.micro | 750 hours | $0 |
| S3 Storage | 5 GB | $0 |
| Data Transfer | 15 GB outbound | $0 |
| **Total** | | **$0-5** |

## 🔧 Local Development

```bash
# Backend (Terminal 1)
cd backend
npm install
npm run dev

# Frontend (Terminal 2)
cd frontend
npm install
npm start

# Visit: http://localhost:3000
```

## 🧹 Cleanup Resources

When you're done testing:

```bash
chmod +x cleanup-aws.sh
./cleanup-aws.sh <timestamp>
```

The script will show you the timestamp when deployment completes.

## 🎉 Features

- ✅ User registration and authentication
- ✅ Skill offers and requests
- ✅ Skill matching system
- ✅ User profiles and ratings
- ✅ Responsive design
- ✅ Production-ready deployment

## 🔍 Troubleshooting

**Deployment fails?**
1. Check AWS credentials: `aws sts get-caller-identity`
2. Check AWS region: Should be `us-east-1`
3. Check Node.js version: `node --version` (need 18+)

**Can't access the app?**
1. Check security groups allow your IP
2. Wait 2-3 minutes after deployment
3. Try the direct EC2 IP if S3 URL doesn't work immediately

**Database connection issues?**
- The script automatically configures security groups
- RDS takes 5-10 minutes to become available

## 📞 Support

This simplified deployment removes all the complexity while keeping costs at $0-5/month within AWS free tier. Perfect for:

- Portfolio demonstrations
- Learning AWS basics
- Prototyping and testing
- Small-scale applications

---

**Total deployment time**: 10-15 minutes
**Monthly cost**: $0-5 (free tier)
**Complexity**: Minimal