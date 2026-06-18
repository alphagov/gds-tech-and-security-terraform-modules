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
  dimensions          = { (var.dimension_name) = var.dimension_value }
  tags = {
    Name        = var.alarm_name
    environment = var.environment
    Owner       = "engineering-enablement"
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
    Owner       = "engineering-enablement"
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
