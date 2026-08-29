# App Runner Service for Backend (Cost Optimized: $5 - $12 / mo)
resource "aws_iam_role" "apprunner_role" {
  name = "englishhive-apprunner-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "build.apprunner.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "apprunner_ecr" {
  role       = aws_iam_role.apprunner_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSAppRunnerServicePolicyForECRAccess"
}

# ECS Cluster for Persistent Database & Redis Containers ($0 RDS Fees)
resource "aws_ecs_cluster" "data_cluster" {
  name = "englishhive-data-cluster"
}
