resource "kubernetes_manifest" "log_sensitivity_template" {
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
          "rego"   = <<-EOT
            package logsensitivity

            # Sensitive keys (log fields)
            sensitive_keys := {"email", "user_id", "credit_card", "ssn"}

            # Main violation check for sensitive data in Pod logs
            violation[{"msg": msg}] {
              input.review.object.kind == "Pod"
              container := input.review.object.spec.containers[_]
              env := container.env[_]
              env.name == "LOG_FIELDS"
              sensitive_key := sensitive_keys[_]
              contains(env.value, sensitive_key)
              msg := sprintf("Pod contains sensitive data in container '%s' (LOG_FIELDS: %s)", [container.name, env.value])
            }

            # Prevent Grafana dashboards from being exposed publicly
            violation[{"msg": msg}] {
              input.review.object.kind == "ConfigMap"
              input.review.object.metadata.labels["app.kubernetes.io/name"] == "grafana"
              input.review.object.data["public"] == "true"
              msg := "Grafana dashboard should not be publicly accessible"
            }
          EOT
        }
      ]
    }
  }
}
