# ==============================================================================
# Terraform Remote State Management (S3 + DynamoDB State Locking)
# ==============================================================================

# S3 Bucket for Terraform Remote State
resource "aws_s3_bucket" "terraform_state" {
  bucket = "englishhive-terraform-state-${data.aws_caller_identity.current.account_id}-${var.environment}"

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name        = "EnglishHive Terraform State Bucket"
    Environment = var.environment
  }
}

# Enable S3 Bucket Versioning for Rollback Capability
resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Enable Server-Side Encryption (AES256)
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block all Public Access to State Bucket
resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# DynamoDB Table for Distributed State Locking
resource "aws_dynamodb_table" "terraform_locks" {
  name         = "englishhive-terraform-locks-${var.environment}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name        = "EnglishHive Terraform State Lock Table"
    Environment = var.environment
  }
}
