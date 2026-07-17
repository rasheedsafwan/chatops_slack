variable "environment" {
  description = "Environment name, used for naming resources"
  type        = string
}

variable "slack_workspace_id" {
  description = "Slack workspace (team) ID, obtained after one-time Chatbot OAuth"
  type        = string
}

variable "slack_channel_id" {
  description = "Slack channel ID to post alerts into"
  type        = string
}