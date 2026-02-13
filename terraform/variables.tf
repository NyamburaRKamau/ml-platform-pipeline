variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "owner" {
  description = "Owner email for cost tracking"
  type        = string
  default     = "your-email@example.com"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "ml-platform"
}

# Networking
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Availability zones for multi-AZ deployment"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

# EKS Cluster
variable "cluster_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.28"
}

variable "node_instance_type" {
  description = "EC2 instance type for worker nodes"
  type        = string
  default     = "t3.medium"  # 2 vCPU, 4GB RAM - $0.0416/hour
}

variable "node_desired_size" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 2
}

variable "node_min_size" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 2
}

variable "node_max_size" {
  description = "Maximum number of worker nodes"
  type        = number
  default     = 4
}

# Monitoring
variable "enable_monitoring" {
  description = "Enable Prometheus and Grafana monitoring"
  type        = bool
  default     = true
}

variable "grafana_admin_password" {
  description = "Grafana admin password"
  type        = string
  sensitive   = true
  default     = "change-me-in-production"
}

# Alerting
variable "slack_webhook_url" {
  description = "Slack webhook URL for alerts (optional)"
  type        = string
  sensitive   = true
  default     = ""
}

variable "alert_email" {
  description = "Email for critical alerts"
  type        = string
  default     = "alerts@example.com"
}

# Cost Control
variable "enable_cluster_autoscaler" {
  description = "Enable cluster autoscaler to reduce costs"
  type        = bool
  default     = true
}

variable "enable_spot_instances" {
  description = "Use spot instances for cost savings (not recommended for prod)"
  type        = bool
  default     = false
}

