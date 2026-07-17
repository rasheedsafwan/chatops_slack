variable "environment" {
  description = "Environment name, used for naming resources"
  type        = string
}

variable "sns_topic_arn" {
  description = "ARN of the SNS topic to notify when the alarm fires"
  type        = string
}

variable "monitored_function_name" {
  description = "Name of the Lambda function this alarm watches for errors"
  type        = string
}