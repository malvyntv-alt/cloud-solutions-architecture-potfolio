resource "aws_ses_email_identity" "sender" { email = var.email_from }

resource "aws_ses_configuration_set" "main" {
  name                       = var.project
  reputation_metrics_enabled = true
  sending_enabled            = true
}

resource "aws_ses_event_destination" "delivery" {
  name                   = "${var.project}-delivery"
  configuration_set_name = aws_ses_configuration_set.main.name
  enabled                = true
  matching_types         = ["send", "reject", "bounce", "complaint", "delivery"]
  cloudwatch_destination {
    default_value  = "unknown"
    dimension_name = "source"
    value_source   = "messageTag"
  }
}

resource "aws_lambda_function" "email" {
  count         = var.enable_runtime ? 1 : 0
  function_name = "${var.project}-email"
  role          = aws_iam_role.task["email"].arn
  package_type  = "Image"
  image_uri     = "${aws_ecr_repository.email.repository_url}:${var.image_tag}"
  architectures = ["x86_64"]
  memory_size   = 256
  timeout       = 30
  vpc_config {
    subnet_ids         = aws_subnet.private[*].id
    security_group_ids = [aws_security_group.compute.id]
  }
  logging_config {
    log_format = "JSON"
    log_group  = aws_cloudwatch_log_group.app["email"].name
  }
  environment {
    variables = {
      APP_MODE              = "aws",
      DATABASE_HOST         = aws_rds_cluster.main.endpoint,
      DATABASE_SECRET_ARN   = aws_secretsmanager_secret.app.arn,
      EMAIL_FROM            = var.email_from,
      SES_CONFIGURATION_SET = aws_ses_configuration_set.main.name,
      PUBLIC_ORIGIN         = local.origin
    }
  }
  depends_on = [aws_iam_role_policy_attachment.lambda_vpc, aws_iam_role_policy.email]
}

resource "aws_lambda_event_source_mapping" "email" {
  count                              = var.enable_runtime ? 1 : 0
  event_source_arn                   = aws_sqs_queue.notifications.arn
  function_name                      = aws_lambda_function.email[0].arn
  batch_size                         = 5
  maximum_batching_window_in_seconds = 1
  function_response_types            = ["ReportBatchItemFailures"]
  enabled                            = var.publish_enabled
  scaling_config { maximum_concurrency = 5 }
}
