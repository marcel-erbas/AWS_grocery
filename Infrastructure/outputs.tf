# The public IP address of the EC2 instance
output "instance_public_ip" {
  description = "public ip from ec2 instance"
  value       = aws_instance.main.public_ip
}


# Pre-formatted SSH command for quick terminal access
output "ssh_connection_command" {
  description = "copy this to connect to your ec2 instance"
  value       = "ssh -i ${var.ssh_key_pair_name}.pem ec2-user@${aws_instance.main.public_ip}"
}


# The load balancer URL to access the web shop in a browser
output "alb_dns_name" {
  description = "The DNS name of the load balancer"
  value       = "http://${aws_lb.grocery_shop_alb.dns_name}"
}


# The connection endpoint for the RDS database
output "rds_endpoint" {
  description = "The DNS address of the RDS instance"
  # Returns the address in the format: name.id.region.rds.amazonaws.com
  value = aws_db_instance.postgres.address
}


# The full connection string for internal application use
output "rds_connection_string" {
  description = "Internal connection string for the PostgreSQL database"
  sensitive   = true # Hides the value in the console to protect credentials
  value       = "postgresql://postgres:${var.db_password}@${aws_db_instance.postgres.endpoint}/grocerydb"
}
