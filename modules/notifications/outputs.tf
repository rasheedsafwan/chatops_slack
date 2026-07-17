output "sns_topic_arn" {
  description = "ARN of the SNS topic other modules publish alerts to"
  value       = aws_sns_topic.chatopsbot_alerts.arn
}
