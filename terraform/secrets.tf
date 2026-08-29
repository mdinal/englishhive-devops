# AWS Secrets Manager for Production Credentials
resource "aws_secretsmanager_secret" "app_secrets" {
  name                    = "englishhive/${var.environment}/app-credentials"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "app_secrets_val" {
  secret_id = aws_secretsmanager_secret.app_secrets.id

  secret_string = jsonencode({
    JWT_SECRET     = "EnglishHiveSuperSecureProductionKeyWithHMACSHA512Validation2026EnterpriseEdition"
    DB_PASSWORD    = "englishhive_secure_password_2026"
    REDIS_PASSWORD = "redis_production_password_2026"
  })
}
