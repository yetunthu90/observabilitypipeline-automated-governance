# Wait for OPA Gatekeeper to be installed
resource "null_resource" "wait_for_gatekeeper" {
  depends_on = [helm_release.gatekeeper]

  provisioner "local-exec" {
    command = "kubectl wait --for=condition=Established crd/constrainttemplates.templates.gatekeeper.sh --timeout=60s"
  }
}

# Define Constraint for Data Sensitivity & Dashboard Access Control
resource "kubernetes_manifest" "log_sensitivity_constraint" {
  depends_on = [null_resource.wait_for_gatekeeper]  # Wait for OPA Gatekeeper to be installed

  manifest = {
    apiVersion = "constraints.gatekeeper.sh/v1beta1"
    kind       = "LogSensitivity"
    metadata = {
      name = "enforce-log-sensitivity"
    }
    spec = {
      enforcementAction = "warn"  # Set to "warn" mode
      match = {
        kinds = [
          {
            apiGroups = [""]
            kinds     = ["Pod"]  # Apply to Pods (for sensitive log fields)
          },
          {
            apiGroups = ["apps"]
            kinds     = ["ConfigMap"]  # Apply to ConfigMaps (for Grafana & Prometheus)
          }
        ]
      }
    }
  }
}
