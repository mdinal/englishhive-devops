# ==============================================================================
# EC2 Database Host for PostgreSQL 16 & Redis
# Free Tier Eligible (t3.micro / t4g.micro) with Persistent EBS & Elastic IP
# ==============================================================================

# Latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Security Group for Database EC2 Instance
resource "aws_security_group" "db_ec2_sg" {
  name        = "englishhive-db-ec2-sg"
  description = "Allow inbound PostgreSQL (5432) and Redis (6379) from Backend SG and VPC"
  vpc_id      = aws_vpc.main.id

  # PostgreSQL from Backend Security Group
  ingress {
    description     = "PostgreSQL from Backend Container SG"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.backend_sg.id]
  }

  # PostgreSQL from internal VPC CIDR
  ingress {
    description = "PostgreSQL from VPC"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # Redis Access from Backend Security Group
  ingress {
    description     = "Redis from Backend Container SG"
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.backend_sg.id]
  }

  # Note: Direct SSH (port 22) and external PostgreSQL (5432) from 0.0.0.0/0 are disabled for security.
  # Use AWS SSM Session Manager or SSM Port Forwarding for administrative/DBeaver access:
  # aws ssm start-session --target <instance-id> --document-name AWS-StartPortForwardingSession --parameters '{"portNumber":["5432"],"localPortNumber":["5432"]}'

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "englishhive-${var.environment}-db-sg"
  }
}

# IAM Role for EC2 Instance (SSM Management & CloudWatch)
resource "aws_iam_role" "db_ec2_role" {
  name = "englishhive-db-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "db_ssm" {
  role       = aws_iam_role.db_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "db_profile" {
  name = "englishhive-db-ec2-profile"
  role = aws_iam_role.db_ec2_role.name
}

# EC2 Database Instance (Cost-optimized: Free Tier t3.micro)
resource "aws_instance" "database" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = "t3.micro" # 1 vCPU, 1 GB RAM (Free Tier eligible)
  subnet_id              = aws_subnet.public_a.id
  vpc_security_group_ids = [aws_security_group.db_ec2_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.db_profile.name

  root_block_device {
    volume_size           = 20 # 20 GB gp3 SSD (within AWS 30 GB Free Tier)
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = false # Protect database data from accidental deletion
    tags = {
      Name = "englishhive-${var.environment}-db-storage"
    }
  }

  # Automated User Data: Installs Docker and starts PostgreSQL 16 + Redis 7
  user_data = <<-EOF
    #!/bin/bash
    set -e
    dnf update -y
    dnf install -y docker

    systemctl enable --now docker
    usermod -aG docker ec2-user

    # Create persistent data directories
    mkdir -p /opt/englishhive/postgres_data
    mkdir -p /opt/englishhive/redis_data

    # Launch PostgreSQL 16 Container
    docker run -d \
      --name englishhive-postgres \
      --restart always \
      -p 5432:5432 \
      -e POSTGRES_DB=englishhive \
      -e POSTGRES_USER=englishhive_user \
      -e POSTGRES_PASSWORD=englishhive_secure_password_2026 \
      -v /opt/englishhive/postgres_data:/var/lib/postgresql/data \
      postgres:16-alpine

    # Launch Redis 7 Container
    docker run -d \
      --name englishhive-redis \
      --restart always \
      -p 6379:6379 \
      -v /opt/englishhive/redis_data:/data \
      redis:7-alpine redis-server --appendonly yes

    echo "EnglishHive Database & Redis stack started successfully" > /var/log/db_init.log
  EOF

  tags = {
    Name = "englishhive-${var.environment}-db-server"
    Role = "Database & Cache Server"
  }
}

# Static Elastic IP for stable DBeaver and backend connectivity
resource "aws_eip" "db_eip" {
  instance = aws_instance.database.id
  domain   = "vpc"

  tags = {
    Name = "englishhive-${var.environment}-db-eip"
  }
}
