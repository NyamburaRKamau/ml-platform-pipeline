# Operations Runbook

## Common Operations

### Accessing the Cluster

```bash
# Configure kubectl
aws eks update-kubeconfig --region us-east-1 --name ml-platform-dev

# Verify access
kubectl get nodes
kubectl get pods --all-namespaces
```

### Scaling

**Scale nodes:**
```bash
# Via Terraform
# Edit terraform/variables.tf:
node_desired_size = 3

terraform apply

# Or manually in AWS Console
```

**Scale application:**
```bash
# Scale ML serving deployment
kubectl scale deployment ml-serving --replicas=5

# Or edit HPA
kubectl edit hpa ml-serving-hpa
```

### Monitoring

**Access Grafana:**
```bash
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
# Open http://localhost:3000
# Username: admin
# Password: <from variables>
```

**Access Prometheus:**
```bash
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090
# Open http://localhost:9090
```

**View alerts:**
```bash
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-alertmanager 9093:9093
# Open http://localhost:9093
```

### Troubleshooting

**Pod not starting:**
```bash
# Check pod status
kubectl describe pod <pod-name>

# View logs
kubectl logs <pod-name>

# Check events
kubectl get events --sort-by='.lastTimestamp'

# Common issues:
# - Image pull errors: Check ECR permissions
# - Insufficient resources: Scale up nodes
# - Crashlooping: Check application logs
```

**High latency:**
```bash
# Check metrics
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80

# Check pod resources
kubectl top pods

# Scale if needed
kubectl scale deployment ml-serving --replicas=10
```

**Out of memory:**
```bash
# Check memory usage
kubectl top pods
kubectl top nodes

# Increase pod memory limits
kubectl edit deployment ml-serving

# Or scale nodes
# Edit terraform/variables.tf: node_instance_type = "t3.large"
```

## Incident Response

### High Error Rate

1. **Check Grafana** - ML Serving dashboard
2. **View logs:**
   ```bash
   kubectl logs -l app=ml-serving --tail=100
   ```
3. **Check recent deployments:**
   ```bash
   kubectl rollout history deployment ml-serving
   ```
4. **Rollback if needed:**
   ```bash
   kubectl rollout undo deployment ml-serving
   ```

### Cluster Down

1. **Check EKS status:**
   ```bash
   aws eks describe-cluster --name ml-platform-dev
   ```
2. **Check nodes:**
   ```bash
   kubectl get nodes
   ```
3. **If nodes down, check AWS Console:**
   - EC2 Auto Scaling Group
   - EKS Node Group status

### Cost Spike

1. **Check node count:**
   ```bash
   kubectl get nodes
   ```
2. **Check AWS Cost Explorer** in console
3. **Review resources:**
   ```bash
   kubectl get pvc --all-namespaces
   kubectl get svc --all-namespaces
   ```
4. **Scale down if appropriate:**
   ```bash
   kubectl scale deployment ml-serving --replicas=2
   ```

## Maintenance

### Update Kubernetes Version

```bash
# 1. Update in Terraform
# Edit terraform/eks.tf: cluster_version = "1.29"

# 2. Apply
terraform apply

# 3. Update node group
# AWS will handle this automatically
```

### Rotate Credentials

```bash
# Rotate Grafana password
kubectl edit secret -n monitoring prometheus-grafana

# Update in Terraform too
```

### Backup

```bash
# Backup Grafana dashboards
kubectl get configmap -n monitoring ml-platform-dashboards -o yaml > grafana-backup.yaml

# Backup Prometheus rules
kubectl get configmap -n monitoring ml-platform-rules -o yaml > prometheus-backup.yaml
```

## Emergency Contacts

- Platform Team: platform@company.com
- On-call: +1-555-0100
- AWS Support: (if Enterprise support)
