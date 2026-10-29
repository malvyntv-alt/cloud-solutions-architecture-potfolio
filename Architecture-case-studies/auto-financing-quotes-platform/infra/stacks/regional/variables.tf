variable "project" {
  type    = string
  default = "drivequote-portfolio"
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,19}$", var.project))
    error_message = "Use 3–20 lowercase letters, numbers, or hyphens, beginning with a letter."
  }
}
variable "region" {
  type    = string
  default = "us-east-1"
}
variable "profile" {
  type    = string
  default = "demo"
  validation {
    condition     = contains(["demo", "ha"], var.profile)
    error_message = "Choose demo or ha. Neither profile is multi-region."
  }
}
variable "domain_name" {
  type        = string
  description = "Existing public DNS name you control, such as quotes.example.com."
}
variable "hosted_zone_id" {
  type        = string
  description = "Existing public Route 53 hosted zone for domain_name."
}
variable "email_from" {
  type        = string
  description = "SES sender address you control; email verification is required."
  validation {
    condition     = can(regex("^[^@ ]+@[^@ ]+\\.[^@ ]+$", var.email_from))
    error_message = "Provide a valid sender email address."
  }
}
variable "alarm_email" {
  type        = string
  default     = ""
  description = "Optional SNS subscription for alarms; recipient must confirm."
}
variable "enable_runtime" {
  type        = bool
  default     = false
  description = "Keep false until images are pushed and the migration task succeeds."
}
variable "publish_enabled" {
  type        = bool
  default     = true
  description = "Disable publisher and consumer during recovery preparation."
}
variable "image_tag" {
  type    = string
  default = "v1"
}
variable "db_instance_class" {
  type    = string
  default = "db.t4g.medium"
}
variable "engine_version" {
  type        = string
  default     = null
  description = "Optional supported Aurora PostgreSQL version. Pin after checking regional availability."
}
variable "enable_waf" {
  type    = bool
  default = true
}
variable "deletion_protection" {
  type    = bool
  default = false
}
variable "log_retention_days" {
  type    = number
  default = 14
}
variable "monthly_budget_usd" {
  type        = string
  default     = "150"
  description = "Alert threshold, NOT a spending cap or cost estimate."
}
