output "alb_arn" {
    description = "ARN of the application of the load balancer"
    value = aws_lb.ecs-lb.arn
}

output "target_group_arn" {
    description = "ARN of the frontend target group"
    value = aws_lb_target_group.frontend_tg.arn
}