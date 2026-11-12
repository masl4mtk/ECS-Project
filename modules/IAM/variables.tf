variable "sqs_queue_arn" {
  description = "The ARN of the SQS queue to be used by the ECS task role"
  type        = string
}

variable "ecs_secrets_arn" {
  description = "The ARN of the secret in AWS Secrets Manager to be accessed by the ECS task role"
  type        = string
}