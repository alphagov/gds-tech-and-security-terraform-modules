# Chatbot Slack Notifications

This module can be used to create a cloudwatch metric or eventbridge alarm and route to slack.

It is at an account level, so you would need the following setup in the account folder.

1. Create you alerts (eventbridge or metric)

eg

```terraform/tooling/billing/alarms.tf```

```hcl
module "dummy_metric_alarm" {
  count = var.environment == "sandbox" ? 1 : 0

  source              = "../../modules/chatbot-slack-notifications"
  type                = "metric"
  environment         = var.environment
  chatbot_role_id     = module.chatbot-role-sandbox[0].id

  alarm_name          = "test-always-firing-metric"
  alarm_description   = "Test alarm - always fires due to missing data."
  namespace           = "AWS/Lambda"
  metric_name         = "Errors"
  statistic           = "Sum"
  comparison_operator = "GreaterThanThreshold"
  threshold           = 0
  period              = 60
  evaluation_periods  = 1
  treat_missing_data  = "breaching" # for test alert so it will always fire
  dimension_name      = "FunctionName"
  dimension_value     = "this-function-does-not-exist" # for test alert so it will always fire
}

module "dummy_eventbridge_alarm" {
  count = var.environment == "sandbox" ? 1 : 0

  source          = "../../modules/chatbot-slack-notifications"
  type            = "eventbridge"
  environment     = var.environment
  chatbot_role_id = module.chatbot-role-sandbox[0].id

  alarm_name        = "test-always-firing-eventbridge"
  alarm_description = "Test alert - fires on AssumeRole."

  event_pattern = {
    source      = ["aws.sts"]
    detail-type = ["AWS API Call via CloudTrail"]
    detail = {
      eventSource = ["sts.amazonaws.com"]
      eventName   = ["AssumeRole"]
    }
  }

  input_paths = {
    time      = "$.time"
    role_name = "$.detail.requestParameters.roleArn"
    caller    = "$.detail.userIdentity.arn"
  }

  input_template = <<-EOT
    {
      "version": "1.0",
      "source": "custom",
      "content": {
        "title": "Test EventBridge Alert",
        "description": "*Role:* `<role_name>`\n*Caller:* `<caller>`\n*Time:* <time>"
      }
    }
  EOT
}

module "another_dummy_metric_alarm" {
  count = var.environment == "production" ? 1 : 0

  source              = "../../modules/chatbot-slack-notifications"
  type                = "metric"
  environment         = var.environment
  chatbot_role_id     = module.chatbot-role-production[0].id

  alarm_name          = "another-test-always-firing-metric"
  alarm_description   = "Another Test alarm - always fires due to missing data."
  namespace           = "AWS/Lambda"
  metric_name         = "Errors"
  statistic           = "Sum"
  comparison_operator = "GreaterThanThreshold"
  threshold           = 0
  period              = 60
  evaluation_periods  = 1
  treat_missing_data  = "breaching" # for test alert so it will always fire
  dimension_name      = "FunctionName"
  dimension_value     = "this-function-does-not-exist" # for test alert so it will always fire
}
```

2. Slack Config

You will have a prod and sandbox `aws_chatbot_slack_channel_configuration` resource per slack channel with a list of alert `sns_topic_arns`. There is
also a module call to create the chatbot role, this role is only needed per account and env.

eg

```terraform/tooling/billing/alarms-slack.tf```

```hcl
module "chatbot-role-production" {
  count  = var.environment == "production" ? 1 : 0
  source = "../../modules/chatbot-slack-notifications-iam"
}

module "chatbot-role-sandbox" {
  count  = var.environment == "sandbox" ? 1 : 0
  source = "../../modules/chatbot-slack-notifications-iam"
}

resource "aws_chatbot_slack_channel_configuration" "billing-tmp-chatbot-alerts-test-sandbox" {
  count  = var.environment == "sandbox" ? 1 : 0

  configuration_name = "billing-tmp-chatbot-alerts-test"
  slack_channel_id   = "C0BB28JEG92" # tmp-chatbot-alerts-test
  slack_team_id      = "T8GT9416G"
  sns_topic_arns = [
    module.dummy_metric_alarm[0].sns_topic_arn,
    module.dummy_eventbridge_alarm[0].sns_topic_arn,
  ]
  iam_role_arn       =  module.chatbot-role-sandbox[0].arn
  logging_level      = "INFO"

  tags = {
    Name        = "billing-tmp-chatbot-alerts-test"
    environment = var.environment
    Owner       = "engineering-enablement"
    Terraform   = "true"
  }
}

resource "aws_chatbot_slack_channel_configuration" "billing-tmp-chatbot-alerts-test-prod" {
  count  = var.environment == "production" ? 1 : 0

  configuration_name = "billing-tmp-chatbot-alerts-test"
  slack_channel_id   = "C0BB28JEG92" # tmp-chatbot-alerts-test
  slack_team_id      = "T8GT9416G"
  sns_topic_arns = [
    module.another_dummy_metric_alarm[0].sns_topic_arn,
  ]
  iam_role_arn       =  module.chatbot-role-production[0].arn
  logging_level      = "INFO"

  tags = {
    Name        = "billing-tmp-chatbot-alerts-test"
    environment = var.environment
    Owner       = "engineering-enablement"
    Terraform   = "true"
  }
}
```
## Note

The above example will show you how to set it up, but take note:

* The `alarms.tf` creates the alerts and outputs `sns_topic_arn`. The `alarms-slack.tf` has a resoutrce called `aws_chatbot_slack_channel_configuration` that needs the list of alert `sns_topic_arn`.
* The `alarms-slack.tf` - creates the chabot role. This is referenced in both the `alarms.tf` and `alarms-slack.tf`
