output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_id" {
  description = "ID of the public subnet"
  value       = aws_subnet.public.id
}

output "private_subnet_id" {
  description = "ID of the private subnet"
  value       = aws_subnet.private.id
}

output "backend_instance_id" {
  description = "ID of the backend EC2 instance"
  value       = aws_instance.backend.id
}

output "backend_public_ip" {
  description = "Public IP address of the backend EC2 instance"
  value       = aws_instance.backend.public_ip
}

output "backend_private_ip" {
  description = "Private IP address of the backend EC2 instance"
  value       = aws_instance.backend.private_ip
}

output "rds_endpoint" {
  description = "Endpoint of the RDS instance"
  value       = aws_db_instance.main.endpoint
}

output "rds_port" {
  description = "Port of the RDS instance"
  value       = aws_db_instance.main.port
}

output "rds_database_name" {
  description = "Name of the RDS database"
  value       = aws_db_instance.main.db_name
}

output "rds_username" {
  description = "Username for the RDS database"
  value       = aws_db_instance.main.username
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.main.dns_name
}

output "alb_zone_id" {
  description = "Zone ID of the Application Load Balancer"
  value       = aws_lb.main.zone_id
}

output "frontend_bucket_name" {
  description = "Name of the S3 bucket for the frontend"
  value       = aws_s3_bucket.frontend.bucket
}

output "frontend_bucket_website_endpoint" {
  description = "Website endpoint of the S3 bucket"
  value       = aws_s3_bucket.frontend.website_endpoint
}

output "cloudfront_distribution_id" {
  description = "ID of the CloudFront distribution"
  value       = aws_cloudfront_distribution.frontend.id
}

output "cloudfront_domain_name" {
  description = "Domain name of the CloudFront distribution"
  value       = aws_cloudfront_distribution.frontend.domain_name
}

output "acm_certificate_arn" {
  description = "ARN of the ACM certificate"
  value       = aws_acm_certificate.main.arn
}

output "ssm_db_password_parameter" {
  description = "SSM parameter name for database password"
  value       = aws_ssm_parameter.db_password.name
}

output "ssm_jwt_secret_parameter" {
  description = "SSM parameter name for JWT secret"
  value       = aws_ssm_parameter.jwt_secret.name
}

output "application_urls" {
  description = "URLs for the application"
  value = {
    frontend = "https://${var.domain_name}"
    backend  = "https://${aws_lb.main.dns_name}"
    api      = "https://${aws_lb.main.dns_name}/api"
  }
}

output "ssh_command" {
  description = "SSH command to connect to the backend instance"
  value       = "ssh -i ${var.key_pair_name}.pem ubuntu@${aws_instance.backend.public_ip}"
}
