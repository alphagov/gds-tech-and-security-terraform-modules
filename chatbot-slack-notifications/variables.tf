variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "type" {
  description = "Type: 'metric' or 'eventbridge'. "
  type        = string
  validation {
    condition     = contains(["metric", "eventbridge"], var.type)
    error_message = "type must be either metric or eventbridge"
  }
}

variable "alarm_name" {
  description = "Name of the CloudWatch alarm"
  type        = string
  default     = null
}

variable "alarm_description" {
  description = "Description of the CloudWatch alarm"
  type        = string
  default     = null
}

# chatbot role
variable "chatbot_role_id" {
  type = string
}

# metrics
variable "metric_name" {
  description = "CloudWatch metric name (e.g. Errors, CPUUtilization)"
  type        = string
  default     = null
}

variable "namespace" {
  description = "CloudWatch metric namespace (e.g. AWS/Lambda, AWS/EC2)"
  type        = string
  default     = null
}

variable "dimension_value" {
  description = "The dimension value for the CloudWatch metric (e.g. function name, instance ID)"
  type        = string
  default     = null
}

variable "dimension_name" {
  description = "The dimension key for the CloudWatch metric (e.g. FunctionName, InstanceId, DBInstanceIdentifier)"
  type        = string
  default     = null
}

variable "comparison_operator" {
  description = "Comparison operator for the alarm"
  type        = string
  default     = "GreaterThanThreshold"
}

variable "threshold" {
  description = "Alarm threshold value"
  type        = number
  default     = 0
}

variable "period" {
  description = "Alarm evaluation period in seconds"
  type        = number
  default     = 300
}

variable "evaluation_periods" {
  description = "Number of periods to evaluate"
  type        = number
  default     = 1
}

variable "statistic" {
  description = "Metric statistic (e.g. Sum, Average, Maximum)"
  type        = string
  default     = "Sum"
}

variable "treat_missing_data" {
  description = "Sets how the metric alarm handles missing data points (missing, ignore, breaching, and notBreaching)"
  type        = string
  default     = "missing"
}

# eventbridge
variable "event_pattern" {
  description = "EventBridge event pattern (event trigger)"
  default     = null
  type        = any
}

variable "input_paths" {
  description = "Input transformer path mappings (select data)"
  type        = map(string)
  default     = null
}

variable "input_template" {
  description = "Input transformer template string (message)"
  type        = string
  default     = null
}
