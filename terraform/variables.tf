variable "aws_region" {
  description = "AWS Deployment Region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "prod"
}

variable "vpc_cidr" {
  description = "VPC CIDR Block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "domain_name" {
  description = "Primary institutional custom domain"
  type        = string
  default     = "englishhive.com"
}
