resource "random_id" "chatbot_id" {
  byte_length = 8
}

resource "aws_chatbot_slack_channel_configuration" "codepipeline-notifications" {
  configuration_name = "chatbot-config-${random_id.chatbot_id.id}"
  slack_team_id      = var.slack_workspace_id
  slack_channel_id   = var.slack_channel_id
  iam_role_arn       = aws_iam_role.slack_chatbot_role.arn
  logging_level      = "NONE"
}

resource "aws_iam_role" "slack_chatbot_role" {
  name = "chatbot-role-${random_id.chatbot_id.id}"

  assume_role_policy = jsonencode({
    Version = "2008-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "chatbot.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy" "codepipeline_readonly_access" {
  name = "codepipeline_readonly_access"
  role = aws_iam_role.slack_chatbot_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "codepipeline:ListPipelineExecutions",
          "codepipeline:ListActionExecutions",
          "codepipeline:ListActionTypes",
          "codepipeline:ListPipelines",
          "codepipeline:ListTagsForResource",
        ],
        Resource = [for config in var.notification_rules : config.pipeline_arn]
      },
    ]
  })
}

resource "aws_codestarnotifications_notification_rule" "codepipeline_notification" {
  for_each = { for config in var.notification_rules : config.pipeline_name => config }

  status         = each.value.status
  name           = each.key
  resource       = each.value.pipeline_arn
  event_type_ids = each.value.event_type_ids
  detail_type    = "BASIC" # https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-codestarnotifications-notificationrule.html

  target {
    type    = "AWSChatbotSlack"
    address = aws_chatbot_slack_channel_configuration.codepipeline-notifications.chat_configuration_arn
  }
}
