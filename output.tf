output "asg_name" {
  description = "Name of the Auto Scaling Group"
  value       = aws_autoscaling_group.prd_nres_asg.name
}

output "asg_arn" {
  description = "ARN of the Auto Scaling Group"
  value       = aws_autoscaling_group.prd_nres_asg.arn
}

output "lb_arn" {
  description = "ARN of LB"
  value       = data.aws_lb.prd-nres-alb.arn
}

output "lb_dns_name" {
  description = "DNS name of LB"
  value       = data.aws_lb.prd-nres-alb.dns_name
}

output "lb_listener_8443_arn" {
  description = "ARN of LB listener for port 8443"
  value       = aws_lb_listener.prd-nres-alb-443-listener.arn
}

output "lb_listener_7443_arn" {
  description = "ARN of LB listener for port 7443"
  value       = aws_lb_listener.prd-nres-alb-7443-listener.arn
}



