terraform {
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 6.0" }
  }
}
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}
locals {
  arn_prefix = "arn:${data.aws_partition.current.partition}"
  region     = data.aws_region.current.region
  account    = data.aws_caller_identity.current.account_id
}

resource "aws_cloudwatch_log_group" "chat" {
  name              = "/aws/lambda/${var.name}-chat"
  retention_in_days = 14
}
resource "aws_iam_role" "chat" {
  name = "${var.name}-chat"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [{ Effect = "Allow", Action = "sts:AssumeRole", Principal = { Service = "lambda.amazonaws.com" } }]
  })
}
resource "aws_iam_role_policy" "chat" {
  role = aws_iam_role.chat.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      { Effect = "Allow", Action = ["bedrock:Retrieve"], Resource = "${local.arn_prefix}:bedrock:${local.region}:${local.account}:knowledge-base/${var.knowledge_base_id}" },
      { Effect = "Allow", Action = ["bedrock:InvokeModel"], Resource = "${local.arn_prefix}:bedrock:${local.region}::foundation-model/${var.model_id}" },
      { Effect = "Allow", Action = ["logs:CreateLogStream", "logs:PutLogEvents"], Resource = "${aws_cloudwatch_log_group.chat.arn}:*" }
    ]
  })
}
resource "aws_lambda_function" "chat" {
  function_name                  = "${var.name}-chat"
  role                           = aws_iam_role.chat.arn
  runtime                        = "python3.12"
  handler                        = "backend.lambda_handler.lambda_handler"
  filename                       = var.lambda_zip_path
  source_code_hash               = filebase64sha256(var.lambda_zip_path)
  timeout                        = 28
  memory_size                    = 256
  reserved_concurrent_executions = var.reserved_concurrent_executions
  environment {
    variables = {
      BEDROCK_KB_ID     = var.knowledge_base_id
      BEDROCK_MODEL_ARN = var.model_id
    }
  }
  depends_on = [aws_iam_role_policy.chat]
}

resource "aws_cognito_user_pool" "chat" {
  name                     = "${var.name}-users"
  username_attributes      = ["email"]
  auto_verified_attributes = ["email"]
  admin_create_user_config { allow_admin_create_user_only = true }
  password_policy {
    minimum_length    = 12
    require_lowercase = true
    require_uppercase = true
    require_numbers   = true
    require_symbols   = true
  }
}
resource "aws_cognito_user_pool_client" "chat" {
  name                          = "${var.name}-web"
  user_pool_id                  = aws_cognito_user_pool.chat.id
  generate_secret               = false
  explicit_auth_flows           = ["ALLOW_USER_SRP_AUTH", "ALLOW_REFRESH_TOKEN_AUTH"]
  prevent_user_existence_errors = "ENABLED"
  enable_token_revocation       = true
  access_token_validity         = 60
  id_token_validity             = 60
  token_validity_units {
    access_token = "minutes"
    id_token     = "minutes"
  }
}
resource "aws_apigatewayv2_api" "chat" {
  name          = "${var.name}-chat"
  protocol_type = "HTTP"
  cors_configuration {
    allow_origins = var.allowed_origins
    allow_methods = ["POST", "OPTIONS"]
    allow_headers = ["authorization", "content-type"]
    max_age       = 300
  }
}
resource "aws_apigatewayv2_authorizer" "chat" {
  api_id           = aws_apigatewayv2_api.chat.id
  name             = "cognito"
  authorizer_type  = "JWT"
  identity_sources = ["$request.header.Authorization"]
  jwt_configuration {
    audience = [aws_cognito_user_pool_client.chat.id]
    issuer   = "https://${aws_cognito_user_pool.chat.endpoint}"
  }
}
resource "aws_apigatewayv2_integration" "chat" {
  api_id                 = aws_apigatewayv2_api.chat.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.chat.invoke_arn
  payload_format_version = "2.0"
  timeout_milliseconds   = 29000
}
resource "aws_apigatewayv2_route" "chat" {
  api_id               = aws_apigatewayv2_api.chat.id
  route_key            = "POST /chat"
  target               = "integrations/${aws_apigatewayv2_integration.chat.id}"
  authorization_type   = "JWT"
  authorizer_id        = aws_apigatewayv2_authorizer.chat.id
  authorization_scopes = ["aws.cognito.signin.user.admin"]
}
resource "aws_cloudwatch_log_group" "api" {
  name              = "/aws/apigateway/${var.name}-chat"
  retention_in_days = 14
}
resource "aws_apigatewayv2_stage" "chat" {
  api_id      = aws_apigatewayv2_api.chat.id
  name        = "$default"
  auto_deploy = true
  default_route_settings {
    throttling_burst_limit = 5
    throttling_rate_limit  = 2
  }
  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api.arn
    format          = jsonencode({ requestId = "$context.requestId", status = "$context.status", route = "$context.routeKey" })
  }
}
resource "aws_lambda_permission" "gateway" {
  statement_id  = "AllowChatGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.chat.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.chat.execution_arn}/*/POST/chat"
}
