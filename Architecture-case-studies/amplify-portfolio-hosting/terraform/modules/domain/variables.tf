variable "enabled" {
  type    = bool
  default = false
}

variable "app_id" {
  type = string
}

variable "branch_name" {
  type = string
}

variable "domain_name" {
  type = string
}

variable "manage_dns_records" {
  type    = bool
  default = false
}

variable "hosted_zone_id" {
  type    = string
  default = ""
}
