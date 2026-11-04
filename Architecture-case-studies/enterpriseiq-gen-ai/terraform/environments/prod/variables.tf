variable "aws_region" {
  type    = string
  default = "us-east-1"
}
variable "environment" {
  type    = string
  default = "prod"
  validation {
    condition     = var.environment == "prod"
    error_message = "This root must deploy only the prod environment."
  }
}

# Deliberately VPC-free: this project does not deploy application resources into a customer VPC.
variable "network_mode" {
  type    = string
  default = "standard"
  validation {
    condition     = var.network_mode == "standard"
    error_message = "EnterpriseIQ currently supports network_mode = standard only (no customer-managed VPC)."
  }
}
