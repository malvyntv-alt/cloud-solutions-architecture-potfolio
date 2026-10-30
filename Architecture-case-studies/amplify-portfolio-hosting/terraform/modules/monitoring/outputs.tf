output "dashboard_name" {
  value = aws_cloudwatch_dashboard.this.dashboard_name
}
output "alarm_names" {
  value = [aws_cloudwatch_metric_alarm.lambda_errors.alarm_name, aws_cloudwatch_metric_alarm.api_errors.alarm_name, aws_cloudwatch_metric_alarm.database_throttles.alarm_name]
}
