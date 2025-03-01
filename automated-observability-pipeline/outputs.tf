output "prometheus_operator_release_name" {
  value = helm_release.prometheus.name
}

output "otel_collector_service_name" {
  value = kubernetes_service.otel_collector.metadata[0].name
}