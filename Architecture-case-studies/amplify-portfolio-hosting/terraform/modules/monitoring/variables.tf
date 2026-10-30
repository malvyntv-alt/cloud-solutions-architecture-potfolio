variable "name" {
  type = string
}

variable "region" {
  type = string
}

variable "function_name" {
  type = string
}

variable "api_id" {
  type = string
}

variable "table_name" {
  type = string
}

variable "alarm_email" {
  type    = string
  default = ""
}

variable "monthly_budget_usd" {
  type    = string
  default = "10"
}
