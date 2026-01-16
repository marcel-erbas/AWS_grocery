# The load balancer URL to access the web shop in a browser
output "alb_dns_name" {
  description = "The DNS name of the load balancer"
  value       = "http://${aws_lb.grocery_shop_alb.dns_name}"
}
