###########################################################################
# EKS Install Test
###########################################################################
resource "kubernetes_namespace" "lbtest" {
  metadata {
    name = "lbtest"
  }
}

resource "kubernetes_service_v1" "nlb_sample_service" {
  metadata {
    name      = "nlb-sample-service"
    namespace = "lbtest"

    annotations = {
      "service.beta.kubernetes.io/aws-load-balancer-type" = "nlb"
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
}

resource "kubernetes_deployment_v1" "nlb_sample_app" {
  metadata {
    name      = "nlb-sample-app"
    namespace = "lbtest"
  }

  spec {
    replicas = 3

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
      }

      spec {
        container {
          name  = "nginx"
          image = "public.ecr.aws/nginx/nginx:1.21"

          port {
            name           = "tcp"
            container_port = 80
          }
        }
      }
    }
  }
}

# terraform init
# terraform apply --auto-approve
# aws eks --region ap-northeast-2 update-kubeconfig --name eks-cluster-dk
# kubectl get all -n lbtest
# terraform destroy --auto-approve
# kubectl get all -n lbtest

###########################################################################
# IRSA Test
###########################################################################
resource "kubernetes_service_account_v1" "s3_readonly_sa" {
  metadata {
    name = var.sa_s3_readonly

    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.irsa_s3_read_only_role.arn
    }
  }
}

resource "kubernetes_job_v1" "irsa_test" {
  metadata {
    name = "irsa-test"

    labels = {
      app = "irsa-test"
    }
  }

  spec {
    template {
      metadata {
        labels = {
          app = "irsa-test"
        }
      }

      spec {
        container {
          name    = "irsa-test"
          image   = "amazon/aws-cli:latest"
          command = ["aws", "s3", "ls"]
        }

        restart_policy       = "Never"
        service_account_name =  var.sa_s3_readonly
      }
    }
  }
}

# kubectl get sa
# kubectl get job
# kubectl describe job irsa-test
# kubectl logs -f -l app=irsa-test  --max-log-requests=100
# terraform state list
#   terraform taint kubernetes_job_v1.irsa_test
#   terraform apply --auto-approve
# terraform apply -replace kubernetes_job_v1.irsa_test

