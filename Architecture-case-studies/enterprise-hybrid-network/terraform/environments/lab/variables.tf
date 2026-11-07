variable "aws_region" {
  description = "AWS region for the independent networking lab."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Prefix for networking lab resources."
  type        = string
  default     = "enterprise-hybrid-network"
}

variable "owner" {
  description = "Owner used in resource tags."
  type        = string
  default     = "malvernvito"
}

variable "availability_zones" {
  description = "Two distinct AZ names in the selected region; null selects the first two available AZs."
  type        = list(string)
  default     = null
  validation {
    condition     = var.availability_zones == null ? true : length(var.availability_zones) == 2 && length(distinct(var.availability_zones)) == 2
    error_message = "Select exactly two distinct availability zones."
  }
}

variable "enable_hybrid" {
  description = "Create the simulated data center, router and two-tunnel BGP VPN."
  type        = bool
  default     = false
}

variable "enable_test_hosts" {
  description = "Create two test hosts per AWS VPC and SSM interface endpoints (billable)."
  type        = bool
  default     = false
}

variable "enable_hybrid_dns" {
  description = "Enable billable two-AZ inbound/outbound Resolver endpoints and router DNS; requires hybrid and test hosts."
  type        = bool
  default     = false
}
