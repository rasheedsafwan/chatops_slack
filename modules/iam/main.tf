# Trust policy
data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda_exec_role" {
  name               = "chatopsbot-lambda-role-${var.environment}"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

# Basic logging permissions to write to CloudWatch Logs
resource "aws_iam_role_policy_attachment" "lambda_basic_logs" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Scoped permission: this Lambda can ONLY manage Lambda functions matching this project's naming
data "aws_iam_policy_document" "lambda_remediation_permissions" {
  statement {
    actions = [
      "lambda:GetFunction",
      "lambda:UpdateFunctionConfiguration",
      "lambda:ListVersionsByFunction"
    ]
    resources = ["arn:aws:lambda:*:*:function:chatopsbot-*"]
  }

  statement {
    actions   = ["cloudwatch:DescribeAlarms"]
    resources = ["*"]
  }

  statement {
    actions   = ["logs:FilterLogEvents", "logs:GetLogEvents"]
    resources = ["arn:aws:logs:*:*:log-group:/aws/lambda/chatopsbot-*"]
  }

  statement {
    actions   = ["sns:Publish"]
    resources = [var.sns_topic_arn]
  }
}

resource "aws_iam_policy" "lambda_remediation" {
  name   = "chatopsbot-remediation-policy-${var.environment}"
  policy = data.aws_iam_policy_document.lambda_remediation_permissions.json
}

resource "aws_iam_role_policy_attachment" "lambda_remediation_attach" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = aws_iam_policy.lambda_remediation.arn
}