# SkillLink Deployment Guide

## 🚀 Deployment Options

### Option 1: AWS Manual Deployment

#### Prerequisites:
1. AWS Account
2. AWS Console access
3. Basic knowledge of AWS services

#### Step 1: Deploy Frontend to S3

1. **Build the frontend:**
   ```bash
   cd frontend
   npm run build
   ```

2. **Create S3 Bucket:**
   - Go to AWS S3 Console
   - Create bucket: `skilllink-frontend-[your-name]`
   - Enable static website hosting
   - Set index document: `index.html`
   - Set error document: `index.html`

3. **Configure Bucket Policy:**
   ```json
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Sid": "PublicReadGetObject",
         "Effect": "Allow",
         "Principal": "*",
         "Action": "s3:GetObject",
         "Resource": "arn:aws:s3:::skilllink-frontend-[your-name]/*"
       }
     ]
   }
   ```

4. **Upload Files:**
   - Upload all files from `frontend/build/` to S3 bucket
   - Set all files to public read

#### Step 2: Deploy Backend to EC2

1. **Launch EC2 Instance:**
   - AMI: Amazon Linux 2
   - Instance Type: t2.micro (free tier)
   - Security Group: Allow ports 22 (SSH), 3001 (API)
   - Key Pair: Create new key pair

2. **Connect to EC2:**
   ```bash
   ssh -i your-key.pem ec2-user@your-ec2-ip
   ```

3. **Install Node.js:**
   ```bash
   curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
   source ~/.bashrc
   nvm install 18
   nvm use 18
   ```

4. **Install PM2:**
   ```bash
   npm install -g pm2
   ```

5. **Deploy Application:**
   ```bash
   # Clone your repository
   git clone https://github.com/WondwossenH9/skilllink.git
   cd skilllink/backend
   
   # Install dependencies
   npm install
   
   # Create environment file
   cat > .env <<EOF
   NODE_ENV=production
   PORT=3001
   JWT_SECRET=your-super-secret-jwt-key
   DATABASE_URL=postgresql://username:password@your-rds-endpoint:5432/skilllink
   EOF
   
   # Start with PM2
   pm2 start src/server.js --name skilllink-backend
   pm2 startup
   pm2 save
   ```

#### Step 3: Setup RDS Database

1. **Create RDS Instance:**
   - Engine: PostgreSQL
   - Instance: db.t3.micro (free tier)
   - Storage: 20 GB
   - Security Group: Allow port 5432 from EC2

2. **Update Environment:**
   - Update `DATABASE_URL` in EC2 `.env` file
   - Restart PM2: `pm2 restart skilllink-backend`

### Option 2: Vercel + Railway (Easiest)

#### Frontend (Vercel):
1. **Connect GitHub:**
   - Go to [vercel.com](https://vercel.com)
   - Connect your GitHub account
   - Import `skilllink` repository

2. **Configure Build:**
   - Framework Preset: Create React App
   - Build Command: `cd frontend && npm install && npm run build`
   - Output Directory: `frontend/build`
   - Install Command: `cd frontend && npm install`

3. **Environment Variables:**
   ```
   REACT_APP_API_URL=https://your-railway-app.railway.app/api
   ```

#### Backend (Railway):
1. **Deploy to Railway:**
   - Go to [railway.app](https://railway.app)
   - Connect GitHub
   - Deploy from `backend` directory

2. **Environment Variables:**
   ```
   NODE_ENV=production
   PORT=3001
   JWT_SECRET=your-super-secret-jwt-key
   DATABASE_URL=postgresql://...
   ```

3. **Database:**
   - Railway provides PostgreSQL
   - Auto-configured in `DATABASE_URL`

### Option 3: Netlify + Render

#### Frontend (Netlify):
1. **Deploy:**
   - Go to [netlify.com](https://netlify.com)
   - Drag & drop `frontend/build` folder
   - Or connect GitHub for auto-deploy

2. **Environment Variables:**
   ```
   REACT_APP_API_URL=https://your-render-app.onrender.com/api
   ```

#### Backend (Render):
1. **Deploy:**
   - Go to [render.com](https://render.com)
   - Connect GitHub
   - Deploy from `backend` directory

2. **Database:**
   - Use Render's PostgreSQL service
   - Auto-configured

## 🔧 Environment Configuration

### Frontend Environment Variables:
```env
REACT_APP_API_URL=https://your-backend-url.com/api
```

### Backend Environment Variables:
```env
NODE_ENV=production
PORT=3001
JWT_SECRET=your-super-secret-jwt-key-here
DATABASE_URL=postgresql://username:password@host:port/database
```

## 🧪 Post-Deployment Testing

1. **Test Frontend:**
   - Visit your frontend URL
   - Test registration/login
   - Test skill creation/browsing

2. **Test Backend:**
   - Health check: `GET /api/health`
   - Skills API: `GET /api/skills`
   - Registration: `POST /api/auth/register`

3. **Test Database:**
   - Verify data persistence
   - Test user creation
   - Test skill creation

## 🔒 Security Checklist

- [ ] JWT_SECRET is strong and unique
- [ ] Database credentials are secure
- [ ] CORS is properly configured
- [ ] Rate limiting is enabled
- [ ] Input validation is working
- [ ] HTTPS is enabled (for production)

## 📊 Monitoring

### AWS (Option 1):
- CloudWatch for logs
- S3 access logs
- RDS monitoring

### Vercel/Railway (Option 2):
- Built-in monitoring
- Automatic scaling
- Error tracking

### Netlify/Render (Option 3):
- Built-in analytics
- Performance monitoring
- Error tracking

## 🚨 Troubleshooting

### Common Issues:
1. **CORS Errors:** Check backend CORS configuration
2. **Database Connection:** Verify DATABASE_URL
3. **Build Failures:** Check Node.js version compatibility
4. **Environment Variables:** Ensure all required vars are set

### Debug Commands:
```bash
# Check backend logs
pm2 logs skilllink-backend

# Check database connection
node -e "console.log(process.env.DATABASE_URL)"

# Test API endpoints
curl https://your-backend-url.com/api/health
```

## 📞 Support

For deployment issues:
1. Check the troubleshooting section
2. Review environment variables
3. Check service-specific documentation
4. Verify network connectivity

---

**Recommended for beginners:** Option 2 (Vercel + Railway)
**Recommended for production:** Option 1 (AWS)
**Recommended for quick demo:** Option 3 (Netlify + Render)
