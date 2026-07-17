variable "environment" {
  description = "Environment name, used for naming resources"
  type        = string
}

variable "lambda_role_arn" {
  description = "IAM role ARN Lambda functions will execute as"
  type        = string
}