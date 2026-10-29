output "application_url" { value = local.origin }
output "app_repository" { value = aws_ecr_repository.app.repository_url }
output "email_repository" { value = aws_ecr_repository.email.repository_url }
output "cluster_name" { value = aws_ecs_cluster.main.name }
output "migration_task_definition" { value = aws_ecs_task_definition.main["migration"].arn }
output "private_subnets" { value = aws_subnet.private[*].id }
output "compute_security_group" { value = aws_security_group.compute.id }
output "user_pool_id" { value = aws_cognito_user_pool.main.id }
output "queue_url" { value = aws_sqs_queue.notifications.url }
output "dlq_url" { value = aws_sqs_queue.dlq.url }
output "audit_bucket" { value = aws_s3_bucket.audit.id }
output "database_cluster" { value = aws_rds_cluster.main.cluster_identifier }
output "deployment_profile" { value = var.profile == "demo" ? "Single region, cost-reduced; NOT the full HA/DR design" : "Single region, three-AZ HA; regional DR still requires separate implementation" }

