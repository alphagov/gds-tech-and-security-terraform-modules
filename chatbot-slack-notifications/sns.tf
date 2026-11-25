#trivy:ignore:AWS-0095
resource "aws_sns_topic" "this" {
  #checkov:skip=CKV_AWS_26:Cloudwatch Alarms needs a user-managed key to publish to encrypted topics
  name = var.alarm_name

  tags = {
    Name        = var.alarm_name
    environment = var.environment
    Owner       = var.owner_tag
    Terraform   = "true"
  }
}

resource "aws_sns_topic_policy" "this" {
  arn    = aws_sns_topic.this.arn
  policy = data.aws_iam_policy_document.sns_policy.json
}
