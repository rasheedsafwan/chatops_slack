variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "slack_workspace_id" {
  description = "Slack workspace ID (from AWS Chatbot console, first-time manual auth required)"
  type        = string
}

variable "slack_channel_id" {
  description = "Slack channel ID to post alerts into"
  type        = string
}

variable "environment" {
  description = "Environment name, used for tagging/naming"
  type        = string
  default     = "dev"
}