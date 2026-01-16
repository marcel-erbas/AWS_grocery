# The AWS region where resources will be deployed
variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "eu-central-1"
}


# The name of the SSH key pair to use for EC2 access
variable "ssh_key_pair_name" {
  description = "Name of the SSH Key Pair"
  type        = string
}


# The AWS CLI profile to use for authentication
variable "aws_profile" {
  description = "AWS CLI Profile"
  type        = string
}


# The name of the S3 bucket for storing avatars
variable "s3_bucket_name" {
  description = "S3 Bucket Name for Avatars"
  type        = string
}


# The instance type for the EC2 instance
variable "ec2_instance_type" {
  description = "EC2 Instance Type"
  type        = string
  default     = "t2.micro"
}


# The RDS instance class/type
variable "rds_instance_class" {
  description = "RDS Instance Class"
  type        = string
  default     = "db.t3.micro"
}


# The PostgreSQL engine version for RDS
variable "postgres_version" {
  description = "PostgreSQL Version for RDS"
  type        = string
  default     = "17.6"
}


# The username for the RDS database master user
variable "db_username" {
  description = "Username for RDS Database"
  type        = string
  default     = "postgres"
}


# Master password for the RDS instance
variable "db_password" {
  description = "Password for RDS Database"
  type        = string
  sensitive   = true
}


# The name of the initial database to create in RDS
variable "grocery_db_name" {
  description = "Name of the RDS Database"
  type        = string
  default     = "grocerydb"
}


# grocery_user database user name
variable "grocery_username" {
  description = "grocery_user username for RDS Database"
  type        = string
  default     = "grocery_user"
}


# grocery_user database user password
variable "grocery_user_db_password" {
  description = "grocery_user password for RDS Database"
  type        = string
  sensitive   = true
}