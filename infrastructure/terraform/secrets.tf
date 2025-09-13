# AWS Secrets Manager Configuration
# This file manages all sensitive configuration using AWS Secrets Manager

# Random password for RDS database
resource "random_password" "db_password" {
  length  = 32
  special = false
  upper   = true
  lower   = true
  numeric = true
}

# Random JWT secret
resource "random_password" "jwt_secret" {
  length  = 64
  special = true
  upper   = true
  lower   = true
  numeric = true
}

# Database credentials secret
resource "aws_secretsmanager_secret" "db_credentials" {
  name                    = "${var.project_name}-${var.environment}-db-credentials"
  description             = "Database credentials for ${var.project_name} ${var.environment}"
  recovery_window_in_days = 7

  tags = {
    Name        = "${var.project_name}-${var.environment}-db-credentials"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    username = var.db_username
    password = random_password.db_password.result
    host     = aws_db_instance.main.endpoint
    port     = aws_db_instance.main.port
    database = aws_db_instance.main.db_name
    url      = "postgresql://${var.db_username}:${random_password.db_password.result}@${aws_db_instance.main.endpoint}:${aws_db_instance.main.port}/${aws_db_instance.main.db_name}"
  })
}

# Application secrets
resource "aws_secretsmanager_secret" "app_secrets" {
  name                    = "${var.project_name}-${var.environment}-app-secrets"
  description             = "Application secrets for ${var.project_name} ${var.environment}"
  recovery_window_in_days = 7

  tags = {
    Name        = "${var.project_name}-${var.environment}-app-secrets"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_secretsmanager_secret_version" "app_secrets" {
  secret_id = aws_secretsmanager_secret.app_secrets.id
  secret_string = jsonencode({
    jwt_secret     = random_password.jwt_secret.result
    jwt_expire     = "7d"
    node_env       = var.environment == "prod" ? "production" : "development"
    port           = "3001"
    frontend_url   = var.environment == "prod" ? "https://${var.domain_name}" : "http://${aws_s3_bucket.frontend.website_endpoint}"
    rate_limit_window_ms = "900000"
    rate_limit_max_requests = "100"
  })
}

# IAM policy for application to read secrets
resource "aws_iam_policy" "secrets_access" {
  name        = "${var.project_name}-${var.environment}-secrets-access"
  description = "Policy for application to access secrets"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = [
          aws_secretsmanager_secret.db_credentials.arn,
          aws_secretsmanager_secret.app_secrets.arn
        ]
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-${var.environment}-secrets-access"
    Environment = var.environment
    Project     = var.project_name
  }
}

# IAM role for EC2 instances to access secrets
resource "aws_iam_role" "ec2_secrets_role" {
  name = "${var.project_name}-${var.environment}-ec2-secrets-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-${var.environment}-ec2-secrets-role"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_iam_role_policy_attachment" "ec2_secrets_policy" {
  role       = aws_iam_role.ec2_secrets_role.name
  policy_arn = aws_iam_policy.secrets_access.arn
}

resource "aws_iam_role_policy_attachment" "ec2_ssm_policy" {
  role       = aws_iam_role.ec2_secrets_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2_secrets_profile" {
  name = "${var.project_name}-${var.environment}-ec2-secrets-profile"
  role = aws_iam_role.ec2_secrets_role.name

  tags = {
    Name        = "${var.project_name}-${var.environment}-ec2-secrets-profile"
    Environment = var.environment
    Project     = var.project_name
  }
}
