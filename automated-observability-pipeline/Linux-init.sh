#!/bin/bash

# Port-forward for frontend
kubectl port-forward deployment/frontend 8080:8080 > /dev/null 2>&1 &

# Port-forward for Prometheus
kubectl port-forward svc/prometheus-operator-kube-p-prometheus 9090:9090 > /dev/null 2>&1 &

# Port-forward for Grafana
kubectl port-forward svc/prometheus-operator-grafana -n default 3000:80 > /dev/null 2>&1 &

echo "Port-forwarding is running in the background. Use 'pkill -f kubectl' to stop it."