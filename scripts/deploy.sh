#!/bin/bash

# ML Platform Deployment Script
# Automates the deployment of the entire infrastructure

set -e

echo "🚀 ML Platform Terraform Deployment"
echo "===================================="
echo ""

# Colors for output
GREEN='\033[0.32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check prerequisites
echo "📋 Checking prerequisites..."

if ! command -v terraform &> /dev/null; then
    echo -e "${RED}❌ Terraform not installed${NC}"
    echo "Install from: https://www.terraform.io/downloads"
    exit 1
fi

if ! command -v aws &> /dev/null; then
    echo -e "${RED}❌ AWS CLI not installed${NC}"
    echo "Install from: https://aws.amazon.com/cli/"
    exit 1
fi

if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}❌ kubectl not installed${NC}"
    echo "Install from: https://kubernetes.io/docs/tasks/tools/"
    exit 1
fi

echo -e "${GREEN}✅ All prerequisites installed${NC}"
echo ""

# Get AWS Account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo "AWS Account ID: $AWS_ACCOUNT_ID"
echo ""

# Prompt for confirmation
echo -e "${YELLOW}⚠️  This will create AWS resources that cost money${NC}"
echo "Estimated cost: ~$200/month for dev environment"
echo ""
read -p "Continue? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Deployment cancelled"
    exit 0
fi

# Navigate to terraform directory
cd terraform

# Initialize Terraform
echo ""
echo "🔧 Initializing Terraform..."
terraform init

# Plan
echo ""
echo "📝 Planning deployment..."
terraform plan -out=tfplan

# Apply
echo ""
echo "🚀 Deploying infrastructure..."
terraform apply tfplan

# Get cluster credentials
echo ""
echo "📥 Configuring kubectl..."
CLUSTER_NAME=$(terraform output -raw cluster_name)
AWS_REGION=$(terraform output -raw region)
aws eks update-kubeconfig --region $AWS_REGION --name $CLUSTER_NAME

# Verify cluster access
echo ""
echo "✅ Verifying cluster access..."
kubectl get nodes

# Deploy ML serving application
echo ""
echo "🤖 Deploying ML serving application..."
cd ..
kubectl apply -f k8s/

# Wait for pods
echo ""
echo "⏳ Waiting for pods to be ready..."
kubectl wait --for=condition=ready pod -l app=ml-serving --timeout=300s || true

# Get service URLs
echo ""
echo "🌐 Getting service URLs..."
echo ""
echo "Grafana:"
echo "  kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80"
echo "  Then open: http://localhost:3000"
echo "  Username: admin"
echo "  Password: (from terraform variables)"
echo ""
echo "Prometheus:"
echo "  kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090"
echo "  Then open: http://localhost:9090"
echo ""

# Show estimated costs
echo ""
terraform output estimated_monthly_cost

echo ""
echo -e "${GREEN}✅ Deployment complete!${NC}"
echo ""
echo "Next steps:"
echo "  1. Access Grafana and explore dashboards"
echo "  2. Deploy your ML model from project 1"
echo "  3. Set up Slack/email alerts in AlertManager"
echo "  4. Configure AWS Budget alerts"
