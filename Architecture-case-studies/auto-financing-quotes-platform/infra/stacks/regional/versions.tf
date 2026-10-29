terraform {
  required_version = ">= 1.10, < 2.0"
  required_providers {
    aws    = { source = "hashicorp/aws", version = "~> 6.0" }
    random = { source = "hashicorp/random", version = "~> 3.7" }
  }
}
provider "aws" {
  region = var.region
  default_tags { tags = { Project = var.project, ManagedBy = "Terraform", Environment = var.profile } }
}
data "aws_caller_identity" "current" {}
data "aws_availability_zones" "available" { state = "available" }
locals {
  az_count        = var.profile == "ha" ? 3 : 2
  azs             = slice(data.aws_availability_zones.available.names, 0, local.az_count)
  db_count        = var.profile == "ha" ? 3 : 1
  web_count       = var.enable_runtime ? (var.profile == "ha" ? 3 : 1) : 0
  publisher_count = var.enable_runtime && var.publish_enabled ? (var.profile == "ha" ? 2 : 1) : 0
  origin          = "https://${var.domain_name}"
  account_id      = data.aws_caller_identity.current.account_id
}

