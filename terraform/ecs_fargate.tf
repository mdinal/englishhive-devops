# Security Group for Backend API Container
resource "aws_security_group" "backend_sg" {
  name        = "englishhive-backend-sg"
  description = "Allow inbound HTTP traffic to Spring Boot Backend API"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Allow HTTP on port 8080"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTP on port 80"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "englishhive-backend-sg"
  }
}

# IAM Execution Role for ECS Fargate Task
resource "aws_iam_role" "ecs_execution_role" {
  name = "englishhive-ecs-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_execution_policy" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# IAM Policy to allow ECS Execution Role to fetch secrets from AWS Secrets Manager
resource "aws_iam_policy" "ecs_secrets_policy" {
  name        = "englishhive-ecs-secrets-policy"
  description = "Allow ECS tasks to retrieve credentials from AWS Secrets Manager"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = [
          aws_secretsmanager_secret.app_secrets.arn
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_secrets_policy_attachment" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = aws_iam_policy.ecs_secrets_policy.arn
}

# ECS Fargate Task Definition for Backend
resource "aws_ecs_task_definition" "backend" {
  family                   = "englishhive-backend-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256" # 0.25 vCPU (Cost-optimized: ~$3.50/mo)
  memory                   = "512" # 0.5 GB RAM
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn

  container_definitions = jsonencode([{
    name      = "backend"
    image     = "${aws_ecr_repository.backend.repository_url}:latest"
    essential = true
    portMappings = [{
      containerPort = 8080
      hostPort      = 8080
      protocol      = "tcp"
    }]
    environment = [
      { name = "SPRING_PROFILES_ACTIVE", value = "prod" },
      { name = "SPRING_DATASOURCE_URL", value = "jdbc:postgresql://${aws_instance.database.private_ip}:5432/englishhive" },
      { name = "SPRING_DATASOURCE_USERNAME", value = "englishhive_user" },
      { name = "SPRING_DATA_REDIS_HOST", value = aws_instance.database.private_ip }
    ]
    secrets = [
      {
        name      = "SPRING_DATASOURCE_PASSWORD"
        valueFrom = "${aws_secretsmanager_secret.app_secrets.arn}:DB_PASSWORD::"
      },
      {
        name      = "APP_JWT_SECRET"
        valueFrom = "${aws_secretsmanager_secret.app_secrets.arn}:JWT_SECRET::"
      }
    ]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.app_logs.name
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "backend"
      }
    }
  }])
}

# ECS Fargate Service (Live Running Backend)
resource "aws_ecs_service" "backend" {
  name            = "englishhive-backend-service"
  cluster         = aws_ecs_cluster.data_cluster.id
  task_definition = aws_ecs_task_definition.backend.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.public_a.id, aws_subnet.public_b.id]
    security_groups  = [aws_security_group.backend_sg.id]
    assign_public_ip = true
  }

  depends_on = [
    aws_iam_role_policy_attachment.ecs_execution_policy,
    aws_instance.database
  ]
}
