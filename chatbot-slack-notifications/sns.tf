resource "aws_sns_topic" "this" {
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
