output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = aws_ecs_cluster.main.name
}

output "ecs_service_name" {
  description = "ECS service names"
  value = {
    frontend = aws_ecs_service.frontend.name
    api      = aws_ecs_service.api.name
    worker   = aws_ecs_service.worker.name
  }
}