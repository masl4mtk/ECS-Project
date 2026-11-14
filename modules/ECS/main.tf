locals {

  services = toset(["frontend", "api", "worker"])

  environment = [
    { name = "DB_Host", value = var.db_address },
    { name = "DB_HOST", value = var.db_address },
    { name = "DB_NAME", value = var.db_name },
    { name = "DB_USER", value = var.db_username },
    { name = "DB_SSL", value = "true" },
    { name = "AWS_REGION", value = var.aws_region },
    { name = "SQS_QUEUE_URL", value = var.sqs_queue_url },
  ]

  secrets = [
    { name = "DB_PASSWORD", valueFrom = var.db_secret_arn },
  ]
}


