variable "environment" {
  description = "Environment name, used for naming/tagging resources"
  type        = string
}

variable "sns_topic_arn" {
  description = "ARN of the SNS topic Lambdas are allowed to publish to"
  type        = string
}