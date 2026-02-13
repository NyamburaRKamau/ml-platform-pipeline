# Prometheus and Grafana monitoring stack

# Create monitoring namespace
resource "kubernetes_namespace" "monitoring" {
  count = var.enable_monitoring ? 1 : 0

  metadata {
    name = "monitoring"
    labels = {
      name = "monitoring"
    }
  }

  depends_on = [module.eks]
}

# Prometheus Stack (includes Prometheus, Grafana, AlertManager)
resource "helm_release" "prometheus_stack" {
  count = var.enable_monitoring ? 1 : 0

  name       = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = "55.0.0"
  namespace  = kubernetes_namespace.monitoring[0].metadata[0].name

  values = [
    templatefile("${path.module}/../monitoring/prometheus-values.yaml", {
      grafana_admin_password = var.grafana_admin_password
      slack_webhook_url      = var.slack_webhook_url
      alert_email            = var.alert_email
    })
  ]

  set {
    name  = "prometheus.prometheusSpec.retention"
    value = "7d"
  }

  set {
    name  = "prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.resources.requests.storage"
    value = "50Gi"
  }

  set {
    name  = "grafana.adminPassword"
    value = var.grafana_admin_password
  }

  set {
    name  = "grafana.persistence.enabled"
    value = "true"
  }

  set {
    name  = "grafana.persistence.size"
    value = "10Gi"
  }

  depends_on = [
    kubernetes_namespace.monitoring,
    aws_eks_addon.ebs_csi
  ]
}

# ConfigMap for additional Prometheus rules
resource "kubernetes_config_map" "prometheus_rules" {
  count = var.enable_monitoring ? 1 : 0

  metadata {
    name      = "ml-platform-rules"
    namespace = kubernetes_namespace.monitoring[0].metadata[0].name
    labels = {
      prometheus = "kube-prometheus"
    }
  }

  data = {
    "ml-platform-rules.yaml" = file("${path.module}/../monitoring/prometheus/alert-rules.yaml")
  }

  depends_on = [helm_release.prometheus_stack]
}

# ConfigMap for Grafana dashboards
resource "kubernetes_config_map" "grafana_dashboards" {
  count = var.enable_monitoring ? 1 : 0

  metadata {
    name      = "ml-platform-dashboards"
    namespace = kubernetes_namespace.monitoring[0].metadata[0].name
    labels = {
      grafana_dashboard = "1"
    }
  }

  data = {
    "ml-serving-dashboard.json" = file("${path.module}/../monitoring/grafana/dashboards/ml-serving-dashboard.json")
    "kubernetes-dashboard.json" = file("${path.module}/../monitoring/grafana/dashboards/kubernetes-dashboard.json")
    "cost-dashboard.json" = file("${path.module}/../monitoring/grafana/dashboards/cost-dashboard.json")
  }

  depends_on = [helm_release.prometheus_stack]
}

# Cluster Autoscaler (if enabled)
resource "helm_release" "cluster_autoscaler" {
  count = var.enable_cluster_autoscaler ? 1 : 0

  name       = "cluster-autoscaler"
  repository = "https://kubernetes.github.io/autoscaler"
  chart      = "cluster-autoscaler"
  version    = "9.29.3"
  namespace  = "kube-system"

  set {
    name  = "autoDiscovery.clusterName"
    value = module.eks.cluster_name
  }

  set {
    name  = "awsRegion"
    value = var.aws_region
  }

  set {
    name  = "rbac.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.cluster_autoscaler_irsa[0].iam_role_arn
  }

  set {
    name  = "extraArgs.scale-down-enabled"
    value = "true"
  }

  set {
    name  = "extraArgs.scale-down-delay-after-add"
    value = "5m"
  }

  set {
    name  = "extraArgs.scale-down-unneeded-time"
    value = "10m"
  }

  depends_on = [module.eks]
}

# Metrics Server (required for HPA)
resource "helm_release" "metrics_server" {
  name       = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  version    = "3.11.0"
  namespace  = "kube-system"

  set {
    name  = "args[0]"
    value = "--kubelet-insecure-tls"
  }

  depends_on = [module.eks]
}

# AWS Load Balancer Controller
module "aws_load_balancer_controller_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name = "${var.project_name}-aws-load-balancer-controller"

  attach_load_balancer_controller_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
    }
  }

  tags = {
    Name = "${var.project_name}-alb-controller-role"
  }
}

resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = "1.6.2"
  namespace  = "kube-system"

  set {
    name  = "clusterName"
    value = module.eks.cluster_name
  }

  set {
    name  = "serviceAccount.create"
    value = "true"
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.aws_load_balancer_controller_irsa.iam_role_arn
  }

  depends_on = [module.eks]
}
