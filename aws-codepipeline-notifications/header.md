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
