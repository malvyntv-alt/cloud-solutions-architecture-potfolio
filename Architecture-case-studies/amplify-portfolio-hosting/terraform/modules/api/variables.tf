variable "name" {
  type = string
}

variable "function_name" {
  type = string
}

variable "role_arn" {
  type = string
}

variable "table_name" {
  type = string
}

variable "lambda_zip" {
  type = string
}

variable "allowed_origins" {
  type = list(string)
}

variable "log_retention_days" {
  type    = number
  default = 14
}

variable "throttle_rate" {
  type    = number
  default = 2
}

variable "throttle_burst" {
  type    = number
  default = 5
}
