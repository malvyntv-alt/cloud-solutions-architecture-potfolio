variable "project" {
  type    = string
  default = "malvern-vito-portfolio"
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,29}$", var.project))
    error_message = "Use 3-30 lowercase letters, numbers or hyphens."
  }
}

variable "region" {
  type    = string
  default = "us-east-1"
}

variable "repository_url" {
  type    = string
  default = "https://github.com/malvyntv-alt/cloud-solutions-architecture-potfolio"
}

variable "amplify_app_id" {
  type        = string
  description = "Existing GitHub-connected Amplify app ID; import app and branch before apply."
  validation {
    condition     = can(regex("^d[a-z0-9]+$", var.amplify_app_id))
    error_message = "Set the existing Amplify app ID after authorizing the GitHub App. No GitHub token belongs in Terraform."
  }
}

variable "branch_name" {
  type    = string
  default = "main"
}

variable "domain_name" {
  type    = string
  default = "malvernvito.com"
}

variable "enable_auto_build" {
  type    = bool
  default = false
}

variable "enable_custom_domain" {
  type    = bool
  default = false
}

variable "manage_dns_records" {
  type    = bool
  default = false
  validation {
    condition     = !var.manage_dns_records || (var.enable_custom_domain && var.hosted_zone_id != "")
    error_message = "Managed DNS requires an enabled custom domain and existing hosted zone ID."
  }
}

variable "hosted_zone_id" {
  type    = string
  default = ""
}

variable "additional_allowed_origins" {
  type    = list(string)
  default = []
  validation {
    condition     = alltrue([for origin in var.additional_allowed_origins : can(regex("^https://[A-Za-z0-9.-]+$", origin))])
    error_message = "Use explicit HTTPS origins without a path, credentials or wildcard."
  }
}

variable "alarm_email" {
  type    = string
  default = ""
}

variable "monthly_budget_usd" {
  type    = string
  default = "10"
}

variable "protect_counter_data" {
  type    = bool
  default = true
}
