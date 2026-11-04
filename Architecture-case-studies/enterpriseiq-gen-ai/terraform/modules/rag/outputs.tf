output "document_bucket" { value = aws_s3_bucket.documents.id }
output "knowledge_base_id" { value = aws_bedrockagent_knowledge_base.kb.id }
output "data_source_id" { value = aws_bedrockagent_data_source.documents.data_source_id }
output "vector_index_arn" { value = aws_s3vectors_index.kb.index_arn }
