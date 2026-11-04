output "chat_url" { value = "${aws_apigatewayv2_api.chat.api_endpoint}/chat" }
output "user_pool_id" { value = aws_cognito_user_pool.chat.id }
output "client_id" { value = aws_cognito_user_pool_client.chat.id }
