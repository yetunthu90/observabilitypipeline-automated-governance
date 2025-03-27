resource "kubernetes_manifest" "logsensitivity_constraint_template" {
  manifest = {
    "apiVersion" = "templates.gatekeeper.sh/v1beta1"
    "kind"       = "ConstraintTemplate"
    "metadata" = {
      "name" = "logsensitivity"
    }
    "spec" = {
      "crd" = {
        "spec" = {
          "names" = {
            "kind" = "LogSensitivity"
          }
        }
      }
      "targets" = [
        {
          "target" = "admission.k8s.gatekeeper.sh"
          "rego" = <<-EOT
            package logsensitivity

            # Prevent Pods from exposing sensitive log fields
            violation[{"msg": msg}] {
              input.review.object.kind == "Pod"
              input.review.object.spec.containers[_].env[_].name == "LOG_FIELDS"
              contains_sensitive_data(input.review.object.spec.containers[_].env[_].value)
              msg := "Pod contains sensitive log data (email, credit card, etc.)"
            }

            # Prevent Grafana dashboards from being exposed publicly
            violation[{"msg": msg}] {
              input.review.object.kind == "ConfigMap"
              input.review.object.metadata.labels["app.kubernetes.io/name"] == "grafana"
              input.review.object.data["public"] == "true"
              msg := "Grafana dashboard should not be publicly accessible"
            }

            # Restrict Prometheus metrics from containing sensitive data
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
