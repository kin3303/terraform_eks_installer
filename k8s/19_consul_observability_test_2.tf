locals {
  domain     = "consul"
  namespace  = "consul"
  datacenter = "dc1"
}

module "eks_consul_installer" {
  source           = "../eks/modules/terraform-aws-eks-consul"
  create_namespace = true
  chart_namespace  = local.namespace

  # global
  consul_datacenter = local.datacenter
  consul_domain     = local.domain

  # global.gossipEncryption
  gossip_enable_auto_generate = true

  # global.tls
  tls_enable_auto_encrypt = true

  # client
  client_enable = true

  # global.metrics
  metrics_enabled        = true
  enable_agent_metrics   = true
  enable_gateway_metrics = true
  
  # ui
  ui_metrics_provider  = "prometheus"
  ui_metrics_base_url  = "http://prometheus-server.default.svc.cluster.local"  
  #ui_dashboard_url_templates =  "http://localhost:3000/d/<YOUR_ID>/services?orgId=1&var-Service={{Service.Name}}"

  # tls
  tls_https_only = false
  
  # connectInject 
  enable_connect_inject                 = true
  connect_inject_by_default             = false
  connect_inject_default_enable_merging = false

  # acl
  manage_system_acls = false
  
  # monitoring
  enable_prometheus = true
  enable_grafana    = true
  enable_jaeger     = true

  # ingressGateways    
  ingress_gateway_enable = true
  ingress_gateways = [
    {
      name = "ingress-gateway"
      service = {
        type = "ClusterIP"
        ports = [
          {
            nodePort = null
            port     = 8080
          }
        ]
      }
      consulNamespace = local.namespace
    }
  ]
}

/*
resource "kubectl_manifest" "ingress_gateway" {
  yaml_body = <<YAML
apiVersion: consul.hashicorp.com/v1alpha1
kind: IngressGateway
metadata:
  name: ingress-gateway 
  namespace: consul 
spec:
  listeners:
  - port: 8080 
    protocol: http 
    services: 
    - name: frontend 
      hosts: ["localhost"]
YAML
  depends_on = [
    module.eks_consul_installer,
    kubernetes_service_v1.frontend,
    kubernetes_service_v1.backend
  ]
}

resource "kubectl_manifest" "proxy_default" {
  yaml_body = <<YAML
apiVersion: consul.hashicorp.com/v1alpha1
kind: ProxyDefaults 
metadata:
  name: global 
  namespace: consul 
spec:
  config:
    protocol: http
    envoy_tracing_json: | 
      {
        "http":{
          "name":"envoy.tracers.zipkin",
          "typedConfig":{
            "@type":"type.googleapis.com/envoy.config.trace.v3.ZipkinConfig",
            "collector_cluster":"jaeger_collector",
            "collector_endpoint_version":"HTTP_JSON",
            "collector_endpoint":"/api/v2/spans",
            "shared_span_context":false
          }
        }
      }
    envoy_extra_static_clusters_json: | 
      {
        "connect_timeout":"3.000s",
        "dns_lookup_family":"V4_ONLY",
        "lb_policy":"ROUND_ROBIN",
        "load_assignment":{
          "cluster_name":"jaeger_collector",
          "endpoints":[
            {
              "lb_endpoints":[
                {
                  "endpoint":{
                    "address":{
                      "socket_address":{
                        "address":"jaeger-collector.default",
                        "port_value":9411, 
                        "protocol":"TCP"
                      }
                    }
                  }
                }
              ]
            }
          ]
        },
        "name":"jaeger_collector",
        "type":"STRICT_DNS"
      }    
YAML
  depends_on = [
    module.eks_consul_installer,
    kubernetes_service_v1.frontend,
    kubernetes_service_v1.backend
  ]
}

resource "kubectl_manifest" "frontend_service_intention" {
  yaml_body = <<YAML
apiVersion: consul.hashicorp.com/v1alpha1
kind: ServiceIntentions
metadata:
  name: frontend
spec:
  destination:
    name: frontend
  sources:
    - name: ingress-gateway
      permissions: 
        - http:
            pathPrefix: /admin 
          action: deny
        - http:
            pathPrefix: / 
          action: allow
YAML
  depends_on = [
    kubectl_manifest.proxy_default
  ]
}

resource "kubectl_manifest" "backend_service_intention" {
  yaml_body = <<YAML
apiVersion: consul.hashicorp.com/v1alpha1
kind: ServiceIntentions
metadata:
  name: backend
  namespace: consul   
spec:
  destination:
    name: backend 
  sources:
    - name: frontend
      action: allow
YAML
  depends_on = [
    kubectl_manifest.proxy_default
  ]
}

resource "kubectl_manifest" "deny_all_service_intention" {
  yaml_body = <<YAML
apiVersion: consul.hashicorp.com/v1alpha1
kind: ServiceIntentions
metadata:
  name: deny-all
  namespace: consul
spec:
  destination:
    name: "*" # 대상 서비스명
  sources:
    - name: "*"    # 소스 서비스명
      action: deny  # 통신을 허용하거나 거부하도록 설정
YAML
  depends_on = [ 
    kubectl_manifest.proxy_default
  ]
}
*/


resource "kubernetes_deployment_v1" "frontend" {
  metadata {
    name = "frontend"

    labels = {
      app = "frontend"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "frontend"
      }
    }

    template {
      metadata {
        labels = {
          app = "frontend"
        }

        annotations = {
          #"consul.hashicorp.com/connect-inject" = "true"
          #"sidecar.jaegertracing.io/inject" = "true"
        }
      }

      spec {
        container {
          name  = "frontend"
          image = "ghcr.io/consul-up/birdwatcher-frontend:1.0.0"

          port {
            container_port = 6060
          }

          env {
            name  = "BIND_ADDR"
            value = "0.0.0.0:6060"
          }

          env {
            name  = "BACKEND_URL"
            value = "http://backend"
          }
          
          #env {
          #  name  = "TRACING_URL"
          #  value = "http://jaeger-collector.default:9411" 
          #}          
        }
      }
    }
  }
  depends_on = [
    module.eks_consul_installer,
    kubernetes_service_v1.backend
  ]
}

resource "kubernetes_service_v1" "frontend" {
  metadata {
    name = "frontend"
    labels = {
      app = "frontend"
    }
  }

  spec {
    port {
      name        = "http"
      port        = 6060
      target_port = 6060
    }

    selector = {
      app = kubernetes_deployment_v1.frontend.spec[0].selector[0].match_labels.app
    }

  }
  depends_on = [
    module.eks_consul_installer,
    kubernetes_deployment_v1.frontend
  ]
}

resource "kubernetes_deployment_v1" "backend" {
  metadata {
    name = "backend"

    labels = {
      app = "backend"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "backend"
      }
    }

    template {
      metadata {
        labels = {
          app = "backend"
        }
        annotations = {
          #"consul.hashicorp.com/connect-inject" = "true"
          #"sidecar.jaegertracing.io/inject" = "true"
        }
      }

      spec {
        container {
          name  = "backend"
          image = "ghcr.io/consul-up/birdwatcher-backend:1.0.0"

          port {
            container_port = 7000
          }

          env {
            name  = "BIND_ADDR"
            value = "0.0.0.0:7000"
          }

          #env {
          #  name  = "TRACING_URL"
          #  value = "http://jaeger-collector.default:9411" 
          #}  
        }
      }
    }
  }
  depends_on = [
    module.eks_consul_installer
  ]
}

resource "kubernetes_service_v1" "backend" {
  metadata {
    name = "backend"
    labels = {
      app = "backend"
    }
  }

  spec {
    port {
      protocol    = "TCP"
      port        = 80
      target_port = 7000
    }

    selector = {
      app = kubernetes_deployment_v1.backend.spec[0].selector[0].match_labels.app
    }
  }
  depends_on = [
    module.eks_consul_installer,
    kubernetes_deployment_v1.backend
  ]
}

# Phase 0 > Consul 설치, App 배포
#
#    terraform apply --auto-approve
#
# Phase 1 > Service Intention Test > 모든 주석 해제
#
#    terraform apply --auto-approve
#
#    배포확인 
#      kubectl port-forward service/consul-ingress-gateway -n consul 8080:8080 --address 0.0.0.0  
#      http://localhost:8080 >> SUCCESS
#      http://localhost:8080/admin >> RBAC: access denied
#
# Phase 2 > Promethues, Grafana, Consul UI 확인
#
#    Promethues 확인
#      kubectl port-forward deploy/prometheus-server 9090:9090
#      http://localhost:9090 
#      envoy_http_downstream_rq_completed 확인
#
#    Consul UI 
#      kubectl port-forward service/consul-server --namespace consul 8501:8501
#      https://localhost:8501/ui/dc1/intentions
# 
#    Grafana
#       kubectl port-forward svc/grafana 3000:3000   
#       http://localhost:3000
#
#       Username : admin Password: password
#
#       Data sources : Prometheus / http://prometheus-server.default.svc.cluster.local
#
#       Dashboard Settings-> Variables
#           Name : Service
#           Query : label_values(consul_source_service)
#
#       Add a new panel - RPS 
#         sum(
#           rate(
#             envoy_http_downstream_rq_completed{
#               consul_source_service="$Service",
#               envoy_http_conn_manager_prefix="public_listener"
#             }[$__rate_interval]]
#           )
#         ) 
#         
#       Add a new panel - Error(%) 
#         sum(
#           rate(
#             envoy_http_downstream_rq_xx{
#               consul_source_service="$Service",
#               envoy_http_conn_manager_prefix=~"public_listener",
#               envoy_response_code_class="5"
#             }[$__rate_interval]]
#           )
#         ) /
#         sum(
#           rate(
#             envoy_http_downstream_rq_completed{
#               consul_source_service="$Service",
#               envoy_http_conn_manager_prefix=~"public_listener"
#             }[$__rate_interval]]
#           )
#         )
#         
#      Add a new panel - Latency 
#         histogram_quantile(
#           0.5,
#           sum(
#             rate(
#               envoy_http_downstream_rq_time_bucket{
#                 consul_source_service="$Service",
#                 envoy_http_conn_manager_prefix=~"public_listener"
#               }[$__rate_interval]]
#             )
#           ) by (le)
#         )  
#         
#         histogram_quantile(
#           0.99,
#           sum(
#             rate(
#               envoy_http_downstream_rq_time_bucket{
#                 consul_source_service="$Service",
#                 envoy_http_conn_manager_prefix=~"public_listener"
#               }[$__rate_interval]]
#             )
#           ) by (le)
#         )  
#
# Phase 3 > Grafana 와 Consul 연동하기
#
#    ui_dashboard_url_templates 에 ID 적절히 넣어 URL Template 완성한 후 terraform apply
# 
#    App
#      kubectl port-forward service/consul-ingress-gateway -n consul 8080:8080 --address 0.0.0.0  
#      http://localhost:8080 
#
#    Grafana
#       kubectl port-forward svc/grafana 3000:3000   
#       http://localhost:3000
#
#    Consul UI 
#      kubectl port-forward service/consul-server --namespace consul 8501:8501
#      https://localhost:8501/ui
#      Grafana 열리는지 확인
#
# Phase 4 > Jaeger 연동 확인
#
#   App 수정
#       https://www.digitalocean.com/community/tutorials/how-to-implement-distributed-tracing-with-jaeger-on-kubernetes
#
#   Service 재시작
#      kubectl get proxydefaults global -n consul >> SYNCED 확인
#      kubectl rollout restart deploy/consul-ingress-gateway -n consul
#      kubectl rollout restart deploy/frontend
#      kubectl rollout restart deploy/backend
#      ubectl rollout status deploy/consul-ingress-gateway --watch -n consul
#      kubectl rollout status deploy/frontend --watch
#      kubectl rollout status deploy/frontend --watch
#
#    App
#      kubectl port-forward service/consul-ingress-gateway -n consul 8080:8080 --address 0.0.0.0  
#      http://localhost:8080 
#
#    Jaeger
#       kubectl port-forward svc/jaeger-query 16686:16686   
#       http://localhost:16686
