output "dashboard_url" {
  description = "Public URL of the ChatOpsBot dashboard"
  value       = "https://${module.dashboard.cloudfront_domain_name}"
}

output "dashboard_api_endpoint" {
  description = "Paste this into src/dashboard/app.js's API_ENDPOINT constant"
  value       = module.dashboard.api_endpoint
}