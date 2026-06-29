# Chatbot Slack Notifications

This module can be used to support the following alarms and route to slack.

* cloudwatch metric
* cloudwatch eventbridge
* codestar (ci) notifications

It is to be used at an account level, so you would need the following setup in the account folder. This example shows how to add the same alarm to production and sandbox.

## Create your alerts (eventbridge, metric, codestar)

The provider is optional, if not specified it will use default region.

eg

```terraform/account-name/alarms.tf```

```hcl
# metric
module "lambda-errors" {
  source          = "../modules/chatbot-slack-notifications"
  type            = "metric"
  environment     = var.environment
  chatbot_role_id = module.chatbot-role.id

  alarm_name          = "lambda-errors"
  alarm_description   = "The account bootstrap lambda has failed"
  namespace           = "AWS/Lambda"
  metric_name         = "Errors"
  statistic           = "Sum"
  comparison_operator = "GreaterThanThreshold"
  threshold           = 0
  period              = 300
  evaluation_periods  = 1
  treat_missing_data  = "notBreaching"
  dimension_name      = "FunctionName"
  dimension_value     = "ExampleLambda"
}

# event bridge
module "service_linked_role_alarm" {
  source          = "../../../modules/chatbot-slack-notifications"
  type            = "eventbridge"
  environment     = var.environment
  chatbot_role_id = module.chatbot-role.id

  providers = {
    aws = aws.us_east_1
  }

  alarm_name        = "service-linked-role-added"
  alarm_description = "A Service Linked Role has been added to the ci member account."

  event_pattern = {
    source      = ["aws.iam"]
    detail-type = ["AWS API Call via CloudTrail"]
    detail = {
      eventSource = ["iam.amazonaws.com"]
      eventName   = ["CreateServiceLinkedRole"]
    }
  }

  input_paths = {
    time         = "$.time"
    user         = "$.detail.userIdentity.arn"
    service_name = "$.detail.requestParameters.aWSServiceName"
    role_name    = "$.detail.responseElements.role.roleName"
  }

  input_template = <<-EOT
    {
      "version": "1.0",
      "source": "custom",
      "content": {
        "title": "Service Linked Role Created in the Sandbox CI Account",
        "description": "*Role:* `<role_name>`\n*Service:* `<service_name>`\n*Created by:* `<user>`\n*Time:* <time>\n*Runbook:* https://github.com/"
      }
    }
  EOT
}

# codestar (ci)
module "codepipeline_notifications" {
  source            = "../../modules/chatbot-slack-notifications"
  type              = "codestar"
  environment       = var.environment
  chatbot_role_id   = module.chatbot-role.id
  alarm_name        = "code-pipeline-errors"
  alarm_description = "Code piepline errors on ${var.environment}"

  notification_rules = [
    {
      pipeline_name = "account-vending-pipeline-${var.environment}"
      pipeline_arn  = module.account_vending_pipeline.codepipeline_arn
      event_type_ids = [
        "codepipeline-pipeline-stage-execution-failed",
        "codepipeline-pipeline-manual-approval-needed",
      ]
      status = var.codepipeline_notifications_status
    },
    {
      pipeline_name = "gds-org-deployment-pipeline-${var.environment}"
      pipeline_arn  = module.deployment_pipeline.codepipeline_arn
      event_type_ids = [
        "codepipeline-pipeline-stage-execution-failed",
        "codepipeline-pipeline-manual-approval-needed",
      ]
      status = var.codepipeline_notifications_status
    }
  ]
}
```

## Slack Config

> [!NOTE]
> You can find the slack IDs by opening the slack channel in the browser - [gds.slack.com](https://gds.slack.com)
>
> `https://app.slack.com/client/WORKSPACE-ID/CHANNEL-ID`
>
> The workspace ID is first, and the channel ID is second. You can also find the channel ID by clicking the 3 dots menu at the top right and then channel details.
>
> The account needs the slack workspace to be [configured for chatbot](https://github.com/alphagov/engineering-enablement/wiki/Runbook%3A-Configure-a-Slack-workspace-for-AWS-Chatbot) - this is only need once per account.

You will have one `aws_chatbot_slack_channel_configuration` resource per slack channel with a list of alert `sns_topic_arns`. There is
also a module call to create the chatbot role per env.

eg

```terraform/my-account/alarms-slack.tf```

```hcl
module "chatbot-role" {
  source = "../modules/chatbot-slack-notifications-iam"
}

resource "aws_chatbot_slack_channel_configuration" "account-slack-channel-name" {
  configuration_name = "account-slack-channel-name"
  slack_channel_id   = "XXXXXXXX" # slack-channel-name
  slack_team_id      = "TXXXXXXX"
  sns_topic_arns = [
    module.lambda-errors.sns_topic_arn,
    module.service_linked_role_alarm.sns_topic_arn,
    module.codestar_notifications.sns_topic_arn
  ]
  iam_role_arn  = module.chatbot-role.arn
  logging_level = "INFO"

  tags = {
    Name        = "account-slack-channel-name"
    environment = var.environment
    Owner       = "engineering-enablement"
    Terraform   = "true"
  }
}
```

## Adding Alarms Depenant on Environment

### Adding alarms to just one environment

You can use locals in `alarms-slack.tf`, please keep reading for full context and examples.

#### Alarms

```terraform/my-account/alarms.tf```

Apply your alarm to just prod, eg.

```hcl
module "lambda-errors" {
  count = var.environment == "production" ? 1 : 0
  ...
```

#### Alarms Slack

```terraform/my-account/alarms-slack.tf```

It is ok to have a `aws_chatbot_slack_channel_configuration` with an empty `sns_topic_arns` list. The resource is created but with no alarm routing. You may have an alarm only on prod and only on sanbox, the `locals` can be edited accordingly, eg

```hcl
locals {
  sns_topic_arns_by_env = {
    production = compact([
      try(module.lambda-errors[0].sns_topic_arn, null),         # only prod
    ])
    sandbox = compact([
      try(module.another-lambda-errors[0].sns_topic_arn, null),  # only sandbox
    ])
  }
  sns_topic_arns = lookup(local.sns_topic_arns_by_env, var.environment, [])
}
```

In the example below we only have prod:

```hcl
locals {
  sns_topic_arns_by_env = {
    production = compact([
      try(module.lambda-errors[0].sns_topic_arn, null),       # only prod
    ])
  }
  sns_topic_arns = lookup(local.sns_topic_arns_by_env, var.environment, [])
}

resource "aws_chatbot_slack_channel_configuration" "account-slack-channel-name" {
  configuration_name = "account-slack-channel-name"
  slack_channel_id   = "xxxx" # gds-xxxx
  slack_team_id      = "xxxxx"
  sns_topic_arns     = local.sns_topic_arns     # only prod, sandbox is empty
  iam_role_arn       = module.chatbot-role.arn
  logging_level      = "INFO"

  tags = {
    Name        = "account-slack-channel-name"
    environment = var.environment
    Owner       = "engineering-enablement"
    Terraform   = "true"
  }
}
```

### Adding alarms on both prod and sandbox, and some env dependent ones

#### Alarms

```terraform/my-account/alarms.tf```

Apply your alarm to just prod, eg.

```hcl
module "lambda-errors" {
  count  = var.environment == "production" ? 1 : 0
  source = "../../modules/chatbot-slack-notifications"
...
```

An alarm applied to both sandbox and prod

```hcl
module "codepipeline_notifications" {
  source = "../../modules/chatbot-slack-notifications"
...
```

#### Alarms Slack

```terraform/my-account/alarms-slack.tf```

```hcl
locals {
  sns_topic_arns_by_env = {
    production = compact([
      try(module.lambda-errors[0].sns_topic_arn, null),               # only prod
    ])
  }
  sns_topic_arns = lookup(local.sns_topic_arns_by_env, var.environment, [])
}


resource "aws_chatbot_slack_channel_configuration" "account-slack-channel-name" {
  configuration_name = "account-slack-channel-name"
  slack_channel_id   = "xxxx" # gds-xxxx
  slack_team_id      = "xxxxx"
  sns_topic_arns = concat(
    local.sns_topic_arns,                                    # env dependent
    [module.codepipeline_notifications.sns_topic_arn],       # both envs
  )
  iam_role_arn       = module.chatbot-role.arn
  logging_level      = "INFO"

  tags = {
    Name        = "account-slack-channel-name"
    environment = var.environment
    Owner       = "engineering-enablement"
    Terraform   = "true"
  }
}
```
