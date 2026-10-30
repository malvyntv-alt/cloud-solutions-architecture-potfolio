locals {
  build_spec = yamlencode({
    version = 1
    applications = [{
      appRoot = var.app_root
      frontend = {
        phases    = { build = { commands = ["node scripts/build-website.mjs"] } }
        artifacts = { baseDirectory = "build/site", files = ["**/*"] }
      }
    }]
  })
}
resource "aws_amplify_app" "this" {
  name                        = var.name
  repository                  = var.repository_url
  platform                    = "WEB"
  enable_auto_branch_creation = false
  enable_branch_auto_build    = var.enable_auto_build
  build_spec                  = local.build_spec
  environment_variables = {
    AMPLIFY_MONOREPO_APP_ROOT = var.app_root
    COUNTER_API_URL           = var.api_url
  }
  custom_rule {
    source = "https://www.${var.domain_name}"
    target = "https://${var.domain_name}"
    status = "301"
  }
  custom_headers = yamlencode({
    applications = [{
      appRoot = var.app_root
      customHeaders = [{
        pattern = "**/*"
        headers = [
          { key = "Strict-Transport-Security", value = "max-age=31536000" },
          { key = "X-Content-Type-Options", value = "nosniff" },
          { key = "Referrer-Policy", value = "strict-origin-when-cross-origin" },
          { key = "Permissions-Policy", value = "camera=(), microphone=(), geolocation=()" },
          { key = "Content-Security-Policy", value = "default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline' https://fonts.googleapis.com; font-src 'self' https://fonts.gstatic.com; img-src 'self' data:; connect-src 'self' ${var.api_url}; frame-ancestors 'none'; base-uri 'self'; form-action 'none'" }
        ]
      }]
    }]
  })
  lifecycle {
    prevent_destroy = true
    precondition {
      condition     = can(regex("^d[a-z0-9]+$", var.existing_app_id))
      error_message = "Connect GitHub through the Amplify GitHub App, set its app ID, and import app/branch before apply. Never put GitHub tokens in Terraform."
    }
  }
}
resource "aws_amplify_branch" "this" {
  app_id                      = aws_amplify_app.this.id
  branch_name                 = var.branch_name
  stage                       = "PRODUCTION"
  enable_auto_build           = var.enable_auto_build
  enable_pull_request_preview = false
  enable_basic_auth           = false
}
