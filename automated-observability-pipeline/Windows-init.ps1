# Port-forward for frontend
Start-Process kubectl -ArgumentList "port-forward deployment/frontend 8080:8080" -NoNewWindow

# Port-forward for Prometheus
Start-Process kubectl -ArgumentList "port-forward svc/prometheus-operator-kube-p-prometheus 9090:9090" -NoNewWindow

# Port-forward for Grafana
Start-Process kubectl -ArgumentList "port-forward svc/prometheus-operator-grafana -n default 3000:80" -NoNewWindow

Write-Host "Port-forwarding is running in the background. Use 'Stop-PortForward' to stop it."

# Function to stop port-forwarding
function Stop-PortForward {
    Get-Process kubectl | Stop-Process -Force
    Write-Host "Port-forwarding stopped."
}