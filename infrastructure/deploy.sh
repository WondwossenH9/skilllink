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

# Network defaults
ALLOWED_SSH_CIDR="${ALLOWED_SSH_CIDR:-0.0.0.0/0}"  # TODO: set to your IP/CIDR


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
  # ------------------------
  # S3 Bucket (idempotent)
  # ------------------------
  # Prefer existing S3_BUCKET from prior deployment file
  if [[ -f infrastructure/.env.deployment ]]; then
    # shellcheck disable=SC1091
    source infrastructure/.env.deployment
  fi

  S3_BUCKET="${S3_BUCKET:-${PROJECT_NAME}-frontend-${ENVIRONMENT}}"

  echo "📦 Ensuring S3 bucket exists: $S3_BUCKET"
  if aws s3api head-bucket --bucket "$S3_BUCKET" --region "$AWS_REGION" 2>/dev/null; then
    echo "ℹ️ Bucket $S3_BUCKET already exists. Reusing."
  else
    aws s3 mb "s3://$S3_BUCKET" --region "$AWS_REGION"
    if [[ $? -ne 0 ]]; then
      ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
      S3_BUCKET="${S3_BUCKET}-${ACCOUNT_ID}"
      echo "🆔 Falling back to bucket name with account ID: $S3_BUCKET"
      if ! aws s3api head-bucket --bucket "$S3_BUCKET" --region "$AWS_REGION" 2>/dev/null; then
        aws s3 mb "s3://$S3_BUCKET" --region "$AWS_REGION"
      fi
    fi
    aws s3api put-public-access-block       --bucket "$S3_BUCKET"       --public-access-block-configuration BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
    aws s3api put-bucket-tagging --bucket "$S3_BUCKET"       --tagging "TagSet=[{Key=Project,Value=$PROJECT_NAME},{Key=Owner,Value=$OWNER},{Key=Environment,Value=$ENVIRONMENT}]"
    echo "✅ Created bucket $S3_BUCKET"
  fi

  # Ensure frontend build exists
  if [[ ! -d frontend/build ]]; then
    echo "⚠️ frontend/build not found. Attempting to build frontend..."
    if [[ -f frontend/package.json ]]; then
      (cd frontend && npm ci && npm run build)
    else
      echo "❌ Frontend build directory missing and no package.json to build from. Aborting."
      exit 1
    fi
  fi

  echo "📤 Uploading website files..."
  aws s3 sync frontend/build "s3://$S3_BUCKET" --delete

  # ------------------------
# ------------------------
  # ------------------------
  # CloudFront + SSL
  # ------------------------
  echo "🌐 Skipping CloudFront HTTPS and ACM certificate setup (no real domain provided)."
  CF_DOMAIN=""
  # To enable HTTPS and CloudFront, uncomment and configure the following block after you have a real domain:
  # ...existing code...
    #           \"S3OriginConfig\": {\"OriginAccessIdentity\": \"\"}
    #         }],
    #         \"Quantity\": 1
    #       },
    #       \"DefaultCacheBehavior\": {
    #         \"TargetOriginId\": \"S3Origin\",
    #         \"ViewerProtocolPolicy\": \"redirect-to-https\",
    #         \"AllowedMethods\": {\"Quantity\": 2, \"Items\": [\"GET\",\"HEAD\"]},
    #         \"CachedMethods\": {\"Quantity\": 2, \"Items\": [\"GET\",\"HEAD\"]},
    #         \"ForwardedValues\": {\"QueryString\": false, \"Cookies\": {\"Forward\": \"none\"}}
    #       },
    #       \"Enabled\": true,
    #       \"DefaultRootObject\": \"index.html\",
    #       \"ViewerCertificate\": {
    #         \"ACMCertificateArn\": \"$CERT_ARN\",
    #         \"SSLSupportMethod\": \"sni-only\",
    #         \"MinimumProtocolVersion\": \"TLSv1.2_2021\"
    #       }
    #     }" \
    #     --query 'Distribution.Id' --output text)
    #
    # aws cloudfront tag-resource --resource "$CF_DIST_ID" \
    #   --tags "Items=[{Key=Project,Value=$PROJECT_NAME},{Key=Owner,Value=$OWNER},{Key=Environment,Value=$ENVIRONMENT}]"
    #
    # echo "✅ CloudFront with HTTPS ready. Distribution ID: $CF_DIST_ID"

  # ------------------------
  # EC2 Instance (idempotent)
  # ------------------------
  echo "💻 Ensuring EC2 instance exists..."
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
  VPC_ID=$(aws ec2 describe-vpcs --filters "Name=isDefault,Values=true" --query "Vpcs[0].VpcId" --output text --region $AWS_REGION)
  SECURITY_GROUP_ID=$(aws ec2 describe-security-groups --filters "Name=group-name,Values=$SECURITY_GROUP_NAME" "Name=vpc-id,Values=$VPC_ID" --query 'SecurityGroups[0].GroupId' --output text --region $AWS_REGION)
  if [[ "$SECURITY_GROUP_ID" != "None" && "$SECURITY_GROUP_ID" != "" ]]; then
    echo "ℹ️ Security group $SECURITY_GROUP_NAME already exists in VPC $VPC_ID. Using existing group."
    # Ensure required ingress rules exist
    EXISTING_22=$(aws ec2 describe-security-groups --group-ids $SECURITY_GROUP_ID --query "length(SecurityGroups[0].IpPermissions[?FromPort==\`22\` && IpProtocol=='tcp'])" --output text)
    if [[ "$EXISTING_22" == "0" ]]; then
      aws ec2 authorize-security-group-ingress --group-id $SECURITY_GROUP_ID --protocol tcp --port 22 --cidr $ALLOWED_SSH_CIDR
    fi
    EXISTING_3001=$(aws ec2 describe-security-groups --group-ids $SECURITY_GROUP_ID --query "length(SecurityGroups[0].IpPermissions[?FromPort==\`3001\` && IpProtocol=='tcp'])" --output text)
    if [[ "$EXISTING_3001" == "0" ]]; then
      aws ec2 authorize-security-group-ingress --group-id $SECURITY_GROUP_ID --protocol tcp --port 3001 --cidr 0.0.0.0/0
    fi
  else
    echo "🔒 Security group $SECURITY_GROUP_NAME does not exist. Creating..."
    SECURITY_GROUP_ID=$(aws ec2 create-security-group \
      --group-name $SECURITY_GROUP_NAME \
      --description "Security group for $PROJECT_NAME $ENVIRONMENT" \
      --vpc-id $VPC_ID \
      --tag-specifications "ResourceType=security-group,Tags=[{Key=Project,Value=$PROJECT_NAME},{Key=Owner,Value=$OWNER},{Key=Environment,Value=$ENVIRONMENT}]" \
      --query 'GroupId' --output text)
    aws ec2 authorize-security-group-ingress --group-id $SECURITY_GROUP_ID --protocol tcp --port 22 --cidr $ALLOWED_SSH_CIDR
    aws ec2 authorize-security-group-ingress --group-id $SECURITY_GROUP_ID --protocol tcp --port 3001 --cidr 0.0.0.0/0
    echo "✅ Security group $SECURITY_GROUP_NAME created and configured."
  fi

  # Ensure SSH is restricted to ALLOWED_SSH_CIDR
  aws ec2 revoke-security-group-ingress --group-id $SECURITY_GROUP_ID --protocol tcp --port 22 --cidr 0.0.0.0/0 2>/dev/null || true
  EXISTING_SSH=$(aws ec2 describe-security-groups --group-ids $SECURITY_GROUP_ID --query "length(SecurityGroups[0].IpPermissions[?FromPort==\`22\` && IpProtocol=='tcp' && contains(IpRanges[].CidrIp, '$ALLOWED_SSH_CIDR')])" --output text)
  if [[ "$EXISTING_SSH" == "0" ]]; then
    aws ec2 authorize-security-group-ingress --group-id $SECURITY_GROUP_ID --protocol tcp --port 22 --cidr $ALLOWED_SSH_CIDR
  fi

  # Prefer reusing an existing instance
  INSTANCE_ID=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=$EC2_NAME_TAG" "Name=instance-state-name,Values=running" --query 'Reservations[0].Instances[0].InstanceId' --output text --region $AWS_REGION)
  if [[ "$INSTANCE_ID" == "None" || -z "$INSTANCE_ID" ]]; then
    # Try to find a stopped instance to start
    STOPPED_ID=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=$EC2_NAME_TAG" "Name=instance-state-name,Values=stopped" --query 'Reservations[0].Instances[0].InstanceId' --output text --region $AWS_REGION)
    if [[ "$STOPPED_ID" != "None" && -n "$STOPPED_ID" ]]; then
      echo "🔄 Starting stopped EC2 instance $STOPPED_ID..."
      aws ec2 start-instances --instance-ids $STOPPED_ID >/dev/null
      INSTANCE_ID="$STOPPED_ID"
    else
      echo "🆕 Launching new EC2 instance..."
      INSTANCE_ID=$(aws ec2 run-instances \
        --image-id $AMI_ID \
        --count 1 \
        --instance-type $EC2_TYPE \
        --key-name $KEY_NAME \
        --security-group-ids $SECURITY_GROUP_ID \
        --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$EC2_NAME_TAG},{Key=Project,Value=$PROJECT_NAME},{Key=Owner,Value=$OWNER},{Key=Environment,Value=$ENVIRONMENT}]" \
        --query 'Instances[0].InstanceId' --output text)
      echo "✅ EC2 instance created: $INSTANCE_ID"
    fi
  else
    echo "ℹ️ Reusing running EC2 instance: $INSTANCE_ID"
  fi

  echo "⏳ Waiting for EC2 instance to be running..."
  aws ec2 wait instance-running --instance-ids $INSTANCE_ID
  EC2_PUBLIC_IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)
  echo "✅ EC2 ready: $INSTANCE_ID at $EC2_PUBLIC_IP"

  # ------------------------
  # RDS Instance
  # ------------------------
  echo "🛢️ Checking for existing RDS instance..."
  DB_INSTANCE_ID="$RDS_NAME_TAG"
  DB_USERNAME="skilllink_user"
  DB_PASSWORD=$(openssl rand -base64 12)

  EXISTING_RDS=$(aws rds describe-db-instances --db-instance-identifier $DB_INSTANCE_ID --region $AWS_REGION --query 'DBInstances[0].DBInstanceIdentifier' --output text 2>/dev/null || echo "none")
  if [[ "$EXISTING_RDS" == "$DB_INSTANCE_ID" ]]; then
    echo "ℹ️ RDS instance $DB_INSTANCE_ID already exists. Skipping creation."
  else
    echo "🛢️ Creating RDS instance..."
    set +e
# Create a dedicated RDS security group that only allows Postgres from EC2 SG
    RDS_SG_NAME="${PROJECT_NAME}-rds-sg-${ENVIRONMENT}"
    RDS_SG_ID=$(aws ec2 describe-security-groups --filters "Name=group-name,Values=$RDS_SG_NAME" "Name=vpc-id,Values=$VPC_ID" --query 'SecurityGroups[0].GroupId' --output text --region $AWS_REGION)
    if [[ "$RDS_SG_ID" == "None" || -z "$RDS_SG_ID" ]]; then
      RDS_SG_ID=$(aws ec2 create-security-group --group-name "$RDS_SG_NAME" --description "RDS SG for $PROJECT_NAME $ENVIRONMENT" --vpc-id "$VPC_ID" --query 'GroupId' --output text)
      aws ec2 create-tags --resources "$RDS_SG_ID" --tags Key=Project,Value=$PROJECT_NAME Key=Owner,Value=$OWNER Key=Environment,Value=$ENVIRONMENT
    fi
    # Authorize inbound from EC2 SG to Postgres port
    aws ec2 authorize-security-group-ingress --group-id "$RDS_SG_ID" --protocol tcp --port 5432 --source-group "$SECURITY_GROUP_ID" 2>/dev/null || true

        aws rds create-db-instance \
      --db-instance-identifier $DB_INSTANCE_ID \
      --db-instance-class $RDS_CLASS \
      --engine postgres \
      --master-username $DB_USERNAME \
      --master-user-password $DB_PASSWORD \
      --allocated-storage 20 \
      --no-publicly-accessible \
      --storage-encrypted \
      --backup-retention-period 7 \
      --tag-list Key=Project,Value=$PROJECT_NAME Key=Owner,Value=$OWNER Key=Environment,Value=$ENVIRONMENT \
      --region $AWS_REGION
    RDS_STATUS=$?
    set -e
    if [[ $RDS_STATUS -ne 0 ]]; then
      echo "❌ Error: Failed to create RDS instance $DB_INSTANCE_ID. Check AWS Console or logs for details."
    else
      echo "✅ RDS instance $DB_INSTANCE_ID created successfully."
    fi
  fi

# Environment file generation (removed stray EOL)
  echo "⏳ Waiting for RDS instance to be available..."
  aws rds wait db-instance-available --db-instance-identifier "$DB_INSTANCE_ID" --region "$AWS_REGION"

cat > .env.deployment <<EOF
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
EOF

  echo "✅ .env.deployment file created."
  echo "Deployment complete for $ENVIRONMENT!"
  echo "CloudFront: $CF_DOMAIN"
  echo "EC2: $EC2_PUBLIC_IP"
}

# ========================
# Command Line Handling
# ========================
case "${1:-deploy}" in
  deploy)
    deploy
    ;;
  *)
    echo "Usage: $0 deploy {dev|prod}"
    exit 1
    ;;
esac
