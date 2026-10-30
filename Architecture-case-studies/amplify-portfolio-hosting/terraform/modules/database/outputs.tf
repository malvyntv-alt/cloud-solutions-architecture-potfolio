output "name" {
  value = aws_dynamodb_table.this.name
}
output "arn" {
  value = aws_dynamodb_table.this.arn
}
output "billing_mode" {
  value = aws_dynamodb_table.this.billing_mode
}
output "deletion_protection" {
  value = aws_dynamodb_table.this.deletion_protection_enabled
}
