resource "aws_iam_role_policy" "chatbot_sns_access" {
  name = "ChatbotSNSAccess-${var.alarm_name}"
  role = var.chatbot_role_id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "sns:GetTopicAttributes",
          "sns:Subscribe",
          "sns:Unsubscribe",
          "sns:Receive"
        ],
        Resource = [aws_sns_topic.this.arn]
      }
    ]
  })
}

data "aws_iam_policy_document" "sns_policy" {
  dynamic "statement" {
    for_each = var.type == "metric" ? [1] : []
    content {
      sid    = "AllowCloudWatchPublish"
      effect = "Allow"
      principals {
        type        = "Service"
        identifiers = ["cloudwatch.amazonaws.com"]
      }
      actions   = ["sns:Publish"]
      resources = [aws_sns_topic.this.arn]
    }
  }

  dynamic "statement" {
    for_each = var.type == "eventbridge" ? [1] : []
    content {
      sid    = "AllowEventBridgePublish"
      effect = "Allow"
      principals {
        type        = "Service"
        identifiers = ["events.amazonaws.com"]
      }
      actions   = ["sns:Publish"]
      resources = [aws_sns_topic.this.arn]
    }
  }

  statement {
    sid    = "AllowChatbotAccess"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["chatbot.amazonaws.com"]
    }
    actions   = ["sns:Subscribe", "sns:Receive", "sns:GetTopicAttributes"]
    resources = [aws_sns_topic.this.arn]
  }
}
