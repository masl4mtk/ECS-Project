output "db_address" {
  value = aws_db_instance.postgres.address
}

output "db_secret_arn" {
  value = aws_secretsmanager_secret.db_secret.arn
}

output "db_name" {
  value = aws_db_instance.postgres.db_name
}

output "db_username" {
  value = aws_db_instance.postgres.username
}