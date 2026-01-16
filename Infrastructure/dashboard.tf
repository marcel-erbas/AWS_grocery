resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "Grocery-Shop-Infrastructure"

  dashboard_body = jsonencode({
    widgets = [
      # ASG CPU Load
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/EC2", "CPUUtilization", "AutoScalingGroupName", "${aws_autoscaling_group.grocery_shop_asg.name}"]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "ASG Server CPU (%)"
        }
      },

      # RDS CPU Load
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", "${aws_db_instance.postgres.identifier}"]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "RDS Database CPU (%)"
        }
      },
      # Healthy Host Count 
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "HealthyHostCount", "TargetGroup", "${aws_lb_target_group.grocery_shop_tg.arn_suffix}", "LoadBalancer", "${aws_lb.grocery_shop_alb.arn_suffix}"]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "Active Instances (Healthy)"
        }
      },

      # Request Count
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", "${aws_lb.grocery_shop_alb.arn_suffix}"]
          ]
          period = 300
          stat   = "Sum"
          region = var.aws_region
          title  = "Total Web Requests"
        }
      }
    ]
  })
}