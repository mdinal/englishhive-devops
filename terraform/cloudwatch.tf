# CloudWatch Log Group for Structured MDC Logs
resource "aws_cloudwatch_log_group" "app_logs" {
  name              = "/englishhive/${var.environment}/backend"
  retention_in_days = 14
}

# CloudWatch Metric Filter for Backend 5xx / Error Logs
resource "aws_cloudwatch_log_metric_filter" "backend_errors" {
  name           = "englishhive-${var.environment}-5xx-errors"
  pattern        = "[timestamp, request_id, level = *ERROR*, ...]"
  log_group_name = aws_cloudwatch_log_group.app_logs.name

  metric_transformation {
    name      = "BackendErrorCount"
    namespace = "EnglishHive/Backend"
    value     = "1"
  }
}

# CloudWatch Alarm for Backend High Error Rate
resource "aws_cloudwatch_metric_alarm" "high_errors" {
  alarm_name          = "englishhive-${var.environment}-high-errors"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "BackendErrorCount"
  namespace           = "EnglishHive/Backend"
  period              = 60
  statistic           = "Sum"
  threshold           = 5
  alarm_description   = "Triggered when backend error logs exceed 5 within 2 minutes"
}

# CloudWatch Alarm for ECS Memory Utilization
resource "aws_cloudwatch_metric_alarm" "ecs_memory_high" {
  alarm_name          = "englishhive-${var.environment}-ecs-memory-high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = 85
  alarm_description   = "Triggered when ECS backend container memory utilization exceeds 85%"

  dimensions = {
    ClusterName = aws_ecs_cluster.data_cluster.name
    ServiceName = aws_ecs_service.backend.name
  }
}
