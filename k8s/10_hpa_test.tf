resource "kubernetes_deployment_v1" "myapp3" {
  metadata {
    name = "app3-nginx-deployment"
    labels = {
      app = "app3-nginx"
    }
  } 
 
  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "app3-nginx"
      }
    }

    template {
      metadata {
        labels = {
          app = "app3-nginx"
        }
      }

      spec {
        container {
          image = "k8s.gcr.io/hpa-example"
          name  = "app3-nginx"
          port {
            container_port = 80
          }
          resources {
            limits = {
              cpu = "500m"
            }
            requests = {
              cpu = "200m"
            }
          }
          }
        }
      }
    }
}

resource "kubernetes_service_v1" "myapp3_cip_service" {
  metadata {
    name = "app3-nginx-cip-service"
  }
  spec {
    selector = {
      app = kubernetes_deployment_v1.myapp3.spec.0.selector.0.match_labels.app
    }
    port {
      name        = "http"
      port        = 80
      target_port = 80
    }
    type = "ClusterIP"
  }
}

resource "kubernetes_horizontal_pod_autoscaler_v1" "hpa_myapp3" {
  metadata {
    name = "hpa-app3"
  }
  spec {
    max_replicas = 10
    min_replicas = 1
    scale_target_ref {
      api_version = "apps/v1"
      kind = "Deployment"
      name = kubernetes_deployment_v1.myapp3.metadata[0].name 
    }
    target_cpu_utilization_percentage = 50
  }
}

# Run Load Test (New Terminal)
#    aws eks --region ap-northeast-2 update-kubeconfig --name eks-cluster-dk
#    kubectl run -i --tty load-generator --rm --image=busybox --restart=Never -- /bin/sh -c "while sleep 0.01; do wget -q -O- http://app3-nginx-cip-service; done"
#    kubectl get hpa