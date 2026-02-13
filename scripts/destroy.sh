#!/bin/bash

# ML Platform Cleanup Script
# Destroys all infrastructure to avoid costs

set -e

echo "🗑️  ML Platform Infrastructure Cleanup"
echo "======================================"
echo ""

# Colors
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${RED}⚠️  WARNING: This will DELETE all infrastructure${NC}"
echo ""
echo "This includes:"
echo "  - EKS Cluster"
echo "  - EC2 Instances"
echo "  - Load Balancers"
echo "  - EBS Volumes"
echo "  - VPC and networking"
echo "  - All data in Prometheus/Grafana"
echo ""
read -p "Are you ABSOLUTELY sure? (type 'destroy' to confirm): " confirm

if [ "$confirm" != "destroy" ]; then
    echo "Cleanup cancelled"
    exit 0
fi

cd terraform

# Delete Kubernetes resources first
echo ""
echo "🧹 Cleaning up Kubernetes resources..."
kubectl delete -f ../k8s/ || true

# Wait a bit for load balancers to be deleted
echo "⏳ Waiting for load balancers to be deleted..."
sleep 30

# Terraform destroy
echo ""
echo "💥 Destroying infrastructure..."
terraform destroy -auto-approve

echo ""
echo "✅ Cleanup complete"
echo ""
echo "Verify in AWS Console that all resources are deleted:"
echo "  - EC2 Instances"
echo "  - Load Balancers"
echo "  - EBS Volumes"
echo "  - VPC (may need manual deletion if resources remain)"
