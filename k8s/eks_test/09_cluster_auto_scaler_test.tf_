resource "kubernetes_deployment_v1" "ca_demo_deployment" {
  metadata {
    name = "ca-demo-deployment"

    labels = {
      app = "ca-nginx"
    }
  }

  spec {
    replicas = 1 #20

    selector {
      match_labels = {
        app = "ca-nginx"
      }
    }

    template {
      metadata {
        labels = {
          app = "ca-nginx"
        }
      }

      spec {
        container {
          name  = "ca-nginx"
          image = "nginx:latest"

          port {
            container_port = 80
          }

          resources {
            requests = {
              cpu = "200m"

              memory = "200Mi"
            }
          }
        }
      }
    }
  }
}        

resource "kubernetes_service_v1" "ca_demo_service_nginx" {
  metadata {
    name = "ca-demo-service-nginx"

    labels = {
      app = "ca-nginx"
    }
  }

  spec {
    port {
      port        = 80
      target_port = "80"
    }

    selector = {
      app = "ca-nginx"
    }

    type = "LoadBalancer"
  }
}
