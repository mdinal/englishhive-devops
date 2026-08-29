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

output "cloudfront_distribution_domain" {
  description = "CloudFront Protected Media CDN Domain"
  value       = aws_cloudfront_distribution.media_cdn.domain_name
}

output "media_bucket_name" {
  description = "S3 Protected Encrypted Media Bucket"
  value       = aws_s3_bucket.protected_media.bucket
}

output "monthly_aws_budget_estimate" {
  description = "Estimated Monthly Total AWS Cost"
  value       = "$15.00 - $28.00 / month (with Containerized PostgreSQL & Redis on ECS/App Runner)"
}
