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

# Phase 0 > Consul 설치, App 배포
#
#    terraform apply --auto-approve
#
# Phase 1 > Service Intention Test > 모든 주석 해제
#
#    terraform apply --auto-approve
#
#    배포확인
#      kubectl get serviceintentions -n consul
#      kubectl port-forward service/consul-ingress-gateway -n consul 8080:8080 --address 0.0.0.0  
#      http://localhost:8080 >> SUCCESS
#      http://localhost:8080/admin >> RBAC: access denied
#
#    UI 확인
#      kubectl port-forward service/consul-server --namespace consul 8501:8501
#      https://localhost:8501/ui/dc1/intentions
 