resource "kubernetes_manifest" "logsensitivity_v2_constraint_template" {
  manifest = {
    "apiVersion" = "templates.gatekeeper.sh/v1beta1"
    "kind"       = "ConstraintTemplate"
    "metadata" = {
      "name" = "logsensitivity-v2"  # Renamed to avoid conflict
    }
    "spec" = {
      "crd" = {
        "spec" = {
          "names" = {
            "kind" = "LogSensitivityV2"  # Changed CRD kind to avoid duplication
          }
        }
      }
      "targets" = [
        {
          "target" = "admission.k8s.gatekeeper.sh"
          "rego" = <<-EOT
            package logsensitivity

            violation[{"msg": msg}] {
              input.review.object.kind == "Pod"
              input.review.object.spec.containers[_].env[_].name == "LOG_FIELDS"
              contains_sensitive_data(input.review.object.spec.containers[_].env[_].value)
              msg := "Pod contains sensitive log data (email, credit card, etc.)"
            }

            violation[{"msg": msg}] {
              input.review.object.kind == "ConfigMap"
              input.review.object.metadata.labels["app.kubernetes.io/name"] == "grafana"
              input.review.object.data["public"] == "true"
              msg := "Grafana dashboard should not be publicly accessible"
            }

            violation[{"msg": msg}] {
              input.review.object.kind == "ConfigMap"
              input.review.object.metadata.labels["app.kubernetes.io/name"] == "prometheus"
              contains_sensitive_data(input.review.object.data["metrics"])
              msg := "Prometheus metrics contain sensitive data"
            }

            contains_sensitive_data(log_fields) {
              log_fields[_] == "email"
            }

            contains_sensitive_data(log_fields) {
              log_fields[_] == "credit_card"
            }

            contains_sensitive_data(log_fields) {
              log_fields[_] == "ssn"
            }
          EOT
        }
      ]
    }
  }
}
