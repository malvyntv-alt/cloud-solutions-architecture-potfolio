variable "name" { type = string }
variable "environment" { type = string }
variable "region" { type = string }
variable "account_id" { type = string }

variable "network_mode" {
  type = string
  validation {
    condition     = var.network_mode == "standard"
    error_message = "The RAG module is intentionally VPC-free."
  }
}
