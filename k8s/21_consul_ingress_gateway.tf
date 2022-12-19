


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

  # connectInject 
  enable_connect_inject                 = true
  connect_inject_by_default             = false
  connect_inject_default_enable_merging = false

  # acl
  manage_system_acls = false

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
YAML
  depends_on = [
    module.eks_consul_installer,
    kubernetes_service_v1.frontend,
    kubernetes_service_v1.backend
  ]
}

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
            value = "http://backend" #"http://localhost:7000"
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

# Phase 0 > Consul 설치
# Phase 1 > deployment annotation 주석을 모두 비활성화 후 terraform apply
# Phase 2 > deployment annotation 주석을 활성화 후 terraform apply
# Phase 3 > ingress_gateway 활성화 후 terraform apply
#
# 배포확인  
#    kubectl get deployment,service --selector app=frontend
#    kubectl get deployment,service --selector app=backend
#    kubectl get ingressgateway ingress-gateway -n consul >> SYNCED == false 확인
#    kubectl describe ingressgateway ingress-gateway -n consul
#
# 접근확인
#    kubectl exec consul-server-0 -n consul -- curl -sS http://frontend.default:6060 
#    kubectl exec deploy/frontend -c frontend -- curl -si http://backend/bird
#    kubectl port-forward service/frontend 6060:6060 --address 0.0.0.0
#    http://localhost:6060
#
# Phase 4 > proxy_default 활성화 후 terraform apply
#     kubectl get ingressgateway ingress-gateway -n consul  >> SYNCED == true 확인
#
# UI 활성화 확인
#    kubectl port-forward service/consul-server --namespace consul 8501:8501
#    https://localhost:8501/ui/dc1/services
#