resource "aws_cloudwatch_log_group" "app" {
  for_each          = toset(["web", "publisher", "migration", "email"])
  name              = "/drivequote/${var.project}/${each.key}"
  retention_in_days = var.log_retention_days
}

resource "aws_sns_topic" "alarms" { name = "${var.project}-alarms" }

resource "aws_sns_topic_subscription" "alarms" {
  count     = var.alarm_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.alarms.arn
  protocol  = "email"
  endpoint  = var.alarm_email
}

resource "aws_cloudwatch_metric_alarm" "queue_age" {
  alarm_name          = "${var.project}-queue-age"
  namespace           = "AWS/SQS"
  metric_name         = "ApproximateAgeOfOldestMessage"
  dimensions          = { QueueName = aws_sqs_queue.notifications.name }
  statistic           = "Maximum"
  period              = 60
  evaluation_periods  = 3
  threshold           = 120
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alarms.arn]
}

resource "aws_cloudwatch_metric_alarm" "dlq" {
  alarm_name          = "${var.project}-dlq"
  namespace           = "AWS/SQS"
  metric_name         = "ApproximateNumberOfMessagesVisible"
  dimensions          = { QueueName = aws_sqs_queue.dlq.name }
  statistic           = "Maximum"
  period              = 60
  evaluation_periods  = 1
  threshold           = 0
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alarms.arn]
}

resource "aws_cloudwatch_metric_alarm" "outbox" {
  count               = var.enable_runtime && var.publish_enabled ? 1 : 0
  alarm_name          = "${var.project}-outbox-age"
  namespace           = "DriveQuote"
  metric_name         = "OldestPendingSeconds"
  dimensions          = { Project = var.project }
  statistic           = "Maximum"
  period              = 60
  evaluation_periods  = 2
  threshold           = 120
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "breaching"
  alarm_actions       = [aws_sns_topic.alarms.arn]
}

resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  count               = var.enable_runtime ? 1 : 0
  alarm_name          = "${var.project}-email-errors"
  namespace           = "AWS/Lambda"
  metric_name         = "Errors"
  dimensions          = { FunctionName = aws_lambda_function.email[0].function_name }
  statistic           = "Sum"
  period              = 60
  evaluation_periods  = 2
  threshold           = 0
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alarms.arn]
}

resource "aws_cloudwatch_metric_alarm" "unhealthy" {
  count               = var.enable_runtime ? 1 : 0
  alarm_name          = "${var.project}-unhealthy-target"
  namespace           = "AWS/ApplicationELB"
  metric_name         = "UnHealthyHostCount"
  dimensions          = { LoadBalancer = aws_lb.main.arn_suffix, TargetGroup = aws_lb_target_group.web.arn_suffix }
  statistic           = "Maximum"
  period              = 60
  evaluation_periods  = 2
  threshold           = 0
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "breaching"
  alarm_actions       = [aws_sns_topic.alarms.arn]
}

resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = var.project
  dashboard_body = jsonencode({ widgets = [
    { type = "metric", x = 0, y = 0, width = 12, height = 6, properties = {
      title   = "Notification backlog age", region = var.region, stat = "Maximum", period = 60,
      metrics = [["AWS/SQS", "ApproximateAgeOfOldestMessage", "QueueName", aws_sqs_queue.notifications.name]]
    } },
    { type = "metric", x = 12, y = 0, width = 12, height = 6, properties = {
      title   = "Unpublished outbox age", region = var.region, stat = "Maximum", period = 60,
      metrics = [["DriveQuote", "OldestPendingSeconds", "Project", var.project]]
    } },
    { type = "metric", x = 0, y = 6, width = 12, height = 6, properties = {
      title   = "ALB response time p99", region = var.region, stat = "p99", period = 60,
      metrics = [["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", aws_lb.main.arn_suffix]]
    } },
    { type = "metric", x = 12, y = 6, width = 12, height = 6, properties = {
      title   = "Database connections", region = var.region, stat = "Maximum", period = 60,
      metrics = [["AWS/RDS", "DatabaseConnections", "DBClusterIdentifier", aws_rds_cluster.main.id]]
    } }
  ] })
}

resource "aws_cloudwatch_log_metric_filter" "notification_failures" {
  name           = "${var.project}-notification-failures"
  log_group_name = aws_cloudwatch_log_group.app["email"].name
  pattern        = "\"notification_failed\""
  metric_transformation {
    name          = "NotificationFailures"
    namespace     = "DriveQuote/${var.project}"
    value         = "1"
    default_value = 0
  }
}

resource "aws_cloudwatch_metric_alarm" "notification_failures" {
  count               = var.enable_runtime ? 1 : 0
  alarm_name          = "${var.project}-notification-failures"
  namespace           = "DriveQuote/${var.project}"
  metric_name         = "NotificationFailures"
  statistic           = "Sum"
  period              = 60
  evaluation_periods  = 2
  threshold           = 0
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alarms.arn]
}
