#!/bin/bash
set -euo pipefail

# ========================
# Config
# ========================
PROJECT_NAME="skilllink"
AWS_REGION="us-east-1"
OWNER="Wondwossen"

# ========================
# Environment Handling
# ========================
ENVIRONMENT="${2:-dev}"  # Default to dev if not provided

if [[ "$ENVIRONMENT" != "dev" && "$ENVIRONMENT" != "prod" ]]; then
  echo "❌ Invalid environment: $ENVIRONMENT"
  echo "Usage: $0 {deploy|cleanup} {dev|prod}"
  exit 1
fi

# Instance types by environment
if [[ "$ENVIRONMENT" == "dev" ]]; then
  EC2_TYPE="t2.micro"
  RDS_CLASS="db.t3.micro"
else
  EC2_TYPE="t3.small"
  RDS_CLASS="db.t3.small"
fi

# Resource names
S3_BUCKET="${PROJECT_NAME}-frontend-${ENVIRONMENT}-$(date +%s)"
EC2_NAME_TAG="${PROJECT_NAME}-ec2-${ENVIRONMENT}"
RDS_NAME_TAG="${PROJECT_NAME}-rds-${ENVIRONMENT}"
CF_COMMENT="${PROJECT_NAME}-${ENVIRONMENT}"

# ========================
# Deploy Function
# ========================
deploy() {
  echo "🚀 Starting deployment for $ENVIRONMENT environment..."

  # ------------------------
  # S3 Bucket
  # ------------------------
  echo "📦 Creating S3 bucket: $S3_BUCKET"
  aws s3 mb s3://$S3_BUCKET --region $AWS_REGION
  aws s3api put-public-access-block \
    --bucket $S3_BUCKET \
    --public-access-block-configuration BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
  aws s3api put-bucket-tagging --bucket $S3_BUCKET \
    --tagging "TagSet=[{Key=Project,Value=$PROJECT_NAME},{Key=Owner,Value=$OWNER},{Key=Environment,Value=$ENVIRONMENT}]"

  echo "📤 Uploading website files..."
  aws s3 sync ./dist s3://$S3_BUCKET --delete

  # ------------------------
  # CloudFront + SSL
  # ------------------------
  echo "🌐 Setting up CloudFront with HTTPS..."
  CERT_ARN=$(aws acm list-certificates --region us-east-1 \
      --query "CertificateSummaryList[?DomainName=='$S3_BUCKET'].CertificateArn" --output text)

  if [[ -z "$CERT_ARN" ]]; then
    echo "🔐 Requesting new ACM certificate..."
    CERT_ARN=$(aws acm request-certificate \
        --domain-name $S3_BUCKET \
        --validation-method DNS \
        --tags Key=Project,Value=$PROJECT_NAME Key=Owner,Value=$OWNER Key=Environment,Value=$ENVIRONMENT \
        --region us-east-1 \
        --query 'CertificateArn' --output text)
    echo "⚠️ DNS validation required for $S3_BUCKET. Validate in ACM console before CloudFront will serve HTTPS."
  fi

  CF_DIST_ID=$(aws cloudfront create-distribution \
      --distribution-config "{
        \"CallerReference\": \"${PROJECT_NAME}-${ENVIRONMENT}-$(date +%s)\",
        \"Comment\": \"$CF_COMMENT\",
        \"Origins\": {
          \"Items\": [{
            \"Id\": \"S3Origin\",
            \"DomainName\": \"${S3_BUCKET}.s3.amazonaws.com\",
            \"S3OriginConfig\": {\"OriginAccessIdentity\": \"\"}
          }],
          \"Quantity\": 1
        },
        \"DefaultCacheBehavior\": {
          \"TargetOriginId\": \"S3Origin\",
          \"ViewerProtocolPolicy\": \"redirect-to-https\",
          \"AllowedMethods\": {\"Quantity\": 2, \"Items\": [\"GET\",\"HEAD\"]},
          \"CachedMethods\": {\"Quantity\": 2, \"Items\": [\"GET\",\"HEAD\"]},
          \"ForwardedValues\": {\"QueryString\": false, \"Cookies\": {\"Forward\": \"none\"}}
        },
        \"Enabled\": true,
        \"DefaultRootObject\": \"index.html\",
        \"ViewerCertificate\": {
          \"ACMCertificateArn\": \"$CERT_ARN\",
          \"SSLSupportMethod\": \"sni-only\",
          \"MinimumProtocolVersion\": \"TLSv1.2_2021\"
        }
      }" \
      --query 'Distribution.Id' --output text)

  aws cloudfront tag-resource --resource "$CF_DIST_ID" \
    --tags "Items=[{Key=Project,Value=$PROJECT_NAME},{Key=Owner,Value=$OWNER},{Key=Environment,Value=$ENVIRONMENT}]"

  echo "✅ CloudFront with HTTPS ready. Distribution ID: $CF_DIST_ID"

  # ------------------------
  # EC2 Instance
  # ------------------------
  echo "💻 Launching EC2 instance..."
  AMI_ID=$(aws ec2 describe-images --owners amazon \
    --filters "Name=name,Values=amzn2-ami-hvm-*-x86_64-gp2" "Name=state,Values=available" \
    --query "Images | sort_by(@, &CreationDate) | [-1].ImageId" --output text --region $AWS_REGION)

  KEY_NAME="${PROJECT_NAME}-keypair-${ENVIRONMENT}"
  if ! aws ec2 describe-key-pairs --key-names $KEY_NAME &> /dev/null; then
      aws ec2 create-key-pair --key-name $KEY_NAME --query 'KeyMaterial' --output text > $KEY_NAME.pem
      chmod 400 $KEY_NAME.pem
      echo "✅ Created key pair: $KEY_NAME.pem"
  fi

  SECURITY_GROUP_NAME="${PROJECT_NAME}-sg-${ENVIRONMENT}"
  SECURITY_GROUP_ID=$(aws ec2 create-security-group \
      --group-name $SECURITY_GROUP_NAME \
      --description "Security group for $PROJECT_NAME $ENVIRONMENT" \
      --tag-specifications "ResourceType=security-group,Tags=[{Key=Project,Value=$PROJECT_NAME},{Key=Owner,Value=$OWNER},{Key=Environment,Value=$ENVIRONMENT}]" \
      --query 'GroupId' --output text)

  aws ec2 authorize-security-group-ingress --group-id $SECURITY_GROUP_ID --protocol tcp --port 22 --cidr 0.0.0.0/0
  aws ec2 authorize-security-group-ingress --group-id $SECURITY_GROUP_ID --protocol tcp --port 3001 --cidr 0.0.0.0/0

  INSTANCE_ID=$(aws ec2 run-instances \
      --image-id $AMI_ID \
      --count 1 \
      --instance-type $EC2_TYPE \
      --key-name $KEY_NAME \
      --security-group-ids $SECURITY_GROUP_ID \
      --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$EC2_NAME_TAG},{Key=Project,Value=$PROJECT_NAME},{Key=Owner,Value=$OWNER},{Key=Environment,Value=$ENVIRONMENT}]" \
      --query 'Instances[0].InstanceId' --output text)

  echo "⏳ Waiting for EC2 instance to be running..."
  aws ec2 wait instance-running --instance-ids $INSTANCE_ID
  EC2_PUBLIC_IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)
  echo "✅ EC2 running: $INSTANCE_ID at $EC2_PUBLIC_IP"

  # ------------------------
  # RDS Instance
  # ------------------------
  echo "🛢️ Creating RDS instance..."
  DB_INSTANCE_ID="$RDS_NAME_TAG"
  DB_USERNAME="skilllink_user"
  DB_PASSWORD=$(openssl rand -base64 12)

  aws rds create-db-instance \
      --db-instance-identifier $DB_INSTANCE_ID \
      --db-instance-class $RDS_CLASS \
      --engine postgres \
      --master-username $DB_USERNAME \
      --master-user-password $DB_PASSWORD \
      --allocated-storage 20 \
      --publicly-accessible \
      --storage-encrypted \
      --backup-retention-period 7 \
      --tag-list Key=Project,Value=$PROJECT_NAME Key=Owner,Value=$OWNER Key=Environment,Value=$ENVIRONMENT \
      --region $AWS_REGION

  # ------------------------
  # Generate .env.deployment
  # ------------------------
  echo "📝 Generating environment variables file..."
  CF_DOMAIN=$(aws cloudfront get-distribution --id $CF_DIST_ID --query 'Distribution.DomainName' --output text)

  cat > .env.deployment <<EOL
# SkillLink Deployment Environment
PROJECT_NAME=$PROJECT_NAME
ENVIRONMENT=$ENVIRONMENT
OWNER=$OWNER
AWS_REGION=$AWS_REGION

# Frontend
S3_BUCKET=$S3_BUCKET
CLOUDFRONT_DOMAIN=$CF_DOMAIN

# Backend
EC2_INSTANCE_ID=$INSTANCE_ID
EC2_PUBLIC_IP=$EC2_PUBLIC_IP

# RDS
DB_INSTANCE_ID=$DB_INSTANCE_ID
DB_NAME=skilllink
DB_USERNAME=$DB_USERNAME
DB_PASSWORD=$DB_PASSWORD
EOL

  echo "✅ .env.deployment file created."
  echo "Deployment complete for $ENVIRONMENT!"
  echo "CloudFront: $CF_DOMAIN"
  echo "EC2: $EC2_PUBLIC_IP"
}

# ========================
# Cleanup Function
# ========================
cleanup() {
  echo "⚠️ Cleanup will delete all resources tagged Project=$PROJECT_NAME and Environment=$ENVIRONMENT."
  read -p "Are you sure? (y/N): " confirm
  [[ "$confirm" != "y" ]] && echo "Aborted." && exit 1

  # EC2
  EC2_IDS=$(aws ec2 describe-instances --filters "Name=tag:Project,Values=$PROJECT_NAME" "Name=tag:Environment,Values=$ENVIRONMENT" --query "Reservations[].Instances[].InstanceId" --output text)
  [[ -n "$EC2_IDS" ]] && aws ec2 terminate-instances --instance-ids $EC2_IDS && aws ec2 wait instance-terminated --instance-ids $EC2_IDS

  # RDS
  RDS_IDS=$(aws rds describe-db-instances --query "DBInstances[?Tags[?Key=='Project' && Value=='$PROJECT_NAME'] && DBInstanceIdentifier.contains(@, '$ENVIRONMENT')].DBInstanceIdentifier" --output text)
  for db in $RDS_IDS; do
      aws rds delete-db-instance --db-instance-identifier $db --skip-final-snapshot
  done

  # CloudFront
  CF_IDS=$(aws cloudfront list-distributions --query "DistributionList.Items[?Comment=='$PROJECT_NAME-$ENVIRONMENT'].Id" --output text)
  for cf in $CF_IDS; do
      ETag=$(aws cloudfront get-distribution-config --id $cf --query 'ETag' --output text)
      aws cloudfront update-distribution --id $cf --distribution-config "$(aws cloudfront get-distribution-config --id $cf --query 'DistributionConfig')" --if-match $ETag --enabled false
      aws cloudfront delete-distribution --id $cf --if-match $ETag
  done

  # S3
  S3_BUCKETS=$(aws s3api list-buckets --query "Buckets[].Name" --output text | tr '\t' '\n' | grep "$PROJECT_NAME-frontend-$ENVIRONMENT")
  for bucket in $S3_BUCKETS; do
      aws s3 rm s3://$bucket --recursive
      aws s3api delete-bucket --bucket $bucket
  done

  echo "✅ Cleanup completed for $ENVIRONMENT."
}

# ========================
# Command Line Handling
# ========================
case "${1:-deploy}" in
  deploy)
    deploy
    ;;
  cleanup)
    cleanup
    ;;
  *)
    echo "Usage: $0 {deploy|cleanup} {dev|prod}"
    exit 1
    ;;
esac
