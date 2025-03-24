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

            violation[{"msg": msg}] {
              input.review.object.kind == "Pod"
              input.review.object.spec.containers[_].env[_].name == "LOG_FIELDS"
              contains_sensitive_data(input.review.object.spec.containers[_].env[_].value)
              msg := "Log contains sensitive data"
            }

            contains_sensitive_data(log_fields) {
              log_fields[_] == "email"
            }

            contains_sensitive_data(log_fields) {
              log_fields[_] == "credit_card"
            }
          EOT
        }
      ]
    }
  }
}
