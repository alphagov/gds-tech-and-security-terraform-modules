# metric
resource "aws_cloudwatch_metric_alarm" "this" {
  count               = var.type == "metric" ? 1 : 0
  alarm_name          = var.alarm_name
  comparison_operator = var.comparison_operator
  evaluation_periods  = var.evaluation_periods
  metric_name         = var.metric_name
  namespace           = var.namespace
  period              = var.period
  statistic           = var.statistic
  threshold           = var.threshold
  alarm_description   = var.alarm_description
  alarm_actions       = [aws_sns_topic.this.arn]
  treat_missing_data  = var.treat_missing_data

  dimensions = var.dimensions != null ? var.dimensions : (
    var.dimension_name != null ? { (var.dimension_name) = var.dimension_value } : null
  )

  tags = {
    Name        = var.alarm_name
    environment = var.environment
    Owner       = var.owner_tag
    Terraform   = "true"
  }
}

# eventbridge
resource "aws_cloudwatch_event_rule" "this" {
  count         = var.type == "eventbridge" ? 1 : 0
  name          = var.alarm_name
  description   = var.alarm_description
  event_pattern = jsonencode(var.event_pattern)
  tags = {
    Name        = var.alarm_name
    environment = var.environment
    Owner       = var.owner_tag
    Terraform   = "true"
  }
}

resource "aws_cloudwatch_event_target" "sns" {
  count     = var.type == "eventbridge" ? 1 : 0
  rule      = aws_cloudwatch_event_rule.this[0].name
  target_id = "SendToSNS"
  arn       = aws_sns_topic.this.arn

  input_transformer {
    input_paths    = var.input_paths
    input_template = var.input_template
  }
}

# codestar (ci)
resource "aws_codestarnotifications_notification_rule" "this" {
  for_each = var.type == "codestar" ? { for c in var.notification_rules : c.pipeline_name => c } : {}

  name           = each.key
  resource       = each.value.pipeline_arn
  event_type_ids = each.value.event_type_ids
  detail_type    = "BASIC"
  status         = each.value.status

  target {
    type    = "SNS"
    address = aws_sns_topic.this.arn
  }
}
