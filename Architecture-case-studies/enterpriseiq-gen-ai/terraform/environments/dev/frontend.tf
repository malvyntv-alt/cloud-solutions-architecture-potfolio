variable "enable_frontend_hosting" {
  type        = bool
  default     = false
  description = "Create DEV Amplify static hosting; upload the locally built artifact separately."
  validation {
    condition     = !var.enable_frontend_hosting || var.enable_chat_api
    error_message = "Frontend hosting requires enable_chat_api = true."
  }
}

resource "aws_amplify_app" "frontend" {
  count                    = var.enable_frontend_hosting ? 1 : 0
  name                     = "enterpriseiq-dev"
  platform                 = "WEB"
  enable_branch_auto_build = false
}

resource "aws_amplify_branch" "frontend" {
  count             = var.enable_frontend_hosting ? 1 : 0
  app_id            = aws_amplify_app.frontend[0].id
  branch_name       = "dev"
  stage             = "DEVELOPMENT"
  enable_auto_build = false
}

locals {
  frontend_origin = var.enable_frontend_hosting ? "https://${aws_amplify_branch.frontend[0].branch_name}.${aws_amplify_app.frontend[0].default_domain}" : null
}

output "frontend_hosting" {
  value = var.enable_frontend_hosting ? {
    app_id      = aws_amplify_app.frontend[0].id
    branch_name = aws_amplify_branch.frontend[0].branch_name
    url         = local.frontend_origin
  } : null
}
