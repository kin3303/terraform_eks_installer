
###########################################################################
# Consul on Terraform 
#     Consul Helm Chart
#         https://github.com/hashicorp/consul-k8s
#         https://developer.hashicorp.com/consul/docs/k8s/helm
#
#     Consul Install
#         https://developer.hashicorp.com/consul/docs/k8s/installation/install  
#
#     Tutorials
#        https://developer.hashicorp.com/consul/tutorials/get-started-kubernetes
#        https://github.com/hashicorp/learn-consul-kubernetes/tree/main/service-mesh/deploy
#
#     Use Cases
#        https://developer.hashicorp.com/consul/tutorials/kubernetes
#  
#     Web Search
#         https://istio.io/latest/docs/examples/bookinfo/
#         https://www.linkedin.com/pulse/how-easily-setup-consul-service-mesh-aws-eks-ihar-vauchok 
###########################################################################
locals {
  domain     = "consul"
  namespace  = "consul"
  datacenter = "dc1"
}

module "eks_consul_installer" {
  source = "../eks/modules/terraform-aws-eks-consul"

  #################################################################################
  # Global
  #################################################################################
  server_datacenter           = local.datacenter
  consul_domain               = local.domain
  chart_namespace             = local.namespace
  gossip_enable_auto_generate = true
  ## consul keygen
  #gossip_encryption_key       = "/jNppi4XKThMjr2GyKh3suNyxdnal4f6rp2QHKwNyR0="
  tls_enable_auto_encrypt = true
  ## consul tls ca create 
  ## consul tls cert create -server -days 730 -domain consul -ca consul-agent-ca.pem -key consul-agent-ca-key.pem -dc dc1 
  #tls_ca_cert             = "D:/Workspaces/Terraform/eks_installer/certificate/consul-agent-ca.pem"
  #tls_ca_cert_key         = "D:/Workspaces/Terraform/eks_installer/certificate/consul-agent-ca-key.pem"
  #tls_server_cert         = "D:/Workspaces/Terraform/eks_installer/certificate/dc1-server-consul-0.pem"
  #tls_server_cert_key     = "D:/Workspaces/Terraform/eks_installer/certificate/dc1-server-consul-0-key.pem"
  metrics_enabled      = true
  enable_agent_metrics = true


  #################################################################################
  # Server
  #################################################################################  
  connect_enable = true

  #################################################################################
  # ConnectInject
  #################################################################################    
  enable_connect_inject                 = true
  connect_inject_by_default             = true
  connect_inject_default_enable_merging = true

  #################################################################################
  # ingressGateways
  #################################################################################    
  ingress_gateway_enable = false
  ingress_gateways = [
    {
      name = "ingress-gateway"
      service = {
        type = "LoadBalancer"
        ports = [
          {
            nodePort = null
            port     = 80
          }
        ]
      }
      consulNamespace = local.namespace
    }
  ]

  #################################################################################
  # Prometheus
  #################################################################################
  enable_prometheus = true

  #################################################################################
  # Test
  #################################################################################
  enable_test_pod = false
}


# Check EFS Static Provisioning
#    aws eks --region ap-northeast-2 update-kubeconfig --name eks-cluster-dk
#    kubectl port-forward service/consul-consul-server --namespace consul 8501:8501
#    https://localhost:8501/ui/dc1/services
#
#    kubectl create namespace bookinfo
#    kubectl apply -f ../k8s/k2tf/09_consul/productpage/ -n bookinfo
#    kubectl apply -f ../k8s/k2tf/09_consul/review/ -n bookinfo
#    kubectl apply -f ../k8s/k2tf/09_consul/rating/ -n bookinfo
#    kubectl apply -f ../k8s/k2tf/09_consul/detailview/ -n bookinfo

#################################################################################
# Backend Service
#################################################################################
resource "kubernetes_service_account" "api_v_1" {
  metadata {
    name = "api-v1"
  }
  depends_on = [
    module.eks_consul_installer
  ]
}

resource "kubernetes_service" "api_v_1" {
  metadata {
    name = "api-v1"
  }

  spec {
    port {
      port        = 9091
      target_port = 9091
    }

    selector = {
      app = "api-v1"
    }
  }
  depends_on = [
    module.eks_consul_installer
  ]  
}

resource "kubernetes_deployment" "api_v_1" {
  metadata {
    name = "api-v1"

    labels = {
      app = "api-v1"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "api-v1"
      }
    }

    template {
      metadata {
        labels = {
          app = "api-v1"
        }

        annotations = {
          "consul.hashicorp.com/connect-inject" = "true"
        }
      }

      spec {
        container {
          name  = "api"
          image = "nicholasjackson/fake-service:v0.7.8"

          port {
            container_port = 9091
          }

          env {
            name  = "LISTEN_ADDR"
            value = "127.0.0.1:9091"
          }

          env {
            name  = "NAME"
            value = "api-v1"
          }

          env {
            name  = "MESSAGE"
            value = "Response from API v1"
          }
        }
      }
    }
  }
  depends_on = [
    module.eks_consul_installer
  ]    
}

#################################################################################
# Frontend Service
#################################################################################
resource "kubernetes_service_account" "web" {
  metadata {
    name = "web"
  }

  depends_on = [
    module.eks_consul_installer
  ]      
}

resource "kubernetes_service" "web" {
  metadata {
    name = "web"
  }

  spec {
    port {
      port        = 9090
      target_port = "9090"
    }

    selector = {
      app = "web"
    }
  }

  depends_on = [
    module.eks_consul_installer
  ]      
}


resource "kubernetes_deployment" "web_deployment" {
  metadata {
    name = "web-deployment"

    labels = {
      app = "web"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "web"
      }
    }

    template {
      metadata {
        labels = {
          app = "web"
        }

        annotations = {
          "consul.hashicorp.com/connect-inject" = "true"
          "consul.hashicorp.com/connect-service-upstreams" = "api-v1:9091"
        }
      }

      spec {
        container {
          name  = "web"
          image = "nicholasjackson/fake-service:v0.7.8"

          port {
            container_port = 9090
          }

          env {
            name  = "LISTEN_ADDR"
            value = "0.0.0.0:9090"
          }

          env {
            name  = "UPSTREAM_URIS"
            value = "http://localhost:9091"
          }

          env {
            name  = "NAME"
            value = "web"
          }

          env {
            name  = "MESSAGE"
            value = "Hello World"
          }
        }
      }
    }
  }

  depends_on = [
    module.eks_consul_installer
  ]      
}

# https://developer.hashicorp.com/consul/tutorials/kubernetes/service-mesh-application-secure-networking
# kubectl port-forward service/web 9090:9090 --address 0.0.0.0
# http://localhost:9090/ui