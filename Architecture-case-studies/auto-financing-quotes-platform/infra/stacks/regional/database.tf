resource "aws_db_subnet_group" "main" {
  name       = "${var.project}-database"
  subnet_ids = aws_subnet.private[*].id
}
resource "aws_rds_cluster" "main" {
  cluster_identifier              = var.project
  engine                          = "aurora-postgresql"
  engine_version                  = var.engine_version
  database_name                   = "quotes"
  master_username                 = "quote_admin"
  manage_master_user_password     = true
  storage_encrypted               = true
  backup_retention_period         = 7
  preferred_backup_window         = "04:00-05:00"
  preferred_maintenance_window    = "sun:06:00-sun:07:00"
  db_subnet_group_name            = aws_db_subnet_group.main.name
  vpc_security_group_ids          = [aws_security_group.database.id]
  deletion_protection             = var.deletion_protection
  skip_final_snapshot             = true
  copy_tags_to_snapshot           = true
  enabled_cloudwatch_logs_exports = ["postgresql"]
}
resource "aws_rds_cluster_instance" "main" {
  count                      = local.db_count
  identifier                 = "${var.project}-${count.index}"
  cluster_identifier         = aws_rds_cluster.main.id
  instance_class             = var.db_instance_class
  engine                     = aws_rds_cluster.main.engine
  availability_zone          = local.azs[count.index]
  publicly_accessible        = false
  auto_minor_version_upgrade = true
  promotion_tier             = count.index
}
resource "random_password" "app" {
  length  = 32
  special = false
}
resource "aws_secretsmanager_secret" "app" {
  name_prefix             = "${var.project}-app-db-"
  recovery_window_in_days = 0
}
resource "aws_secretsmanager_secret_version" "app" {
  secret_id     = aws_secretsmanager_secret.app.id
  secret_string = jsonencode({ username = "quote_app", password = random_password.app.result, host = aws_rds_cluster.main.endpoint })
}

