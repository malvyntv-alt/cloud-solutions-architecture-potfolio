output "endpoint" {
  value = aws_apigatewayv2_api.this.api_endpoint
}
output "api_id" {
  value = aws_apigatewayv2_api.this.id
}
output "function_name" {
  value = aws_lambda_function.counter.function_name
}
output "lambda_log_group" {
  value = aws_cloudwatch_log_group.lambda.name
}
output "api_log_group" {
  value = aws_cloudwatch_log_group.api.name
}
output "route_keys" {
  value = toset([for route in aws_apigatewayv2_route.this : route.route_key])
}
