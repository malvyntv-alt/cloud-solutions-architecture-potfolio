variable "name" { type = string }
variable "knowledge_base_id" { type = string }
variable "lambda_zip_path" { type = string }
variable "reserved_concurrent_executions" {
  type        = number
  default     = -1
  description = "-1 uses the account's shared pool; positive integers reserve capacity. Zero disables invocation."
  validation {
    condition     = var.reserved_concurrent_executions >= -1 && floor(var.reserved_concurrent_executions) == var.reserved_concurrent_executions
    error_message = "Reserved concurrency must be -1 or a non-negative integer."
  }
}
variable "allowed_origins" {
  type = list(string)
  validation {
    condition     = length(var.allowed_origins) > 0 && alltrue([for origin in var.allowed_origins : can(regex("^https://[^/]+$|^http://localhost:[0-9]+$", origin))])
    error_message = "Use explicit HTTPS origins or http://localhost:PORT, without trailing slashes."
  }
}
variable "model_id" {
  type    = string
  default = "amazon.nova-lite-v1:0"
  validation {
    condition     = can(regex("^amazon\\.[a-z0-9.:-]+$", var.model_id))
    error_message = "Supply a regional Amazon foundation-model ID; inference profiles need a separate IAM policy."
  }
}
