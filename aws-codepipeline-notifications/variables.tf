variable "slack_workspace_id" {
  description = "Slack workspace ID from the Amazon Q chatbot integration"
  type        = string
}

variable "slack_channel_id" {
  description = "Name of the slack channel where to send notifications"
  type        = string
}

variable "notification_rules" {
  description = "List of notification rule configurations"
  type = list(object({
    pipeline_name  = string
    pipeline_arn   = string
    event_type_ids = list(string)
    status         = optional(string, "ENABLED")
  }))
  default = []
}
