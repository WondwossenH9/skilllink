# Check current deployment status

$AWS_CLI = "C:\Program Files\Amazon\AWSCLIV2\aws.exe"

Write-Host "Checking SkillLink Deployment Status" -ForegroundColor Cyan
Write-Host "====================================="

# Check S3 buckets
Write-Host "1. S3 Buckets:" -ForegroundColor Yellow
$s3Buckets = & $AWS_CLI s3 ls | Where-Object {$_ -like "*skilllink*"}
if ($s3Buckets) {
    Write-Host "   Found: $s3Buckets" -ForegroundColor Green
    $bucketName = ($s3Buckets -split '\s+')[-1]
    $websiteUrl = "http://$bucketName.s3-website-us-east-1.amazonaws.com"
    Write-Host "   Frontend URL: $websiteUrl" -ForegroundColor Cyan
} else {
    Write-Host "   No SkillLink S3 buckets found" -ForegroundColor Red
}

# Check EC2 instances
Write-Host "2. EC2 Instances:" -ForegroundColor Yellow
$ec2Instances = & $AWS_CLI ec2 describe-instances --filters "Name=tag:Name,Values=skilllink-server" --query "Reservations[].Instances[].[InstanceId,State.Name,PublicIpAddress]" --output text
if ($ec2Instances) {
    Write-Host "   Found: $ec2Instances" -ForegroundColor Green
} else {
    Write-Host "   No SkillLink EC2 instances found" -ForegroundColor Red
}

# Check RDS instances
Write-Host "3. RDS Instances:" -ForegroundColor Yellow
$rdsInstances = & $AWS_CLI rds describe-db-instances --query "DBInstances[?contains(DBInstanceIdentifier, 'skilllink')].[DBInstanceIdentifier,DBInstanceStatus,Endpoint.Address]" --output text
if ($rdsInstances) {
    Write-Host "   Found: $rdsInstances" -ForegroundColor Green
} else {
    Write-Host "   No SkillLink RDS instances found" -ForegroundColor Red
}

# Check key pairs
Write-Host "4. Key Pairs:" -ForegroundColor Yellow
$keyPairs = & $AWS_CLI ec2 describe-key-pairs --query "KeyPairs[?contains(KeyName, 'skilllink')].KeyName" --output text
if ($keyPairs) {
    Write-Host "   Found: $keyPairs" -ForegroundColor Green
} else {
    Write-Host "   No SkillLink key pairs found" -ForegroundColor Red
}

Write-Host ""
Write-Host "Status Summary:" -ForegroundColor Cyan
if ($s3Buckets) {
    Write-Host "✅ Frontend deployed to S3" -ForegroundColor Green
} else {
    Write-Host "❌ Frontend not deployed" -ForegroundColor Red
}

if ($ec2Instances) {
    Write-Host "✅ Backend infrastructure created" -ForegroundColor Green
} else {
    Write-Host "❌ Backend not deployed" -ForegroundColor Red
}

if ($rdsInstances) {
    Write-Host "✅ Database created" -ForegroundColor Green
} else {
    Write-Host "❌ Database not created" -ForegroundColor Red
}