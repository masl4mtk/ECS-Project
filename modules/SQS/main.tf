resource "aws_sqs_queue" "order_queue" {
  name                      = "orderflow-main-queue"
  delay_seconds             = 90
  max_message_size          = 2048
  message_retention_seconds = 86400
  receive_wait_time_seconds = 10
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.order-queue-deadletter.arn
    maxReceiveCount     = 3
  })

  tags = {
    Environment = "production"
  }
}

resource "aws_sqs_queue" "order-queue-deadletter" {
  name                      = "orderflow-queue-deadletter"
  }

