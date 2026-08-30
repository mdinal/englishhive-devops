output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "backend_ecr_url" {
  description = "Backend ECR Repository URL"
  value       = aws_ecr_repository.backend.repository_url
}

output "frontend_ecr_url" {
  description = "Frontend ECR Repository URL"
  value       = aws_ecr_repository.frontend.repository_url
}

output "cloudfront_distribution_id" {
  description = "CloudFront Distribution ID for Cache Invalidation"
  value       = aws_cloudfront_distribution.media_cdn.id
}

output "cloudfront_distribution_domain" {
  description = "CloudFront Protected Media CDN Domain"
  value       = aws_cloudfront_distribution.media_cdn.domain_name
}

output "media_bucket_name" {
  description = "S3 Protected Encrypted Media & Frontend Bucket"
  value       = aws_s3_bucket.protected_media.bucket
}

output "ecs_cluster_name" {
  description = "ECS Data Cluster Name"
  value       = aws_ecs_cluster.data_cluster.name
}

output "ecs_service_name" {
  description = "ECS Backend Service Name"
  value       = aws_ecs_service.backend.name
}

output "terraform_state_bucket" {
  description = "S3 Bucket for Terraform Remote State"
  value       = aws_s3_bucket.terraform_state.bucket
}

output "terraform_lock_table" {
  description = "DynamoDB Table for Terraform State Locking"
  value       = aws_dynamodb_table.terraform_locks.name
}

output "monthly_aws_budget_estimate" {
  description = "Estimated Monthly Total AWS Cost"
  value       = "$0.00 (Free Tier) to ~$6.00 / month (EC2 t3.micro Database & Backend)"
}

output "database_ec2_public_ip" {
  description = "Public Static Elastic IP for Database EC2 (SSM managed)"
  value       = aws_eip.db_eip.public_ip
}

output "database_ec2_private_ip" {
  description = "Private IP for Internal Backend Container Traffic"
  value       = aws_instance.database.private_ip
}

output "database_jdbc_url" {
  description = "JDBC Connection URL for PostgreSQL 16 (internal VPC)"
  value       = "jdbc:postgresql://${aws_instance.database.private_ip}:5432/englishhive"
}
