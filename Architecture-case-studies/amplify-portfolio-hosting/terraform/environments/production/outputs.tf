output "api_endpoint" { value = module.api.endpoint }
output "amplify_app_id" { value = module.hosting.app_id }
output "amplify_preview_url" { value = "https://${var.branch_name}.${module.hosting.default_domain}" }
output "portfolio_url" { value = "https://${var.domain_name}" }
output "custom_domain_enabled" { value = var.enable_custom_domain }
output "certificate_dns_record" { value = module.domain.certificate_dns_record }
output "subdomain_dns_records" { value = module.domain.subdomain_dns_records }
output "dashboard_name" { value = module.monitoring.dashboard_name }
