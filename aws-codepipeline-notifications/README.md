<!-- BEGIN_TF_DOCS -->
# CodePipeline Notifications

This module uses `Amazon Q` to send notifications to Slack.

## Pre-requisites

In order for the terraform module to work, an initial setup must be performed.

### Set-up App with Slack

Follow *Step 1: Configure a Slack client* on [this guide](https://docs.aws.amazon.com/chatbot/latest/adminguide/slack-setup.html).

Add the Amazon Q app to the Slack workspace, then setup Slack in the AWS Console.

**Note**: If this *AWS setup* gets broken, the configuration must be initialised again using the link above. Then re-apply the terraform, paying special attention to the workspace ID (if changed).

### Add App to the Slack channel

In your slack channel, enter:
```text
/invite @Amazon Q
Choose Invite Them.
```
Once the app is added to the workspace, it will remain in the channel until it's kicked off.

## Configuration

Changes on how the bot displays messages, can be done through the slack bot app preferences.

In your slack channel, enter:
```text
@Amazon Q preferences
```

**Note**: If the terraform resource `aws_chatbot_slack_channel_configuration` is destroyed and re-created, the preferences for the channel will be lost.

Everything else is handled in code.

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 6.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | ~> 3.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 6.0 |
| <a name="provider_random"></a> [random](#provider\_random) | ~> 3.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_chatbot_slack_channel_configuration.codepipeline-notifications](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/chatbot_slack_channel_configuration) | resource |
| [aws_codestarnotifications_notification_rule.codepipeline_notification](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/codestarnotifications_notification_rule) | resource |
| [aws_iam_role.slack_chatbot_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.codepipeline_readonly_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [random_id.chatbot_id](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/id) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_notification_rules"></a> [notification\_rules](#input\_notification\_rules) | List of notification rule configurations | <pre>list(object({<br/>    pipeline_name  = string<br/>    pipeline_arn   = string<br/>    event_type_ids = list(string)<br/>    status         = optional(string, "ENABLED")<br/>  }))</pre> | `[]` | no |
| <a name="input_slack_channel_id"></a> [slack\_channel\_id](#input\_slack\_channel\_id) | Name of the slack channel where to send notifications | `string` | n/a | yes |
| <a name="input_slack_workspace_id"></a> [slack\_workspace\_id](#input\_slack\_workspace\_id) | Slack workspace ID from the Amazon Q chatbot integration | `string` | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
