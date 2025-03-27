provider "kubernetes" {
  config_path = "~/.kube/config"  # Minikube's kubeconfig path
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"  # Minikube's kubeconfig path
  }
}
# Install OPA Gatekeeper using Helm
resource "helm_release" "gatekeeper" {
  name       = "gatekeeper"
  repository = "https://open-policy-agent.github.io/gatekeeper/charts"
  chart      = "gatekeeper"
  namespace  = "default"

}