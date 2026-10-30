resource "aws_dynamodb_table" "this" {
  name                        = var.name
  billing_mode                = "PAY_PER_REQUEST"
  hash_key                    = "pk"
  deletion_protection_enabled = var.deletion_protection
  attribute {
    name = "pk"
    type = "S"
  }
  server_side_encryption { enabled = true }
  point_in_time_recovery { enabled = var.point_in_time_recovery }
}
