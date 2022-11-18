
### https://github.com/gavinbunney/terraform-provider-kubectl/issues/61

## Resource: Namespace

resource "kubernetes_namespace_v1" "amazon_cloudwatch" {
  metadata {
    name = "amazon-cloudwatch"
  }
}

# Resource: Service Account, ClusteRole, ClusterRoleBinding
data "http" "get_cwagent_serviceaccount" {
  url = "https://raw.githubusercontent.com/aws-samples/amazon-cloudwatch-container-insights/latest/k8s-deployment-manifest-templates/deployment-mode/daemonset/container-insights-monitoring/cwagent/cwagent-serviceaccount.yaml"
  # Optional request headers
  request_headers = {
    Accept = "text/*"
  }
}

data "kubectl_file_documents" "cwagent_docs" {
  content = data.http.get_cwagent_serviceaccount.body
}

resource "kubectl_manifest" "cwagent_serviceaccount" {
  count     = length(data.kubectl_file_documents.cwagent_docs.manifests)
  yaml_body = element(data.kubectl_file_documents.cwagent_docs.manifests, count.index)

  depends_on = [
    kubernetes_namespace_v1.amazon_cloudwatch
  ]
}



# Resource: Daemonset
data "http" "get_cwagent_daemonset" {
  url = "https://raw.githubusercontent.com/aws-samples/amazon-cloudwatch-container-insights/latest/k8s-deployment-manifest-templates/deployment-mode/daemonset/container-insights-monitoring/cwagent/cwagent-daemonset.yaml"
  # Optional request headers
  request_headers = {
    Accept = "text/*"
  }
}

resource "kubectl_manifest" "cwagent_daemonset" {
  yaml_body = data.http.get_cwagent_daemonset.body

  depends_on = [
    kubernetes_namespace_v1.amazon_cloudwatch,
    kubernetes_config_map_v1.cwagentconfig_configmap,
    kubectl_manifest.cwagent_serviceaccount
  ]
}