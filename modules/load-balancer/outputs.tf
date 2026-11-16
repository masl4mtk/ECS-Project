output "alb_arn" {
  description = "ARN of the application of the load balancer"
  value       = aws_lb.ecs-lb.arn
}

output "frontend_target_group_arn" {
  description = "ARN of the frontend target group"
  value       = aws_lb_target_group.frontend_tg.arn
}

output "api_target_group_arn" {
  description = "ARN of the api target group"
  value       = aws_lb_target_group.api_tg.arn
}

output "zone_id" {
  description = "Zone ID for ALB"
  value       = aws_lb.ecs-lb.zone_id
}

output "alb_dns_name" {
  description = "DNS name of ALB"
  value       = aws_lb.ecs-lb.dns_name
}
