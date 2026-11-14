variable "aws_region" {
  description = "AWS region, used for the log configuration and the app's AWS_REGION"
  type        = string
}

variable "image_tag" {
  description = "Tag of the images in ECR (the commit SHA from the pipeline)"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnets where the tasks run"
  type        = list(string)
}

variable "frontend_api_sg_id" {
  description = "Security group for the frontend and API tasks"
  type        = string
}

variable "worker_sg_id" {
  description = "Security group for the worker tasks"
  type        = string
}

variable "ecr_repository_urls" {
  description = "Map of service name to ECR repository URL"
  type        = map(string)
}

variable "db_address" {
  description = "RDS hostname (without the port)"
  type        = string
}

variable "db_name" {
  description = "Database name"
  type        = string
}

variable "db_username" {
  description = "Database master username"
  type        = string
}

variable "db_secret_arn" {
  description = "ARN of the Secrets Manager secret holding the DB password"
  type        = string
}

variable "sqs_queue_url" {
  description = "URL of the orders queue"
  type        = string
}

variable "execution_role_arn" {
  description = "Shared task execution role"
  type        = string
}

variable "task_role_arns" {
  description = "Map of service name to task role ARN (api, worker)"
  type        = map(string)
}

variable "frontend_target_group_arn" {
  description = "ALB target group for the frontend tasks"
  type        = string
}

variable "api_target_group_arn" {
  description = "ALB target group for the API tasks"
  type        = string
}

variable "desired_count" {
  description = "Number of copies of the frontend and API tasks"
  type        = number
  default     = 2
}

variable "worker_desired_count" {
  description = "Number of copies of the worker task"
  type        = number
  default     = 1
}
