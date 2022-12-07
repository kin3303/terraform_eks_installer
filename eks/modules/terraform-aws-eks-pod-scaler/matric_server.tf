# https://artifacthub.io/packages/helm/metrics-server/metrics-server
resource "helm_release" "metrics_server_release" {
  name              = local.resource_names.matric_server_name
  repository        = "https://kubernetes-sigs.github.io/metrics-server/"
  chart             = "metrics-server"
  namespace         = "kube-system"
  cleanup_on_fail   = true
  dependency_update = true
}

