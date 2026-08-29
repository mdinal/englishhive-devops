#!/bin/bash
set -e

# ==============================================================================
# EnglishHive AWS 1-Command Automated Cloud Deployment Script
# ==============================================================================

echo "🚀 [EnglishHive] Starting Enterprise AWS Deployment Pipeline..."

REGION=${AWS_REGION:-"us-east-1"}
ENV=${ENVIRONMENT:-"prod"}

# 1. Initialize Terraform Infrastructure
echo "📦 [Step 1/4] Applying Terraform Infrastructure (VPC, ECR, S3, CloudFront, AppRunner)..."
cd terraform
terraform init -upgrade
terraform apply -auto-approve -var="aws_region=${REGION}" -var="environment=${ENV}"

BACKEND_ECR=$(terraform output -raw backend_ecr_url)
FRONTEND_ECR=$(terraform output -raw frontend_ecr_url)
cd ..

# 2. Authenticate Docker with AWS ECR
echo "🔑 [Step 2/4] Logging into AWS ECR..."
aws ecr get-login-password --region ${REGION} | docker login --username AWS --password-stdin ${BACKEND_ECR}

# 3. Build & Push Backend Docker Image
echo "🔨 [Step 3/4] Building and pushing Backend container..."
docker build -t ${BACKEND_ECR}:latest ../backend
docker push ${BACKEND_ECR}:latest

# 4. Build & Push Frontend Docker Image
echo "🔨 [Step 4/4] Building and pushing Frontend container..."
docker build -t ${FRONTEND_ECR}:latest ../frontend
docker push ${FRONTEND_ECR}:latest

echo "✅ [EnglishHive] Deployment Complete! Global CDN and services are live."
