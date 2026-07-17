resource "aws_sns_topic" "chatopsbot_alerts" {
  name = "chatopsbot-alerts-${var.environment}"
}

# AWS Chatbot Slack channel configuration
resource "aws_chatbot_slack_channel_configuration" "chatopsbot" {
  configuration_name = "chatopsbot-${var.environment}"
  iam_role_arn       = aws_iam_role.chatbot_role.arn
  slack_channel_id   = var.slack_channel_id
  slack_team_id      = var.slack_workspace_id
  sns_topic_arns     = [aws_sns_topic.chatopsbot_alerts.arn]

  logging_level = "ERROR"
}

data "aws_iam_policy_document" "chatbot_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["chatbot.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "chatbot_role" {
  name               = "chatopsbot-chatbot-role-${var.environment}"
  assume_role_policy = data.aws_iam_policy_document.chatbot_assume_role.json
}

resource "aws_iam_role_policy_attachment" "chatbot_readonly" {
  role       = aws_iam_role.chatbot_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSResourceExplorerReadOnlyAccess"
}

data "aws_iam_policy_document" "chatbot_invoke_lambda" {
  statement {
    actions   = ["lambda:InvokeFunction"]
    resources = ["arn:aws:lambda:*:*:function:chatopsbot-*"]
  }
}

resource "aws_iam_policy" "chatbot_invoke_lambda" {
  name   = "chatopsbot-chatbot-invoke-lambda-${var.environment}"
  policy = data.aws_iam_policy_document.chatbot_invoke_lambda.json
}

resource "aws_iam_role_policy_attachment" "chatbot_invoke_lambda_attach" {
  role       = aws_iam_role.chatbot_role.name
  policy_arn = aws_iam_policy.chatbot_invoke_lambda.arn
}

data "aws_iam_policy_document" "chatbot_slack_commands" {
  statement {
    sid       = "AllowLambdaGetDetails"
    actions   = ["lambda:GetFunction"]
    resources = ["arn:aws:lambda:*:*:function:chatopsbot-*"]
  }

  statement {
    sid = "AllowCloudWatchAndLogs"
    actions = [
      "cloudwatch:DescribeAlarms",
      "logs:FilterLogEvents"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "chatbot_slack_commands" {
  name   = "chatopsbot-chatbot-slack-commands-${var.environment}"
  role   = aws_iam_role.chatbot_role.id
  policy = data.aws_iam_policy_document.chatbot_slack_commands.json
}