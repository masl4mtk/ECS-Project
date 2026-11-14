output "execution_role_arn" {
  value = aws_iam_role.ecs_execution.arn
}
output "ecs_task_role_api_arn" {
  value = aws_iam_role.ecs_task_role["api"].arn
}

output "ecs_task_role_worker_arn" {
  value = aws_iam_role.ecs_task_role["worker"].arn
}