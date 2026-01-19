# Launch Template: Defines how new instances should be configured
resource "aws_launch_template" "grocery_shop_lt" {
  name_prefix   = "grocery-shop-template-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = var.ec2_instance_type
  key_name = aws_key_pair.deployer.key_name

  # IAM Instance Profile so the Shop can access S3 (Avatars)
  iam_instance_profile {
    name = aws_iam_instance_profile.grocery_ec2_profile.name
  }

  # Network configuration
  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.allow_ssh_and_shop.id]
  }

  # Dynamic Userdata: Injecting RDS and S3 variables into the script
  user_data = base64encode(templatefile("userdata.sh", {
    aws_region               = var.aws_region
    s3_bucket_name           = var.s3_bucket_name
    rds_endpoint             = aws_db_instance.postgres.address
    rds_master_password      = aws_db_instance.postgres.password
    grocery_username         = var.grocery_username
    grocery_db_name          = var.grocery_db_name
    grocery_user_db_password = var.grocery_user_db_password
  }))

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "grocery-shop-asg-instance"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Auto Scaling Group: Manages the number of instances
resource "aws_autoscaling_group" "grocery_shop_asg" {
  name                = "grocery-shop-asg"
  desired_capacity    = 2
  max_size            = 4
  min_size            = 1
  
  target_group_arns   = [aws_lb_target_group.grocery_shop_tg.arn]
  vpc_zone_identifier = [
    aws_subnet.grocery_shop_public_subnet_1.id,
    aws_subnet.grocery_shop_public_subnet_2.id
  ]

  launch_template {
    id      = aws_launch_template.grocery_shop_lt.id
    version = "$Latest"
  }

  # Ensures the ASG uses ALB health checks instead of just EC2 status
  health_check_type         = "ELB"
  health_check_grace_period = 300 # 5 minutes to allow Docker to start

  tag {
    key                 = "Name"
    value               = "grocery-shop-asg-member"
    propagate_at_launch = true
  }
}


# Scaling Policy: Scale based on average CPU utilization
resource "aws_autoscaling_policy" "cpu_scaling" {
  name                   = "grocery-shop-cpu-scaling"
  autoscaling_group_name = aws_autoscaling_group.grocery_shop_asg.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    # Target 70% CPU usage. If it goes higher, add instances (up to max_size).
    # If it stays significantly lower, remove instances (down to min_size).
    target_value = 70.0
  }
}