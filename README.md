# ML Platform Infrastructure as Code

[![Terraform](https://img.shields.io/badge/Terraform-v1.0+-623CE4?logo=terraform)](https://www.terraform.io/)
[![AWS](https://img.shields.io/badge/AWS-EKS-FF9900?logo=amazon-aws)](https://aws.amazon.com/eks/)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-v1.28-326CE5?logo=kubernetes)](https://kubernetes.io/)

Production-grade infrastructure for deploying and operating ML models at scale using Terraform, AWS EKS, and
comprehensive observability.

## 🎯 What This Demonstrates

This project shows you can build production ML infrastructure, not just deploy models:

**Infrastructure as Code:**

- ✅ Complete AWS infrastructure defined in Terraform
- ✅ Reproducible deployments across environments
- ✅ Version-controlled infrastructure changes
- ✅ Cost-optimized resource configuration

**Production Operations:**

- ✅ Full observability stack (Prometheus + Grafana + AlertManager)
- ✅ Custom alerting for ML-specific metrics
- ✅ Runbooks for common operations
- ✅ Cost tracking and optimization

**Enterprise Features:**

- ✅ Multi-AZ deployment for high availability
- ✅ Encryption at rest (KMS)
- ✅ IRSA for fine-grained IAM permissions
- ✅ Cluster autoscaling for cost optimization
- ✅ VPC endpoints to reduce NAT costs

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         AWS Account                              │
│                                                                   │
│
┌────────────────────────────────────────────────────────────┐
│
│  │                      VPC (10.0.0.0/16)                     │ │
│  │                                                             │ │
│  │  ┌─────────────────┐         ┌─────────────────┐          │ │
│  │  │ Public Subnet   │         │ Public Subnet   │          │ │
│  │  │  us-east-1a     │         │  us-east-1b     │          │ │
│  │  │                 │         │                 │          │ │
│  │  │  NAT Gateway    │         │                 │          │ │
│  │  └────────┬────────┘         └─────────────────┘          │ │
│  │           │                                                │ │
│  │  ┌────────▼────────┐         ┌─────────────────┐          │ │
│  │  │ Private Subnet  │         │ Private Subnet  │          │ │
│  │  │  us-east-1a     │         │  us-east-1b     │          │ │
│  │  │                 │         │                 │          │ │
│  │  │  EKS Nodes      │         │  EKS Nodes      │          │ │
│  │  │  ┌──────────┐   │         │  ┌──────────┐   │          │ │
│  │  │  │ ML Pods  │   │         │  │ ML Pods  │   │          │ │
│  │  │  └──────────┘   │         │  └──────────┘   │          │ │
│  │  │  ┌──────────┐   │         │  ┌──────────┐   │          │ │
│  │  │  │Prometheus│   │         │  │ Grafana  │   │          │ │
│  │  │  └──────────┘   │         │  └──────────┘   │          │ │
│  │  └─────────────────┘         └─────────────────┘          │ │
│  │                                                             │ │
│  │  VPC Endpoints: S3, ECR                                    │ │
│
└─────────────────────────────────────────────────────────────┘
│
│                                                                   │
│  EKS Control Plane (Managed by AWS)                              │
│  KMS (Encryption Keys)                                            │
│  IAM Roles & IRSA                                                 │
└───────────────────────────────────────────────────────────────────┘
```

## 📦 What Gets Deployed

### Networking

- VPC with public and private subnets across 2 AZs
- NAT Gateway for private subnet internet access
- VPC Endpoints (S3, ECR) for cost optimization
- Security groups with least-privilege access

### Kubernetes (EKS)

- EKS 1.28 cluster with managed control plane
- Managed node group with 2-4 t3.medium instances
- Cluster autoscaler for automatic scaling
- AWS Load Balancer Controller
- EBS CSI Driver for persistent storage
- Metrics Server for HPA

### Monitoring Stack

- **Prometheus** - Metrics collection and storage
- **Grafana** - Visualization dashboards
- **AlertManager** - Alert routing and management
- **Pre-configured dashboards:**
  - ML Serving metrics (latency, throughput, errors)
  - Kubernetes cluster health
  - Cost tracking

### Security

- KMS encryption for EKS secrets
- IRSA for pod-level IAM permissions
- Private EKS API endpoint option
- Security groups with minimal access
- Non-root containers

## 💰 Cost Breakdown

**Monthly costs (dev environment):**

| Resource          | Configuration | Monthly Cost    |
| ----------------- | ------------- | --------------- |
| EKS Control Plane | Managed       | $73             |
| EC2 Nodes         | 2x t3.medium  | ~$120           |
| NAT Gateway       | Single NAT    | $32             |
| Load Balancer     | ALB           | ~$20            |
| EBS Volumes       | 150GB total   | ~$15            |
| Data Transfer     | Minimal       | ~$10            |
| **Total**         |               | **~$270/month** |

**Cost Optimization Tips:**

1. Use spot instances (70% savings): `enable_spot_instances = true`
2. Scale down to t3.small for dev: `node_instance_type = "t3.small"`
3. Use single NAT for dev (already configured)
4. Delete cluster when not in use: `terraform destroy`
5. Set AWS Budget alerts at $300/month

**Production costs** scale based on:

- Node count (autoscaling 2-10 nodes)
- Instance types
- Data transfer
- Typically $500-1500/month for medium traffic

## 🚀 Quick Start

### Prerequisites

```bash
# Install Terraform
brew install terraform  # macOS
# or download from terraform.io

# Install AWS CLI
brew install awscli
aws configure  # Set your credentials

# Install kubectl
brew install kubernetes-cli
```

### Deploy Infrastructure

```bash
# 1. Clone and navigate
git clone <your-repo>
cd ml-platform-terraform

# 2. Configure variables (optional)
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
# Edit terraform.tfvars with your preferences

# 3. Deploy (automated script)
chmod +x scripts/*.sh
./scripts/deploy.sh

# Or manual deployment:
cd terraform
terraform init
terraform plan
terraform apply

# 4. Configure kubectl
aws eks update-kubeconfig --region us-east-1 --name ml-platform-dev
kubectl get nodes
```

### Access Monitoring

```bash
# Grafana
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
# Open: http://localhost:3000
# Username: admin
# Password: (from variables.tf)

# Prometheus
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090
# Open: http://localhost:9090
```

## 📊 Monitoring & Alerts

### Pre-configured Alerts

The platform includes production-ready alerts:

**ML Serving:**

- High prediction latency (P95 > 100ms)
- High error rate (> 1%)
- No predictions received
- Model not loaded
- Anomalous fraud detection rates

**Kubernetes:**

- Pod restarts
- High CPU/memory usage
- Node issues
- HPA at max replicas

**Cost:**

- High node count
- Unused persistent volumes

### Alert Channels

Configure in `terraform/variables.tf`:

```hcl
slack_webhook_url = "https://hooks.slack.com/services/YOUR/WEBHOOK"
alert_email = "alerts@yourcompany.com"
```

### Dashboards

Three pre-configured Grafana dashboards:

1. **ML Serving** - Request rate, latency, errors, fraud rate
2. **Kubernetes** - Cluster health, resource usage
3. **Cost** - Resource consumption, estimated costs

## 🔧 Configuration

### Customize Variables

Edit `terraform/variables.tf` or create `terraform/terraform.tfvars`:

```hcl
# Basic Configuration
aws_region = "us-east-1"
environment = "dev"  # dev, staging, prod
owner = "your-email@example.com"

# Cost Optimization
node_instance_type = "t3.medium"    # or t3.small for dev
node_desired_size = 2
enable_spot_instances = false       # true for 70% savings

# Monitoring
grafana_admin_password = "secure-password"
slack_webhook_url = "https://..."
```

### Scaling Configuration

**Horizontal scaling** (number of nodes):

```hcl
node_min_size = 2
node_max_size = 4  # Increase for production
enable_cluster_autoscaler = true
```

**Vertical scaling** (node size):

```hcl
node_instance_type = "t3.large"  # 2 vCPU, 8GB
# or t3.xlarge (4 vCPU, 16GB)
# or t3.2xlarge (8 vCPU, 32GB)
```

## 🎓 What This Teaches

### Infrastructure as Code

- Terraform module structure
- State management
- Provider configuration
- Resource dependencies
- Output values

### AWS Best Practices

- Multi-AZ for high availability
- Private subnets for security
- VPC endpoints for cost optimization
- KMS encryption
- IAM IRSA for pod security

### Kubernetes Operations

- Cluster provisioning
- Add-on management
- Observability setup
- Cost optimization
- Security hardening

### Production Monitoring

- Metrics collection
- Custom alerting
- Dashboard design
- SLO tracking
- Incident response

## 🔐 Security

**Implemented:**

- ✅ Private subnets for nodes
- ✅ KMS encryption at rest
- ✅ IRSA for fine-grained permissions
- ✅ Security groups with least privilege
- ✅ VPC endpoints to avoid public internet
- ✅ EKS control plane logging (optional)

**For Production:**

- [ ] Private EKS API endpoint
- [ ] Network policies
- [ ] Pod security policies/standards
- [ ] Secrets management (AWS Secrets Manager)
- [ ] WAF on load balancers
- [ ] GuardDuty for threat detection

## 🧪 Testing

```bash
# Verify cluster
kubectl get nodes
kubectl get pods --all-namespaces

# Test monitoring
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80

# Check alerts
kubectl get prometheusrules -n monitoring

# View logs
kubectl logs -n monitoring -l app.kubernetes.io/name=prometheus
```

## 📚 Documentation

- [Setup Guide](docs/SETUP.md) - Detailed setup instructions
- [Architecture](docs/architecture.md) - In-depth architecture explanation
- [Cost Analysis](docs/cost-analysis.md) - Detailed cost breakdown
- [Runbook](docs/runbook.md) - Operations guide
- [ADRs](docs/architecture-decisions.md) - Architecture decision records

## 🐛 Troubleshooting

**Terraform Errors:**

```bash
# State lock issues
terraform force-unlock <lock-id>

# Refresh state
terraform refresh

# Destroy and recreate
terraform destroy
terraform apply
```

**EKS Access Issues:**

```bash
# Update kubeconfig
aws eks update-kubeconfig --region us-east-1 --name ml-platform-dev

# Check IAM
aws sts get-caller-identity

# Verify cluster
aws eks describe-cluster --name ml-platform-dev
```

**Pod Issues:**

```bash
# Check pod status
kubectl get pods --all-namespaces

# Describe pod
kubectl describe pod <pod-name>

# View logs
kubectl logs <pod-name>

# Check events
kubectl get events --sort-by='.lastTimestamp'
```

## 🗑️ Cleanup

**⚠️ This deletes everything!**

```bash
# Automated cleanup
./scripts/destroy.sh

# Or manual:
cd terraform
terraform destroy
```

Verify in AWS Console that all resources are deleted.

## 🤝 Contributing

This is a portfolio project, but improvements welcome:

1. Fork the repo
2. Create feature branch
3. Test changes thoroughly
4. Submit PR with explanation

## 📝 License

MIT License - Free to use for learning and portfolios

---

**Technologies:** Terraform · AWS · EKS · Kubernetes · Prometheus · Grafana · Helm

---

**Built with 💪 to demonstrate production Platform Engineering skills**
