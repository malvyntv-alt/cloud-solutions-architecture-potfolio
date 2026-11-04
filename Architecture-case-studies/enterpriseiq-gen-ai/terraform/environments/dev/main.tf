terraform {
  required_version = ">= 1.10.0"
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 6.0" }
  }
  backend "s3" {}
}
provider "aws" {
  region = var.aws_region
  default_tags { tags = { Project = "EnterpriseIQ", Environment = var.environment, ManagedBy = "Terraform" } }
}
data "aws_caller_identity" "current" {}
module "rag" {
  source       = "../../modules/rag"
  name         = "enterpriseiq"
  environment  = var.environment
  region       = var.aws_region
  account_id   = data.aws_caller_identity.current.account_id
  network_mode = var.network_mode
}
output "document_bucket" { value = module.rag.document_bucket }
output "knowledge_base_id" { value = module.rag.knowledge_base_id }
output "data_source_id" { value = module.rag.data_source_id }
