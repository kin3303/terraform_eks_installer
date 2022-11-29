# https://developer.hashicorp.com/consul/tutorials/kubernetes-features/kubernetes-layer7-observability

locals {
  domain     = "consul"
  namespace  = "consul"
  datacenter = "dc1"
}

module "eks_consul_installer_test" {
  source = "../eks/modules/terraform-aws-eks-consul"

  /*
global:
  enabled: true
  name: consul
  datacenter: dc1
  metrics:
    enabled: true
    enableAgentMetrics: true
    agentMetricsRetentionTime: "1m"
server:
  replicas: 1
ui:
  enabled: true
  metrics:
    enabled: true
    provider: "prometheus"
    baseURL: http://prometheus-server.default.svc.cluster.local
connectInject:
  enabled: true
  default: true
controller:
  enabled: true
*/
  #################################################################################
  # Global
  #################################################################################
  # General
  consul_domain     = local.domain
  server_datacenter = local.datacenter
  chart_namespace   = local.namespace
  create_namespace  = true

  # Matrix
  metrics_enabled      = true
  enable_agent_metrics = true
  ui_metrics_provider  = "prometheus"
  ui_metrics_base_url  = "http://prometheus-server.default.svc.cluster.local"

  # TLS
  tls_https_only = false


  #################################################################################
  # connectInject
  #################################################################################
  client_enable = true
  enable_connect_inject     = true
  connect_inject_by_default = true

  #################################################################################
  # Monitoring
  #################################################################################
  enable_prometheus = true
  enable_grafana    = true
}

# Check Result
#    aws eks --region ap-northeast-2 update-kubeconfig --name eks-cluster-dk
#    kubectl get pods --namespace default 
#    kubectl get pods --namespace consul
#
# Service 배포
#     kubectl apply -f .\k2tf\11_consul_monitoring\hashicups\
#     kubectl get pods --namespace default 
#     kubectl port-forward deploy/frontend 8080:80 
#     http://localhost:8080
#
# Traffic 발생
#     kubectl apply -f .\k2tf\11_consul_monitoring\traffic.yaml
#
# UI 활성화 확인
#    kubectl port-forward service/consul-server 8500:8500 -n consul
#    http://localhost:8500/ui/dc1/services
#
# Promethues 확인
#    kubectl port-forward deploy/prometheus-server 9090:9090
#    http://localhost:9090
#    sum by(__name__)({app="product-api"})!= 0
#
# Grafana
#    kubectl port-forward svc/grafana 3000:3000   
#    http://localhost:3000
#    Username : admin Password: password
#
# 정리
#  kubectl delete -f .\k2tf\11_consul_monitoring\traffic.yaml
#  kubectl delete -f .\k2tf\11_consul_monitoring\hashicups\
#   