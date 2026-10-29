resource "aws_s3_bucket" "audit" {
  bucket        = "${var.project}-audit-${local.account_id}-${var.region}"
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "audit" {
  bucket                  = aws_s3_bucket.audit.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "audit" {
  bucket = aws_s3_bucket.audit.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "audit" {
  bucket = aws_s3_bucket.audit.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "audit" {
  bucket = aws_s3_bucket.audit.id
  rule {
    id     = "archive"
    status = "Enabled"
    filter { prefix = "" }
    transition {
      days          = 90
      storage_class = "GLACIER"
    }
  }
}

resource "aws_s3_bucket_policy" "audit" {
  bucket = aws_s3_bucket.audit.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      { Sid    = "TrailAcl", Effect = "Allow", Principal = { Service = "cloudtrail.amazonaws.com" },
        Action = "s3:GetBucketAcl", Resource = aws_s3_bucket.audit.arn,
      Condition = { StringEquals = { "aws:SourceArn" = "arn:aws:cloudtrail:${var.region}:${local.account_id}:trail/${var.project}" } } },
      { Sid    = "TrailWrite", Effect = "Allow", Principal = { Service = "cloudtrail.amazonaws.com" },
        Action = "s3:PutObject", Resource = "${aws_s3_bucket.audit.arn}/AWSLogs/${local.account_id}/*",
      Condition = { StringEquals = { "s3:x-amz-acl" = "bucket-owner-full-control", "aws:SourceArn" = "arn:aws:cloudtrail:${var.region}:${local.account_id}:trail/${var.project}" } } },
      { Sid      = "DenyInsecure", Effect = "Deny", Principal = "*", Action = "s3:*",
        Resource = [aws_s3_bucket.audit.arn, "${aws_s3_bucket.audit.arn}/*"],
      Condition = { Bool = { "aws:SecureTransport" = "false" } } }
    ]
  })
}

resource "aws_cloudtrail" "main" {
  name                          = var.project
  s3_bucket_name                = aws_s3_bucket.audit.id
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true
  event_selector {
    read_write_type           = "All"
    include_management_events = true
  }
  depends_on = [aws_s3_bucket_policy.audit]
}
