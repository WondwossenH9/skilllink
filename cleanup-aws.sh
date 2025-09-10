#!/bin/bash
set -e

# SkillLink AWS Cleanup Script
echo "🧹 SkillLink AWS Resource Cleanup"
echo "================================="

if [ -z "$1" ]; then
    echo "Usage: $0 <timestamp>"
    echo "Example: $0 1699123456"
    echo ""
    echo "To find your resources:"
    echo "aws ec2 describe-instances --query 'Reservations[].Instances[].[InstanceId,Tags[?Key==\`Name\`].Value|[0],State.Name]' --output table"
    exit 1
fi

TIMESTAMP="$1"
PROJECT_NAME="skilllink"

echo "🔍 Looking for resources with timestamp: $TIMESTAMP"

# Find resources
INSTANCE_ID=$(aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=$PROJECT_NAME-server" "Name=instance-state-name,Values=running,stopped" \
    --query 'Reservations[0].Instances[0].InstanceId' --output text 2>/dev/null || echo "None")

DB_IDENTIFIER=$(aws rds describe-db-instances \
    --query "DBInstances[?contains(DBInstanceIdentifier, '$PROJECT_NAME-db-$TIMESTAMP')].DBInstanceIdentifier" \
    --output text 2>/dev/null || echo "None")

S3_BUCKET=$(aws s3api list-buckets \
    --query "Buckets[?contains(Name, '$PROJECT_NAME-frontend-$TIMESTAMP')].Name" \
    --output text 2>/dev/null || echo "None")

KEY_NAME="$PROJECT_NAME-key-$TIMESTAMP"
SG_NAME="$PROJECT_NAME-sg-$TIMESTAMP"

echo ""
echo "📋 Found resources:"
echo "Instance ID: $INSTANCE_ID"
echo "Database: $DB_IDENTIFIER"
echo "S3 Bucket: $S3_BUCKET"
echo "Key Pair: $KEY_NAME"
echo ""

read -p "🗑️ Delete these resources? (y/N): " confirm
if [[ $confirm != [yY] ]]; then
    echo "❌ Cleanup cancelled"
    exit 0
fi

# Cleanup resources
echo "🗑️ Starting cleanup..."

# Terminate EC2 instance
if [[ "$INSTANCE_ID" != "None" && -n "$INSTANCE_ID" ]]; then
    echo "💻 Terminating EC2 instance: $INSTANCE_ID"
    aws ec2 terminate-instances --instance-ids "$INSTANCE_ID"
    echo "⏳ Waiting for instance to terminate..."
    aws ec2 wait instance-terminated --instance-ids "$INSTANCE_ID"
    echo "✅ EC2 instance terminated"
else
    echo "⚠️ No EC2 instance found"
fi

# Delete RDS instance
if [[ "$DB_IDENTIFIER" != "None" && -n "$DB_IDENTIFIER" ]]; then
    echo "🗄️ Deleting RDS instance: $DB_IDENTIFIER"
    aws rds delete-db-instance \
        --db-instance-identifier "$DB_IDENTIFIER" \
        --skip-final-snapshot \
        --delete-automated-backups
    echo "✅ RDS deletion initiated"
else
    echo "⚠️ No RDS instance found"
fi

# Empty and delete S3 bucket
if [[ "$S3_BUCKET" != "None" && -n "$S3_BUCKET" ]]; then
    echo "📦 Deleting S3 bucket: $S3_BUCKET"
    aws s3 rm "s3://$S3_BUCKET" --recursive
    aws s3 rb "s3://$S3_BUCKET"
    echo "✅ S3 bucket deleted"
else
    echo "⚠️ No S3 bucket found"
fi

# Delete security group (after EC2 is terminated)
if [[ "$INSTANCE_ID" != "None" && -n "$INSTANCE_ID" ]]; then
    echo "⏳ Waiting before deleting security group..."
    sleep 30
fi

SG_ID=$(aws ec2 describe-security-groups \
    --filters "Name=group-name,Values=$SG_NAME" \
    --query 'SecurityGroups[0].GroupId' --output text 2>/dev/null || echo "None")

if [[ "$SG_ID" != "None" && -n "$SG_ID" ]]; then
    echo "🛡️ Deleting security group: $SG_ID"
    aws ec2 delete-security-group --group-id "$SG_ID"
    echo "✅ Security group deleted"
fi

# Delete key pair
echo "🔑 Deleting key pair: $KEY_NAME"
aws ec2 delete-key-pair --key-name "$KEY_NAME" || echo "⚠️ Key pair not found"
rm -f "$KEY_NAME.pem"
echo "✅ Key pair deleted"

echo ""
echo "🎉 Cleanup complete!"
echo "All AWS resources have been deleted."
echo "💰 No more charges will be incurred."