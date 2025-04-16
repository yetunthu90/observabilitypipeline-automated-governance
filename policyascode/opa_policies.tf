resource "null_resource" "wait_for_logsensitivity_crd" {
  provisioner "local-exec" {
 command = "powershell.exe -Command \"for ($i = 0; $i -lt 30; $i++) { if (kubectl get constrainttemplates logsensitivity) { break } Start-Sleep -Seconds 2 }\""
  }

  depends_on = [kubernetes_manifest.log_sensitivity_template]
}

resource "kubernetes_manifest" "log_sensitivity_constraint" {
  depends_on = [null_resource.wait_for_logsensitivity_crd]

  manifest = {
    apiVersion = "constraints.gatekeeper.sh/v1beta1"
    kind       = "LogSensitivity"
    metadata = {
      name = "enforce-log-sensitivity"
    }
    spec = {
      enforcementAction = "deny"
      match = {
        kinds = [
          {
            apiGroups = [""]
            kinds     = ["Pod"]
          },
          {
            apiGroups = [""]
            kinds     = ["ConfigMap"]
          }
        ]
      }
    }
  }
}
