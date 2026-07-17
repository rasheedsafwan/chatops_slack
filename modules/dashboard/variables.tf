variable "environment" {
  description = "Environment name, used for naming resources"
  type        = string
}

variable "status_lambda_arn" {
  description = "ARN of the status Lambda, invoked by API Gateway for dashboard data"
  type        = string
}

variable "status_lambda_name" {
  description = "Function name of the status Lambda (needed for the resource-based policy)"
  type        = string
}