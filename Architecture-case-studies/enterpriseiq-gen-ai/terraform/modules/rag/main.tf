locals {
  prefix    = "${var.name}-${var.environment}"
  model_arn = "arn:aws:bedrock:${var.region}::foundation-model/amazon.titan-embed-text-v2:0"
}

resource "aws_s3_bucket" "documents" {
  bucket        = "${local.prefix}-docs-${var.account_id}"
  force_destroy = false
}
resource "aws_s3_bucket_public_access_block" "documents" {
  bucket                  = aws_s3_bucket.documents.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
resource "aws_s3_bucket_versioning" "documents" {
  bucket = aws_s3_bucket.documents.id
  versioning_configuration { status = "Enabled" }
}
resource "aws_s3_bucket_server_side_encryption_configuration" "documents" {
  bucket = aws_s3_bucket.documents.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3vectors_vector_bucket" "kb" {
  vector_bucket_name = "${local.prefix}-vectors"
}
resource "aws_s3vectors_index" "kb" {
  index_name         = "knowledge-index"
  vector_bucket_name = aws_s3vectors_vector_bucket.kb.vector_bucket_name
  data_type          = "float32"
  dimension          = 1024
  distance_metric    = "cosine"

  metadata_configuration {
    non_filterable_metadata_keys = ["AMAZON_BEDROCK_TEXT", "AMAZON_BEDROCK_METADATA"]
  }
}

data "aws_iam_policy_document" "bedrock_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["bedrock.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [var.account_id]
    }
    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = ["arn:aws:bedrock:${var.region}:${var.account_id}:knowledge-base/*"]
    }
  }
}
resource "aws_iam_role" "bedrock_kb" {
  name               = "${local.prefix}-kb-role"
  assume_role_policy = data.aws_iam_policy_document.bedrock_assume.json
}
data "aws_iam_policy_document" "bedrock_kb" {
  statement {
    sid       = "EmbeddingModel"
    actions   = ["bedrock:InvokeModel"]
    resources = [local.model_arn]
  }
  statement {
    sid       = "ReadDocuments"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.documents.arn}/*"]
  }
  statement {
    sid       = "ListDocuments"
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.documents.arn]
  }
  statement {
    sid       = "VectorData"
    actions   = ["s3vectors:PutVectors", "s3vectors:QueryVectors", "s3vectors:GetVectors", "s3vectors:DeleteVectors", "s3vectors:GetIndex"]
    resources = [aws_s3vectors_index.kb.index_arn]
  }
}
resource "aws_iam_role_policy" "bedrock_kb" {
  role   = aws_iam_role.bedrock_kb.id
  policy = data.aws_iam_policy_document.bedrock_kb.json
}
resource "aws_bedrockagent_knowledge_base" "kb" {
  name     = "${local.prefix}-kb"
  role_arn = aws_iam_role.bedrock_kb.arn
  knowledge_base_configuration {
    type = "VECTOR"
    vector_knowledge_base_configuration {
      embedding_model_arn = local.model_arn
      embedding_model_configuration {
        bedrock_embedding_model_configuration {
          dimensions          = 1024
          embedding_data_type = "FLOAT32"
        }
      }
    }
  }
  storage_configuration {
    type = "S3_VECTORS"
    s3_vectors_configuration { index_arn = aws_s3vectors_index.kb.index_arn }
  }
  depends_on = [aws_iam_role_policy.bedrock_kb]
}
resource "aws_bedrockagent_data_source" "documents" {
  name              = "${local.prefix}-documents"
  knowledge_base_id = aws_bedrockagent_knowledge_base.kb.id
  data_source_configuration {
    type = "S3"
    s3_configuration {
      bucket_arn         = aws_s3_bucket.documents.arn
      inclusion_prefixes = ["sample-knowledge-base/"]
    }
  }
}
