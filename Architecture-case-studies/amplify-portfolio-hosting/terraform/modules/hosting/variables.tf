variable "name" {
  type = string
}

variable "repository_url" {
  type = string
}

variable "branch_name" {
  type    = string
  default = "main"
}

variable "app_root" {
  type = string
}

variable "api_url" {
  type = string
}

variable "domain_name" {
  type = string
}

variable "existing_app_id" {
  type = string
}

variable "enable_auto_build" {
  type    = bool
  default = false
}
