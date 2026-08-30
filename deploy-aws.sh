#!/bin/bash
set -eo pipefail

# ==============================================================================
# EnglishHive Automated Cloud Deployment Pipeline
# Deploys Infrastructure, Backend (ECS Fargate), and Frontend SPA (S3 + CloudFront)
# ==============================================================================

echo "🚀 [EnglishHive] Starting Enterprise AWS Deployment Pipeline..."

REGION=${AWS_REGION:-"us-east-1"}
ENV=${ENVIRONMENT:-"prod"}

# Determine script root directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

# ------------------------------------------------------------------------------
# 1. Terraform Infrastructure Provisioning
# ------------------------------------------------------------------------------
echo "📦 [Step 1/5] Initializing & Applying Terraform Infrastructure..."
cd "${SCRIPT_DIR}/terraform"
terraform init -upgrade
terraform apply -auto-approve -var="aws_region=${REGION}" -var="environment=${ENV}"

# Extract Provisioned Outputs
BACKEND_ECR=$(terraform output -raw backend_ecr_url)
FRONTEND_ECR=$(terraform output -raw frontend_ecr_url)
MEDIA_BUCKET=$(terraform output -raw media_bucket_name)
CF_DIST_ID=$(terraform output -raw cloudfront_distribution_id)
CF_DOMAIN=$(terraform output -raw cloudfront_distribution_domain)
ECS_CLUSTER=$(terraform output -raw ecs_cluster_name)
ECS_SERVICE=$(terraform output -raw ecs_service_name)

# ------------------------------------------------------------------------------
# 2. Authenticate Docker with AWS ECR
# ------------------------------------------------------------------------------
echo "🔑 [Step 2/5] Logging into AWS Elastic Container Registry (ECR)..."
aws ecr get-login-password --region "${REGION}" | docker login --username AWS --password-stdin "${BACKEND_ECR}"

# ------------------------------------------------------------------------------
# 3. Build, Tag & Push Backend Container Image
# ------------------------------------------------------------------------------
echo "🔨 [Step 3/5] Building and pushing Backend container to ECR..."
docker build -t "${BACKEND_ECR}:latest" "${ROOT_DIR}/backend"
docker push "${BACKEND_ECR}:latest"

echo "🔄 Triggering ECS Fargate rolling redeployment..."
aws ecs update-service \
  --cluster "${ECS_CLUSTER}" \
  --service "${ECS_SERVICE}" \
  --force-new-deployment \
  --region "${REGION}" > /dev/null

# ------------------------------------------------------------------------------
# 4. Build Angular Frontend Application & Deploy to S3
# ------------------------------------------------------------------------------
echo "🌐 [Step 4/5] Building Angular Frontend SPA..."
cd "${ROOT_DIR}/frontend"
npm install --legacy-peer-deps
npm run build

echo "☁️ Syncing static build artifacts to S3 bucket (${MEDIA_BUCKET})..."
aws s3 sync dist/englishhive-frontend/browser "s3://${MEDIA_BUCKET}/" --delete --region "${REGION}"

# ------------------------------------------------------------------------------
# 5. Invalidate CloudFront CDN Cache
# ------------------------------------------------------------------------------
echo "⚡ [Step 5/5] Invalidating CloudFront edge cache..."
aws cloudfront create-invalidation \
  --distribution-id "${CF_DIST_ID}" \
  --paths "/*" > /dev/null

echo "=============================================================================="
echo "✅ [EnglishHive] Deployment Succeeded!"
echo "   - CDN Domain:      https://${CF_DOMAIN}"
echo "   - S3 Bucket:       ${MEDIA_BUCKET}"
echo "   - ECS Service:     ${ECS_SERVICE} in ${ECS_CLUSTER}"
echo "   - Region:          ${REGION}"
echo "=============================================================================="
