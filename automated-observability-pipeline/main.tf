provider "kubernetes" {
  config_path = "~/.kube/config"  # Minikube's kubeconfig path
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"  # Minikube's kubeconfig path
  }
}

# Install Prometheus using Helm
resource "helm_release" "prometheus" {
  name       = "prometheus-operator"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  namespace  = "default"

  set {
    name  = "prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues"
    value = "false"
  }
}

# ServiceMonitor for Frontend
resource "kubernetes_manifest" "frontend_servicemonitor" {
  manifest = {
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "ServiceMonitor"
    metadata = {
      name = "frontend-servicemonitor"
      namespace = "default"
      labels = {
        release = "prometheus-operator"
      }
    }
    spec = {
      selector = {
        matchLabels = {
          app = "frontend"
        }
      }
      endpoints = [
        {
          port     = "http"
          path     = "/metrics"
          interval = "30s"
        }
      ]
    }
  }
}

# OpenTelemetry Collector ConfigMap
resource "kubernetes_config_map" "otel_collector_config" {
  metadata {
    name      = "otel-collector-config"
    namespace = "default"
  }

  data = {
    "otel-collector-config.yaml" = <<-EOT
    receivers:
      prometheus:
        config:
          scrape_configs:
            - job_name: 'frontend'
              scrape_interval: 10s
              static_configs:
                - targets: ['frontend-service:8080']  # Use the frontend service name
    processors:
      batch:
        send_batch_size: 10000
        timeout: 10s
    exporters:
      prometheus:
        endpoint: '0.0.0.0:9090'
        namespace: 'frontend'
        send_timestamps: true
      debug:
        verbosity: detailed
    service:
      pipelines:
        metrics:
          receivers: [prometheus]
          processors: [batch]
          exporters: [prometheus, debug]
    EOT
  }
}

# OpenTelemetry Collector Deployment
resource "kubernetes_deployment" "otel_collector" {
  metadata {
    name      = "otel-collector"
    namespace = "default"
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "otel-collector"
      }
    }

    template {
      metadata {
        labels = {
          app = "otel-collector"
        }
      }

      spec {
        container {
          name  = "otel-collector"
          image = "otel/opentelemetry-collector-contrib:latest"

          volume_mount {
            name       = "otel-collector-config-vol"
            mount_path = "/etc/otelcol"
            read_only  = true
          }

          args = ["--config", "/etc/otelcol/otel-collector-config.yaml"]
        }

        volume {
          name = "otel-collector-config-vol"

          config_map {
            name = kubernetes_config_map.otel_collector_config.metadata[0].name
          }
        }
      }
    }
  }
}

# OpenTelemetry Collector Service
resource "kubernetes_service" "otel_collector" {
  metadata {
    name      = "otel-collector"
    namespace = "default"
  }

  spec {
    selector = {
      app = "otel-collector"
    }

    port {
      port        = 9090
      target_port = 9090
      protocol    = "TCP"
    }
  }
}