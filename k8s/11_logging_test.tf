resource "kubernetes_deployment_v1" "myapp_1__deployment" {
  metadata {
    name = "myapp1-deployment"
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        app = "myapp1"
      }
    }

    template {
      metadata {
        name = "myapp1-pod"

        labels = {
          app = "myapp1"
        }
      }

      spec {
        container {
          name  = "myapp1-container"
          image = "kin3303/mynginx1"

          port {
            container_port = 80
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "myapp_1__lb_service" {
  metadata {
    name = "myapp1-lb-service"
  }

  spec {
    port {
      name        = "http"
      port        = 80
      target_port = "80"
    }

    selector = {
      app = kubernetes_deployment_v1.myapp_1__deployment.spec.0.selector.0.match_labels.app
    }

    type = "LoadBalancer"
  }
}