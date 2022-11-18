###########################################################################
# Namespace
###########################################################################
resource "kubernetes_namespace_v1" "amazon_cloudwatch" {
  metadata {
    name = "amazon-cloudwatch"
  }
  depends_on = [
    module.eks
  ]
}

###########################################################################
# Cloudwatch Agent Install
###########################################################################
resource "kubernetes_config_map_v1" "cwagentconfig_configmap" {
  metadata {
    name = "cwagentconfig" 
    namespace = kubernetes_namespace_v1.amazon_cloudwatch.metadata[0].name 
  }
  data = {
    "cwagentconfig.json" = jsonencode({
      "logs": {
        "metrics_collected": {
          "kubernetes": {
            "metrics_collection_interval": 60
          }
        },
        "force_flush_interval": 5
      }
    })
  }
}

#-----------------------------------------------------------------------------
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
  for_each  = data.kubectl_file_documents.cwagent_docs.manifests
  yaml_body = each.value

  depends_on = [
    kubernetes_namespace_v1.amazon_cloudwatch
  ]
}

#-----------------------------------------------------------------------------
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

###########################################################################
# Fluentbit Install
###########################################################################

resource "kubernetes_config_map_v1" "fluentbit_cluster_info_configmap" {
  metadata {
    name      = "fluent-bit-cluster-info"
    namespace = kubernetes_namespace_v1.amazon_cloudwatch.metadata[0].name
  }
  data = {
    "cluster.name" = module.eks.eks_cluster.cluster_id
    "http.port"    = "2020"
    "http.server"  = "On"
    "logs.region"  = var.aws_region
    "read.head"    = "Off"
    "read.tail"    = "On"
  }
}

#-----------------------------------------------------------------------------
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
