# AWS provider
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-1"
}

# SSH Key
variable "key_name" {
  description = "Name for the SSH key pair"
  type        = string
  default     = "terraform-key"
}

# Security Group
variable "web_sg_name" {
  description = "Name of the web server security group"
  type        = string
  default     = "web-sg"
}

variable "db_sg_name" {
  description = "Name of the database security group"
  type        = string
  default     = "db-sg"
}

# S3 Bucket
variable "s3_bucket_name" {
  description = "Name of the S3 bucket"
  type        = string
  default     = "terraform-vicwin-uploads"
}

# Database
variable "db_name" {
  description = "Database name"
  type        = string
  default     = "files"
}

variable "db_username" {
  description = "Database username"
  type        = string
  default     = "admin"
}

variable "db_password" {
  description = "Database password"
  type        = string
  default     = "r0998157!"
}

variable "db_instance_class" {
  description = "Database instance type"
  type        = string
  default     = "db.t3.micro"
}

# EC2
variable "ami_id" {
  description = "AMI ID for EC2 instances"
  type        = string
  default     = "ami-0905a3c97561e0b69"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}
