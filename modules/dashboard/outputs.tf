output "cloudfront_domain_name" {
  description = "Public URL of the dashboard"
  value       = aws_cloudfront_distribution.dashboard.domain_name
}

output "api_endpoint" {
  description = "Invoke URL for the dashboard's status API — paste this into app.js"
  value       = "${aws_apigatewayv2_stage.default.invoke_url}status"
}