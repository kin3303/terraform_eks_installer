
# Resource: FluentBit Agent ConfigMap
resource "kubernetes_config_map_v1" "fluentbit_cluster_info_configmap" {
  metadata {
    name      = "fluent-bit-cluster-info"
    namespace = kubernetes_namespace_v1.amazon_cloudwatch.metadata[0].name
  }
  data = {
    "cluster.name" = var.cluster_name
    "http.port"    = "2020"
    "http.server"  = "On"
    "logs.region"  = var.aws_region
    "read.head"    = "Off"
    "read.tail"    = "On"
  }
}

# Resources: FluentBit 
## - ServiceAccount
## - ClusterRole
## - ClusterRoleBinding
## - ConfigMap: fluent-bit-config
## - DaemonSet
data "http" "get_fluentbit_resources" {
  url = "https://raw.githubusercontent.com/aws-samples/amazon-cloudwatch-container-insights/latest/k8s-deployment-manifest-templates/deployment-mode/daemonset/container-insights-monitoring/fluent-bit/fluent-bit.yaml"
  # Optional request headers
  request_headers = {
    Accept = "text/*"
  }
}

data "kubectl_file_documents" "fluentbit_docs" {
  content = data.http.get_fluentbit_resources.body
}

resource "kubectl_manifest" "fluentbit_resources" {
  for_each  = data.kubectl_file_documents.fluentbit_docs.manifests
  yaml_body = each.value

  depends_on = [
    kubernetes_namespace_v1.amazon_cloudwatch,
    kubernetes_config_map_v1.fluentbit_cluster_info_configmap,
    kubectl_manifest.cwagent_daemonset
  ]
}
