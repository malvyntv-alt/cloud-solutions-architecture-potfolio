locals {
  function_name = "${var.project}-counter"
  app_root      = "Architecture-case-studies/amplify-portfolio-hosting"
}
module "database" {
  source              = "../../modules/database"
  name                = "${var.project}-views"
  deletion_protection = var.protect_counter_data
}
module "iam" {
  source        = "../../modules/iam"
  name          = "${var.project}-counter"
  table_arn     = module.database.arn
  function_name = local.function_name
  region        = var.region
}
module "api" {
  source          = "../../modules/api"
  name            = "${var.project}-counter"
  function_name   = local.function_name
  role_arn        = module.iam.role_arn
  table_name      = module.database.name
  lambda_zip      = "${path.module}/../../../build/counter.zip"
  allowed_origins = concat(["https://${var.domain_name}", "https://www.${var.domain_name}"], var.additional_allowed_origins)
  depends_on      = [module.iam]
}
module "hosting" {
  source            = "../../modules/hosting"
  name              = var.project
  repository_url    = var.repository_url
  branch_name       = var.branch_name
  app_root          = local.app_root
  api_url           = module.api.endpoint
  domain_name       = var.domain_name
  existing_app_id   = var.amplify_app_id
  enable_auto_build = var.enable_auto_build
}
module "domain" {
  source             = "../../modules/domain"
  enabled            = var.enable_custom_domain
  app_id             = module.hosting.app_id
  branch_name        = module.hosting.branch_name
  domain_name        = var.domain_name
  manage_dns_records = var.manage_dns_records
  hosted_zone_id     = var.hosted_zone_id
}
module "monitoring" {
  source             = "../../modules/monitoring"
  name               = var.project
  region             = var.region
  function_name      = module.api.function_name
  api_id             = module.api.api_id
  table_name         = module.database.name
  alarm_email        = var.alarm_email
  monthly_budget_usd = var.monthly_budget_usd
}
