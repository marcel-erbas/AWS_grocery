# Security Group for the Load Balancer
resource "aws_security_group" "grocery_shop_alb_sg" {
  name        = "grocery-shop-alb-sg"
  description = "Allow HTTP inbound traffic"
  vpc_id      = aws_vpc.grocery_shop_vpc.id

  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "grocery-shop-alb-sg"
  }
}


# Application Load Balancer
resource "aws_lb" "grocery_shop_alb" {
  name               = "grocery-shop-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.grocery_shop_alb_sg.id]
  subnets = [
    aws_subnet.grocery_shop_public_subnet_1.id,
    aws_subnet.grocery_shop_public_subnet_2.id
  ]

  tags = {
    Name = "grocery-shop-alb"
  }
}


# Target Group pointing to Port 5000 of EC2 instances
resource "aws_lb_target_group" "grocery_shop_tg" {
  name     = "grocery-shop-tg"
  port     = 5000
  protocol = "HTTP"
  vpc_id   = aws_vpc.grocery_shop_vpc.id

  health_check {
    path                = "/"
    port                = "5000"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}


# Listener: User (Port 80) -> ALB -> Target Group (Port 5000)
resource "aws_lb_listener" "grocery_shop_http" {
  load_balancer_arn = aws_lb.grocery_shop_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.grocery_shop_tg.arn
  }
}