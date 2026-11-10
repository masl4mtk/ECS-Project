output "queue_url" {
  value = aws_sqs_queue.main_queue.id
}

output "queue_arn" {
  value = aws_sqs_queue.main_queue.arn
}

output "deadletter_queue_url" {
  value = aws_sqs_queue.deadletter_queue.id
}

output "deadletter_queue_arn" {
  value = aws_sqs_queue.deadletter_queue.arn
}