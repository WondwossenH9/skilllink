variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name of the project (used for resource naming)"
  type        = string
  default     = "skilllink"
}

variable "allowed_ssh_cidr" {
  description = "CIDR block allowed to SSH to EC2 instances"
  type        = string
  default     = "0.0.0.0/0" # Change this to your IP address for security
}

variable "domain_name" {
  description = "Domain name for the application"
  type        = string
  default     = "skilllink.example.com" # Change this to your actual domain
}

variable "key_pair_name" {
  description = "Name of the EC2 key pair for SSH access"
  type        = string
  default     = "skilllink-key" # Change this to your actual key pair name
}

variable "db_name" {
  description = "Name of the PostgreSQL database"
  type        = string
  default     = "skilllink"
}

variable "db_username" {
  description = "Username for the PostgreSQL database"
  type        = string
  default     = "skilllink_admin"
}

variable "db_password" {
  description = "Password for the PostgreSQL database"
  type        = string
  sensitive   = true
  default     = "ChangeMe123!" # Change this to a secure password
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "prod"
}

variable "instance_type" {
  description = "EC2 instance type for the backend"
  type        = string
  default     = "t3.micro"
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "Allocated storage for RDS in GB"
  type        = number
  default     = 20
}
