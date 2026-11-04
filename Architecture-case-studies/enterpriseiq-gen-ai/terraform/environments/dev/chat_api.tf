variable "enable_chat_api" {
  type        = bool
  default     = false
  description = "Opt in after building the Lambda archive and reviewing the DEV plan."
}
variable "chat_allowed_origins" {
  type    = list(string)
  default = ["http://localhost:5173"]
}
module "chat_api" {
  count             = var.enable_chat_api ? 1 : 0
  source            = "../../modules/chat_api"
  name              = "enterpriseiq-dev"
  knowledge_base_id = module.rag.knowledge_base_id
  lambda_zip_path   = "${path.module}/../../../build/chat-lambda.zip"
  allowed_origins   = var.chat_allowed_origins
}
output "chat_api" {
  value = var.enable_chat_api ? {
    url          = module.chat_api[0].chat_url
    user_pool_id = module.chat_api[0].user_pool_id
    client_id    = module.chat_api[0].client_id
  } : null
}
