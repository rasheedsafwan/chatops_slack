resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  alarm_name          = "chatopsbot-lambda-errors-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "Triggers when the monitored Lambda has any errors in a 5-min window"
  alarm_actions       = [var.sns_topic_arn]

  dimensions = {
    FunctionName = var.monitored_function_name
  }
}

# EventBridge rule: catch the CloudWatch alarm state change
resource "aws_cloudwatch_event_rule" "alarm_to_sns" {
  name        = "chatopsbot-alarm-routing-${var.environment}"
  description = "Routes CloudWatch alarm state changes to SNS"

  event_pattern = jsonencode({
    source      = ["aws.cloudwatch"]
    detail-type = ["CloudWatch Alarm State Change"]
    resources   = [aws_cloudwatch_metric_alarm.lambda_errors.arn]
  })
}

resource "aws_cloudwatch_event_target" "alarm_to_sns_target" {
  rule      = aws_cloudwatch_event_rule.alarm_to_sns.name
  target_id = "sns"
  arn       = var.sns_topic_arn
}