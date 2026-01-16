# Private RDS PostgreSQL instance configuration
resource "aws_db_instance" "postgres" {
  identifier        = "grocery-rds-postgres-db"
  engine            = "postgres"
  engine_version    = var.postgres_version
  instance_class    = var.rds_instance_class
  allocated_storage = 20
  storage_type      = "gp3"
  storage_encrypted = true

  # Database name and master user credentials
  db_name  = var.grocery_db_name
  username = var.db_username
  password = var.db_password

  # Network and security settings
  publicly_accessible     = false
  multi_az                = false
  backup_retention_period = 7

  # Associated security groups and subnet placement
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.main.name

  # Skip final snapshot for faster deletion in dev environments
  skip_final_snapshot = true

  tags = {
    Name = "grocery-postgres-db"
  }
}


# Subnet group defining which subnets the RDS instance can use
resource "aws_db_subnet_group" "main" {
  name = "grocery-db-subnet-group"
  # Allow inbound PostgreSQL traffic only from the application security group
  subnet_ids = [aws_subnet.grocery_shop_public_subnet_1.id, aws_subnet.grocery_shop_private_subnet.id]

  tags = {
    Name = "Grocery DB Subnet Group"
  }
}


# Security group to control network traffic to the RDS instance
resource "aws_security_group" "rds_sg" {
  name        = "grocery-rds-sg"
  description = "Allow PostgreSQL access from the web server"
  vpc_id      = aws_vpc.grocery_shop_vpc.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.allow_ssh_and_shop.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}