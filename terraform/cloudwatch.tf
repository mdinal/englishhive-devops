# CloudWatch Log Group for Structured MDC Logs
resource "aws_cloudwatch_log_group" "app_logs" {
  name              = "/englishhive/${var.environment}/backend"
  retention_in_days = 14
}

# CloudWatch Alarm for High 5xx Error Rate
resource "aws_cloudwatch_metric_alarm" "high_errors" {
  alarm_name          = "englishhive-${var.environment}-high-5xx-errors"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "5XXError"
  namespace           = "AWS/AppRunner"
  period              = 60
  statistic           = "Sum"
  threshold           = 5
  alarm_description   = "Triggered when 5xx errors exceed 5 within 2 minutes"
}
