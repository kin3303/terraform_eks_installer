# https://developer.hashicorp.com/consul/tutorials/kubernetes/kubernetes-custom-resource-definitions

locals {
  domain     = "consul"
  namespace  = "consul"
  datacenter = "dc1"
}

module "eks_consul_installer_test" {
  source = "../eks/modules/terraform-aws-eks-consul"

  #################################################################################
  # Global
  #################################################################################
  # General
  consul_domain     = local.domain
  consul_datacenter = local.datacenter
  chart_namespace   = local.namespace
  create_namespace  = true

  # Matrix
  metrics_enabled      = true
  enable_agent_metrics = true 

  # Gossip Encryption
  gossip_enable_auto_generate = true
 
  # RPC Encryption
  tls_enabled = true
  #tls_enable_auto_encrypt = true
  #tls_https_only = false
  tls_verify = false
 
  # ACL
  manage_system_acls = true  

  #################################################################################
  # client
  #################################################################################
  client_enable = true

  #################################################################################
  # connectInject
  #################################################################################
  enable_connect_inject     = true
  connect_inject_by_default = true
  connect_inject_default_enable_merging = true
 
}

#################################################################################
# Counting
#################################################################################
resource "kubernetes_service_account_v1" "counting" {
  metadata {
    name      = "counting"
    namespace = "default"
  }

  automount_service_account_token = true
  depends_on = [
    module.eks_consul_installer_test
  ]  
}

resource "kubernetes_service_v1" "counting" {
  metadata {
    name      = "counting"
    namespace = "default"

    labels = {
      app = "counting"
    }
  }

  spec {
    port {
      port        = 9001
      target_port = "9001"
    }

    selector = {
      app = "counting"
    }

    type = "ClusterIP"
  }
  depends_on = [
    module.eks_consul_installer_test
  ]  
}

resource "kubernetes_deployment_v1" "counting" {
  metadata {
    name = "counting"

    labels = {
      app = "counting"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "counting"
      }
    }

    template {
      metadata {
        labels = {
          app = "counting"
        }

        annotations = {
          "consul.hashicorp.com/connect-inject" = "true"
        }
      }

      spec {
        container {
          name  = "counting"
          image = "hashicorp/counting-service:0.0.2"

          port {
            container_port = 9001
          }

          image_pull_policy = "IfNotPresent"
        }

        service_account_name = "counting"
      }
    }
  }
  depends_on = [
    module.eks_consul_installer_test
  ]
}

#################################################################################
# Dashboard
#################################################################################
resource "kubernetes_service_account_v1" "dashboard" {
  metadata {
    name      = "dashboard"
    namespace = "default"
  }

  automount_service_account_token = true
  depends_on = [
    module.eks_consul_installer_test
  ]  
}

resource "kubernetes_service_v1" "dashboard" {
  metadata {
    name      = "dashboard"
    namespace = "default"

    labels = {
      app = "dashboard"
    }
  }

  spec {
    port {
      port        = 9002
      target_port = "9002"
    }

    selector = {
      app = "dashboard"
    }

    type = "ClusterIP"
  }
  depends_on = [
    module.eks_consul_installer_test
  ]  
}

resource "kubernetes_deployment_v1" "dashboard" {
  metadata {
    name = "dashboard"

    labels = {
      app = "dashboard"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "dashboard"
      }
    }

    template {
      metadata {
        labels = {
          app = "dashboard"
        }

        annotations = {
          "consul.hashicorp.com/connect-inject" = "true"
          "consul.hashicorp.com/connect-service-upstreams" = "counting:9001"
        }
      }

      spec {
        container {
          name  = "dashboard"
          image = "hashicorp/dashboard-service:0.0.4"

          port {
            container_port = 9002
          }

          env {
            name  = "COUNTING_SERVICE_URL"
            value = "http://localhost:9001"
          }

          image_pull_policy = "IfNotPresent"
        }

        service_account_name = "dashboard"
      }
    }
  }
  depends_on = [
    module.eks_consul_installer_test
  ]  
}

#################################################################################
# Intention - ACL 이 Enable 인 경우 deny all 이 활성화 되며 Intention 을 명시적으로 설정 필요
#################################################################################
resource "kubectl_manifest" "service_intention" {
  yaml_body = <<YAML
apiVersion: consul.hashicorp.com/v1alpha1
kind: ServiceIntentions
metadata:
  name: dashboard-to-counting
spec:
  destination:
    name: counting
  sources:
    - name: dashboard
      action: allow
YAML
  depends_on = [
    module.eks_consul_installer_test,
    kubernetes_service_v1.dashboard,
    kubernetes_service_v1.counting
  ]
}

# Check Result
#    aws eks --region ap-northeast-2 update-kubeconfig --name eks-cluster-dk 
# 
# ACL Token 정보 얻기 
#    > kubectl get secret --namespace consul consul-bootstrap-acl-token -o jsonpath="{.data.token}"
#       OThlOGNhZWQtYWZiNS1iYzE1LThkNGYtOTU5Y2EzNDBiYmU0
#    > [Text.Encoding]::Utf8.GetString([Convert]::FromBase64String('OThlOGNhZWQtYWZiNS1iYzE1LThkNGYtOTU5Y2EzNDBiYmU0'))
#        98e8caed-afb5-bc15-8d4f-959ca340bbe4 
#    > $env:CONSUL_HTTP_TOKEN = "98e8caed-afb5-bc15-8d4f-959ca340bbe4"
#
# UI
#    kubectl port-forward svc/consul-ui --namespace consul 8443:443
#    https://localhost:8443
#    ACL Token 으로 로그인
# 
# App
#    kubectl port-forward svc/dashboard --namespace default 9002:9002
#    http://localhost:9002
#
# 정리
#  terraform destroy --auto-approve
