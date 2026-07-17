output "lambda_role_arn" {
  description = "ARN of the shared Lambda execution role"
  value       = aws_iam_role.lambda_exec_role.arn
}