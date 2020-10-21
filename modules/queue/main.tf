resource "aws_sqs_queue" "queue" {
  name                      = var.queue_name
  message_retention_seconds = 21600 # 6 hours
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dead_letter_queue.arn
    maxReceiveCount     = 4
  })
}

resource "aws_sqs_queue" "dead_letter_queue" {
  name                      = "${var.queue_name}-dlq"
}

// Outputs

resource "aws_ssm_parameter" "queue_arn" {
  name  = "/nevvi/sqs/${var.queue_name}/arn"
  type  = "String"
  value = aws_sqs_queue.queue.arn
}

resource "aws_ssm_parameter" "dead_letter_queue_arn" {
  name  = "/nevvi/sqs/${var.queue_name}-dlq/arn"
  type  = "String"
  value = aws_sqs_queue.dead_letter_queue.arn
}