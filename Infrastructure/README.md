# AWS Grocery Shop Infrastructure

This directory contains the Terraform code to provision the AWS infrastructure for the Grocery Shop application.

## Prerequisites

Before you begin, ensure you have the following installed and configured:

1.  **Terraform** (v1.0+)
2.  **AWS CLI** (configured with `aws configure`)
3.  **SSH Key Pair**: You need an SSH public key file (default: `key-aws-ssh.pub`) in this directory.

## Configuration

1.  Create a `terraform.tfvars` file (or use the existing one) with the following variables:

    ```hcl
    aws_region               = "eu-central-1"
    aws_profile              = "default"
    ssh_key_pair_name        = "key-aws-ssh"       # Name of your key file (without .pub)
    s3_bucket_name           = "your-unique-bucket-name"
    grocery_db_name          = "grocerydb"
    grocery_username         = "grocery_user"
    grocery_user_db_password = "secureUserPassword123!"
    db_password              = "secureMasterPassword123!"
    ```

    > **Note:** Passwords should be strong. The S3 bucket name must be globally unique.

## Deployment Steps

1.  **Initialize Terraform**:
    Downloads the necessary providers.
    ```bash
    terraform init
    ```

2.  **Review the Plan**:
    Shows what resources will be created.
    ```bash
    terraform plan
    ```

3.  **Apply the Infrastructure**:
    Provisions the resources in AWS.
    ```bash
    terraform apply
    ```
    Confirm with `yes` when prompted.

## Accessing the Application

After a successful deployment, Terraform will output the Load Balancer URL:

```
alb_dns_name = "http://grocery-shop-alb-..."
```

*   **Web App**: Open the `alb_dns_name` URL in your browser.
*   **Wait Time**: It may take a few minutes for the EC2 instances to launch, install Docker, and start the application.

## Infrastructure Overview

*   **VPC**: Custom VPC with Public and Private Subnets.
*   **ALB**: Application Load Balancer (Public) handles traffic.
*   **EC2**: Auto Scaling Group (Public Subnets) runs the application containers.
*   **RDS**: PostgreSQL Database (Private Subnets) stores data.
*   **S3**: Bucket for storing user uploads (Avatars).

## Cleaning Up

To destroy the infrastructure and stop creating costs:

```bash
terraform destroy
```
