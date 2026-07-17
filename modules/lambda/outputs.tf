output "restart_function_name" {
  value = aws_lambda_function.restart_function.function_name
}

output "restart_function_arn" {
  value = aws_lambda_function.restart_function.arn
}

output "check_logs_function_name" {
  value = aws_lambda_function.check_logs.function_name
}

output "status_function_name" {
  value = aws_lambda_function.status.function_name
}

output "status_function_arn" {
  value = aws_lambda_function.status.arn
}