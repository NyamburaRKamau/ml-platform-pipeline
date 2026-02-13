output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.eks.cluster_endpoint
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = module.eks.cluster_security_group_id
}

output "cluster_iam_role_arn" {
  description = "IAM role ARN of the EKS cluster"
  value       = module.eks.cluster_iam_role_arn
}

output "region" {
  description = "AWS region"
  value       = var.aws_region
}

output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "private_subnets" {
  description = "Private subnet IDs"
  value       = module.vpc.private_subnets
}

output "public_subnets" {
  description = "Public subnet IDs"
  value       = module.vpc.public_subnets
}

output "configure_kubectl" {
  description = "Configure kubectl: run this command to update your kubeconfig"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}"
}

output "grafana_url" {
  description = "Grafana dashboard URL (after port-forward)"
  value       = var.enable_monitoring ? "kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80" : "Monitoring not enabled"
}

output "prometheus_url" {
  description = "Prometheus URL (after port-forward)"
  value       = var.enable_monitoring ? "kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090" : "Monitoring not enabled"
}

output "grafana_admin_user" {
  description = "Grafana admin username"
  value       = var.enable_monitoring ? "admin" : "N/A"
}

output "estimated_monthly_cost" {
  description = "Estimated monthly cost in USD"
  value       = <<-EOT
  EKS Control Plane: $73/month
  EC2 Nodes (${var.node_desired_size}x ${var.node_instance_type}): ~$${var.node_desired_size * 60}/month
  NAT Gateway: ${var.environment == "dev" ? "$32" : "$64"}/month
  EBS Volumes: ~$15/month
  Load Balancer: ~$20/month
  
  Total Estimated: ~$${73 + (var.node_desired_size * 60) + (var.environment == "dev" ? 32 : 64) + 15 + 20}/month
  
  Note: This is an estimate. Actual costs depend on data transfer, storage, and usage patterns.
  Use AWS Cost Explorer for accurate billing.
  EOT
}

output "cost_optimization_tips" {
  description = "Tips to reduce costs"
  value       = <<-EOT
  1. Use spot instances (set enable_spot_instances = true) for dev: Save 70%
  2. Enable cluster autoscaler to scale down during idle
  3. Use smaller instance types for dev (t3.small)
  4. Delete unused EBS volumes
  5. Use single NAT gateway for dev (already configured)
  6. Set up AWS Budget alerts at $100/month
  EOT
}
