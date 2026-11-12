output "queue_url" {
  value = aws_sqs_queue.order_queue.url
}

output "queue_arn" {
  value = aws_sqs_queue.order_queue.arn
}

output "deadletter_queue_url" {
  value = aws_sqs_queue.order-queue-deadletter.url
}

output "deadletter_queue_arn" {
  value = aws_sqs_queue.order-queue-deadletter.arn
}