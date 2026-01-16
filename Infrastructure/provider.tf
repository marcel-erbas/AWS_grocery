# Terraform settings and required provider versions
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source = "hashicorp/aws"
      # Allow any 5.x version, but block breaking changes in 6.x
      version = "~> 5.0"
    }
  }
}


# Configure the AWS Provider and authentication profile
provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile

  # Apply global tags to all resources created by this provider
  default_tags {
    tags = {
      Project     = "grocery-shop"
      Environment = "development"
      ManagedBy   = "terraform"
      CostCenter  = "grocery-shop-01"
    }
  }
}


# Data source to fetch available AZs in the current region
data "aws_availability_zones" "available" {
  state = "available"
}
