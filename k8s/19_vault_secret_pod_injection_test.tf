# https://developer.hashicorp.com/vault/tutorials/kubernetes/kubernetes-sidecar

 
resource "kubernetes_service_account_v1" "vault_sa" {
  metadata {
    name = "internal-app"
  }
  depends_on = [
    module.eks_vault_installer_test
  ]
}

resource "kubernetes_service_v1" "nlb_sample_service" {
  metadata {
    name      = "nlb-sample-service" 

    annotations = {
      "service.beta.kubernetes.io/aws-load-balancer-type" = "nlb"
      "external-dns.alpha.kubernetes.io/hostname" = "sample.idtplateer.com"
    }
  }

  spec {
    port {
      protocol    = "TCP"
      port        = 80
      target_port = "80"
    }

    selector = {
      app = "nginx"
    }

    type = "LoadBalancer"
  }

  depends_on = [
    module.eks_vault_installer_test
  ]
}

resource "kubernetes_deployment_v1" "example" {
  metadata {
    name      = "nlb-sample-app"
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "nginx"
      }
    }
    template {
      metadata {
        labels = {
          app = "nginx"
        }

#        annotations = {
#          "vault.hashicorp.com/agent-inject" = "true"
#          "vault.hashicorp.com/agent-inject-status" = "update"
#          "vault.hashicorp.com/role" = kubernetes_service_account_v1.vault_sa.metadata[0].name
#          "vault.hashicorp.com/agent-inject-secret-database-config.txt" = "internal/data/database/config"
#          "vault.hashicorp.com/agent-inject-template-database-config.txt" = <<EOF
#{{- with secret "internal/data/database/config" -}}
#postgresql://{{ .Data.data.username }}:{{ .Data.data.password }}@postgres:5432/wizard
#{{- end -}}
#          EOF
#        }        
      }

      spec {
        service_account_name = kubernetes_service_account_v1.vault_sa.metadata[0].name
        container {
          image = "nginx:1.21.6"
          name  = "nginx"

          resources {
            limits = {
              cpu    = "0.5"
              memory = "512Mi"
            }
            requests = {
              cpu    = "250m"
              memory = "50Mi"
            }
          }

          liveness_probe {
            http_get {
              path = "/"
              port = 80

              http_header {
                name  = "X-Custom-Header"
                value = "Awesome"
              }
            }

            initial_delay_seconds = 3
            period_seconds        = 3
          }
        }
      }
    }
  }

  depends_on = [
    module.eks_vault_installer_test
  ]
}

# Check Result
#    aws eks --region ap-northeast-2 update-kubeconfig --name eks-cluster-dk 
#
# Vault Secret Injection
#   Vault Secret 엔진 활성화 
#     경로 :  internal
#
#   Vault Secret 생성 
#     경로 : /database/config/username=dkim
#     경로 : /database/config/password=pw
#
#   Vault Policy 생성
#     이름 : internal-app
#     정책 : path "internal/data/database/config" { 
#                capabilities = ["read"] 
#            } 
#
#   Vault 에 kubernetes Auth 활성화 
#      Host 로 Kubernetes Endpoint 입력
#
#   Vault Kubernetes Auth 에서 Create Role
#      Name :  internal-app
#      Bound service account names : internal-app
#      Bound service account namespaces : default
#      Generated Token's Policies : internal-app
#
#   k8s deployment 에서 annotation 주석 풀고 terraform apply 하여 pod 에 vault secret 주입하기
#
#   배포된 app 확인
#      kubectl get pod 
#      kubectl exec -it nlb-sample-app-55d4d8d868-fclzx /bin/sh  
#      cd /vault/secrets
#      cat database-config.txt