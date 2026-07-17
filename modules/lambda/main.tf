data "archive_file" "restart_function_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../../src/lambda/restart_function"
  output_path = "${path.module}/../../build/restart_function.zip"
}

resource "aws_lambda_function" "restart_function" {
  function_name    = "chatopsbot-restart-function-${var.environment}"
  role             = var.lambda_role_arn
  handler          = "handler.handler"
  runtime          = "python3.12"
  filename         = data.archive_file.restart_function_zip.output_path
  source_code_hash = data.archive_file.restart_function_zip.output_base64sha256
  timeout          = 30

  environment {
    variables = {
      ENVIRONMENT = var.environment
    }
  }
}

data "archive_file" "check_logs_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../../src/lambda/check_logs"
  output_path = "${path.module}/../../build/check_logs.zip"
}

resource "aws_lambda_function" "check_logs" {
  function_name    = "chatopsbot-check-logs-${var.environment}"
  role             = var.lambda_role_arn
  handler          = "handler.handler"
  runtime          = "python3.12"
  filename         = data.archive_file.check_logs_zip.output_path
  source_code_hash = data.archive_file.check_logs_zip.output_base64sha256
  timeout          = 15
}

data "archive_file" "status_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../../src/lambda/status"
  output_path = "${path.module}/../../build/status.zip"
}

resource "aws_lambda_function" "status" {
  function_name    = "chatopsbot-status-${var.environment}"
  role             = var.lambda_role_arn
  handler          = "handler.handler"
  runtime          = "python3.12"
  filename         = data.archive_file.status_zip.output_path
  source_code_hash = data.archive_file.status_zip.output_base64sha256
  timeout          = 15
}

