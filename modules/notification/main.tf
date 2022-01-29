resource "aws_sns_topic" "user-response-topic" {
  name                      = var.topic_name
  policy = <<EOF
    {
      "Version": "2012-10-17",
      "Id": "__default_policy_ID",
      "Statement": [
        {
          "Sid": "__default_statement_ID",
          "Effect": "Allow",
          "Principal": {
            "AWS": "*"
          },
          "Action": [
            "SNS:GetTopicAttributes",
            "SNS:SetTopicAttributes",
            "SNS:AddPermission",
            "SNS:RemovePermission",
            "SNS:DeleteTopic",
            "SNS:Subscribe",
            "SNS:ListSubscriptionsByTopic",
            "SNS:Publish"
          ],
          "Resource": "arn:aws:sns:us-east-1:275527036335:${var.topic_name}",
          "Condition": {
            "StringEquals": {
              "AWS:SourceOwner": "275527036335"
            }
          }
        },
        {
          "Sid": "PinpointPublish",
          "Effect": "Allow",
          "Principal": {
            "Service": "mobile.amazonaws.com"
          },
          "Action": "sns:Publish",
          "Resource": "arn:aws:sns:us-east-1:275527036335:${var.topic_name}"
        }
      ]
    }
  EOF
}

// Outputs

resource "aws_ssm_parameter" "topic_arn" {
  name  = "/nevvi/sns/${var.topic_name}/arn"
  type  = "String"
  value = aws_sns_topic.user-response-topic.arn
}
