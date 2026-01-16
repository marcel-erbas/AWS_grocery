# Fetch the latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}


# Main EC2 instance for the web server
resource "aws_instance" "main" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = var.ec2_instance_type

  # Attach IAM role for S3 access
  iam_instance_profile = aws_iam_instance_profile.grocery_ec2_profile.name

  # Network and access configuration
  key_name               = aws_key_pair.deployer.key_name
  vpc_security_group_ids = [aws_security_group.allow_ssh_and_shop.id]
  subnet_id              = aws_subnet.grocery_shop_public_subnet.id

  # Bootstrap script to configure the application and DB connection
  user_data = templatefile("userdata.sh", {
    aws_region               = var.aws_region
    s3_bucket_name           = var.s3_bucket_name
    rds_endpoint             = aws_db_instance.postgres.address
    rds_master_password      = aws_db_instance.postgres.password
    grocery_username         = var.grocery_username
    grocery_db_name          = var.grocery_db_name
    grocery_user_db_password = var.grocery_user_db_password
  })

  tags = {
    Name = "grocery-web-server"
  }
}


# Register public SSH key for instance access
resource "aws_key_pair" "deployer" {
  key_name   = var.ssh_key_pair_name
  public_key = file("${path.module}/${var.ssh_key_pair_name}.pub")
}


# Get the current public IP address of the machine running Terraform
data "http" "myip" {
  url = "https://ipv4.icanhazip.com"
}


# Security group for web server traffic
resource "aws_security_group" "allow_ssh_and_shop" {
  name        = "ec2-sg-allow-ssh-and-shop"
  description = "allow ssh and shop access"
  vpc_id      = aws_vpc.grocery_shop_vpc.id

  # Restricted SSH access only for the administrator's current IP
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${chomp(data.http.myip.response_body)}/32"]
  }

  # Public access to the shop application (Port 5000)
  ingress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Jeder im Internet darf den Shop sehen
  }

  # Allow all outgoing traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


# IAM Role to allow EC2 instances to call AWS services
resource "aws_iam_role" "grocery_ec2_role" {
  name = "grocery-ec2-role"

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
}


# Attach S3 full access policy to the IAM role
resource "aws_iam_role_policy_attachment" "s3_access" {
  role       = aws_iam_role.grocery_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}


# Instance profile wrapper for the IAM role to be used by EC2
resource "aws_iam_instance_profile" "grocery_ec2_profile" {
  name = "grocery-ec2-profile"
  role = aws_iam_role.grocery_ec2_role.name
}