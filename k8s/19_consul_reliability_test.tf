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
  ui_metrics_provider = "prometheus"
  ui_metrics_base_url = "http://prometheus-server.default.svc.cluster.local"
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
    kubectl_manifest.frontend_service_intention
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
    kubectl_manifest.backend_service_intention
  ]
}


resource "kubectl_manifest" "backend_router" {
  yaml_body = <<YAML
apiVersion: consul.hashicorp.com/v1alpha1
kind: ServiceRouter
metadata:
  name: backend
spec:
  routes:
    - destination:
        numRetries: 5 
        retryOnStatusCodes: [503]
YAML
  depends_on = [ 
    kubectl_manifest.deny_all_service_intention
  ]
}


resource "kubernetes_deployment_v1" "frontend" {
  metadata {
    name = "frontend"

    labels = {
      app = "frontend"
    }
    annotations = {
      "sidecar.jaegertracing.io/inject" = "true"
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
          "consul.hashicorp.com/connect-inject" = "true" 
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

          env {
            name  = "TRACING_URL"
            value = "http://jaeger-collector.default:9411" 
          }          
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

    annotations = {
      "sidecar.jaegertracing.io/inject" = "true"
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
          "consul.hashicorp.com/connect-inject" = "true"
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

          env {
            name  = "TRACING_URL"
            value = "http://jaeger-collector.default:9411" 
          }

          readiness_probe {
            http_get {
              path = "/healthz"
              port = "9999" # "7000"
            }
            period_seconds = 5
          }
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
#   terraform apply --auto-approve 
#
# Phase 1 > Passive Health Check  > readiness_probe  제외 모든 주석 해제 
#
#   terraform apply --auto-approve
#
#   Service 재시작
#      kubectl get proxydefaults global -n consul >> SYNCED 확인
#      kubectl get servicerouter backend  >> SYNCED 확인
#      kubectl rollout restart deploy/consul-ingress-gateway -n consul
#      kubectl rollout restart deploy/frontend
#      kubectl rollout restart deploy/backend
#      kubectl rollout status deploy/consul-ingress-gateway --watch -n consul
#      kubectl rollout status deploy/frontend --watch
#      kubectl rollout status deploy/frontend --watch

#    App
#      kubectl port-forward service/consul-ingress-gateway -n consul 8080:8080 --address 0.0.0.0  
#      http://localhost:8080 
#      Error Ratio 를 100% 로 수정후 Shuffle
#
#    Jaeger
#       kubectl port-forward svc/jaeger-query 16686:16686   
#       http://localhost:16686
#       요청을 5번 했는지 확인
#
#    Consul UI 
#      kubectl port-forward service/consul-server --namespace consul 8501:8501
#      https://localhost:8501/ui
#      Backend 서비스 활성 상태 확인, Circuit Break 검사 
#
# Phase 3 > Active Health Check > readiness_probe 주석 해제
#
#    서비스 비활성 상태 확인
#      kubectl port-forward service/consul-server --namespace consul 8501:8501
#      https://localhost:8501/ui
#      Service > Instances > Health Checks 항목서 Backend 서비스 Readiness Probe 실패 및 서비스 비활성 상태 확인
#    
#    서비스 활성 상태 확인
#      port = "9999" # "7000" 을 7000 으로 변경 후 terraform apply --auto-approve
#      kubectl port-forward service/consul-server --namespace consul 8501:8501
#      https://localhost:8501/ui
#      Service > Instances > Health Checks 항목서 Backend 서비스 Readiness Probe 성공 및 서비스 활성 상태 확인