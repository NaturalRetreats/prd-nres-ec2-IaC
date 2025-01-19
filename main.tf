# This code is only for Production environment. This code will create EC2 instances,
# load balancer target group, listeners in an existing VPC and subnets.

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.74.0"
    }
  }

backend "s3" {
    bucket         = "prd-nres-ec2-tfstate"
    key            = "prd-nres-ec2-tfstate-fld/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "prd-ec2-tf-state-nres-dyndb"
  }
}

data "aws_vpc" "prd_vpc" {
  id = "vpc-0a7fa0c2492fdae89" # nres
}

data "aws_subnets" "prd-listner-subnet-az1a" {
  filter {
    name   = "cidr-block"
    values = ["172.31.112.0/20"]
  }
}

data "aws_subnets" "prd-listner-subnet-az1b" {
  filter {
    name   = "cidr-block"
    values = ["172.31.128.0/20"]
  }
}

resource "aws_launch_template" "prd_nres_ec2_lt" {
  name_prefix   = "prd-nres-ec2-launch-template"
  image_id      = var.ami
  instance_type = "t3.medium"

  network_interfaces {
    security_groups = [data.aws_security_group.prd-ec2-sg.id]
  }

  key_name = var.key_pair

  tags = merge(
    local.common_tags,
    {
      Name = "prd-nres-ec2-launch-template"
    }
  )
}

resource "aws_autoscaling_group" "prd_nres_asg" {
  name             = "prd-nres-asg"
  desired_capacity = 2
  max_size         = 4
  min_size         = 2
  target_group_arns = [
    aws_lb_target_group.prd-nres-ec2-8443-tg.arn,
    aws_lb_target_group.prd-nres-ec2-7443-tg.arn
  ]
  vpc_zone_identifier = [
    data.aws_subnets.prd-listner-subnet-az1a.ids[0],
    data.aws_subnets.prd-listner-subnet-az1b.ids[0]
  ]

  launch_template {
    id      = aws_launch_template.prd_nres_ec2_lt.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "prd-nres-ec2"
    propagate_at_launch = true
  }

  dynamic "tag" {
    for_each = local.common_tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
}

resource "aws_lb_target_group" "prd-nres-ec2-8443-tg" {
  name        = "prd-nres-ec2-8443-tg"
  port        = 8443
  protocol    = "HTTPS"
  vpc_id      = data.aws_vpc.prd_vpc.id
  target_type = "instance"
  tags = merge(
    local.common_tags,
    {
      Name = "prd-nres-ec2-8443-tg"
    }
  )

  health_check {
    path                = "/" # Adjust based on your application
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    protocol            = "HTTPS"
    port                = 8443
  }
}

resource "aws_lb_target_group" "prd-nres-ec2-7443-tg" {
  name        = "prd-nres-ec2-7443-tg"
  port        = 7443
  protocol    = "HTTPS"
  vpc_id      = data.aws_vpc.prd_vpc.id
  target_type = "instance"
  tags = merge(
    local.common_tags,
    {
      Name = "prd-nres-ec2-7443-tg"
    }
  )

  health_check {
    path                = "/" # Adjust based on your application
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    protocol            = "HTTPS"
    port                = 7443
  }
}

data "aws_lb" "prd-nres-alb" {
  name = "prd-nres-alb"
}

data "aws_acm_certificate" "prd-nres-ec2-cert" {
  domain = "*.naturalretreats.com"
  statuses = ["ISSUED"]
  most_recent = true
}

resource "aws_lb_listener" "prd-nres-alb-443-listener" {
  load_balancer_arn = data.aws_lb.prd-nres-alb.arn
  port              = 443
  protocol          = "HTTPS"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.prd-nres-ec2-8443-tg.arn
  }
  ssl_policy      = "ELBSecurityPolicy-TLS13-1-2-Res-2021-06"
  certificate_arn = data.aws_acm_certificate.prd-nres-ec2-cert.arn
}

resource "aws_lb_listener" "prd-nres-alb-7443-listener" {
  load_balancer_arn = data.aws_lb.prd-nres-alb.arn
  port              = 7443
  protocol          = "HTTPS"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.prd-nres-ec2-7443-tg.arn
  }
  ssl_policy      = "ELBSecurityPolicy-TLS13-1-2-Res-2021-06"
  certificate_arn = data.aws_acm_certificate.prd-nres-ec2-cert.arn
}

resource "aws_lb_listener" "prd-nres-alb-80-listener" {
  load_balancer_arn = data.aws_lb.prd-nres-alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

data "aws_security_group" "prd-ec2-sg" {
  name = "prd-ec2-sg" # replace with your existing security group name
}

// Scale up policy
resource "aws_autoscaling_policy" "scale_up" {
  name                   = "scale_up"
  autoscaling_group_name = aws_autoscaling_group.prd_nres_asg.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = 1
  cooldown               = 300
}

// Scale down policy
resource "aws_autoscaling_policy" "scale_down" {
  name                   = "scale_down"
  autoscaling_group_name = aws_autoscaling_group.prd_nres_asg.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = -1
  cooldown               = 300
}

// CloudWatch alarm to trigger scale up
resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "cpu-utilization-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "Scale up if CPU > 80% for 10 minutes"
  alarm_actions       = [aws_autoscaling_policy.scale_up.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.prd_nres_asg.name
  }
}

// CloudWatch alarm to trigger scale down
resource "aws_cloudwatch_metric_alarm" "cpu_low" {
  alarm_name          = "cpu-utilization-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "40"
  alarm_description   = "Scale down if CPU < 40% for 10 minutes"
  alarm_actions       = [aws_autoscaling_policy.scale_down.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.prd_nres_asg.name
  }
}
