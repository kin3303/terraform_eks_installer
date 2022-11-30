# https://developer.hashicorp.com/consul/tutorials/kubernetes-features/kubernetes-layer7-observability

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
  ui_metrics_provider  = "prometheus"
  ui_metrics_base_url  = "http://prometheus-server.default.svc.cluster.local"

  # TLS
  tls_https_only = false


  #################################################################################
  # connectInject
  #################################################################################
  client_enable             = true
  enable_connect_inject     = true
  connect_inject_by_default = true

  #################################################################################
  # Monitoring
  #################################################################################
  enable_prometheus = true
  enable_grafana    = true
}

#################################################################################
# Frontend
#################################################################################

resource "kubectl_manifest" "service_defaults_front" {
  yaml_body = <<YAML
apiVersion: consul.hashicorp.com/v1alpha1
kind: ServiceDefaults
metadata:
  name: frontend
spec:
  protocol: "http"
YAML
  depends_on = [
    module.eks_consul_installer_test
  ]
}

resource "kubectl_manifest" "service_intention_front" {
  yaml_body = <<YAML
apiVersion: consul.hashicorp.com/v1alpha1
kind: ServiceIntentions
metadata:
  name: frontend-to-public-api
spec:
  destination:
    name: public-api
  sources:
    - name: frontend
      action: allow
YAML
  depends_on = [
    module.eks_consul_installer_test,
    kubernetes_service_v1.frontend,
    kubernetes_service_v1.public_api
  ]
}

resource "kubectl_manifest" "nginx_configmap" {
  yaml_body = <<YAML
apiVersion: v1
kind: ConfigMap
metadata:
  name: nginx-configmap
data:
  config: |
    # /etc/nginx/conf.d/default.conf
    server {
        listen       80;
        server_name  localhost;

        #charset koi8-r;
        #access_log  /var/log/nginx/host.access.log  main;

        location / {
            root   /usr/share/nginx/html;
            index  index.html index.htm;
        }

        # Proxy pass the api location to save CORS
        # Use location exposed by Consul connect
        location /api {
            proxy_pass http://public-api.default.svc.cluster.local:8080;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "Upgrade";
            proxy_set_header Host $host;
        }

        error_page   500 502 503 504  /50x.html;
        location = /50x.html {
            root   /usr/share/nginx/html;
        }
    }
YAML
  depends_on = [
    module.eks_consul_installer_test
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
      port        = 80
      target_port = "80"
    }

    selector = {
      app = "frontend"
    }

    type = "ClusterIP"
  }
}

resource "kubernetes_service_account_v1" "frontend" {
  metadata {
    name = "frontend"
  }

  automount_service_account_token = true
  depends_on = [
    module.eks_consul_installer_test
  ]
}

resource "kubernetes_deployment_v1" "frontend" {
  metadata {
    name = "frontend"
  }

  spec {
    replicas = 1
    selector {
      match_labels = {
        app     = "frontend"
        service = "frontend"
      }
    }

    template {
      metadata {
        labels = {
          app     = "frontend"
          service = "frontend"
        }
      }

      spec {
        volume {
          name = "config"

          config_map {
            name = "nginx-configmap"

            items {
              key  = "config"
              path = "default.conf"
            }
          }
        }

        container {
          name  = "frontend"
          image = "hashicorpdemoapp/frontend:v0.0.3"

          port {
            container_port = 80
          }

          volume_mount {
            name       = "config"
            read_only  = true
            mount_path = "/etc/nginx/conf.d"
          }
        }

        service_account_name = "frontend"
      }
    }
  }
  depends_on = [
    module.eks_consul_installer_test,
    kubectl_manifest.nginx_configmap
  ]
}


#################################################################################
# Postgres
#################################################################################

resource "kubectl_manifest" "service_default_postgres" {
  yaml_body = <<YAML
apiVersion: consul.hashicorp.com/v1alpha1
kind: ServiceDefaults
metadata:
  name: postgres
spec:
  protocol: tcp
YAML
  depends_on = [
    module.eks_consul_installer_test
  ]
}


resource "kubernetes_service_account_v1" "postgres" {
  metadata {
    name = "postgres"
  } 

  automount_service_account_token = true
  depends_on = [
    module.eks_consul_installer_test
  ]  
}


resource "kubernetes_service_v1" "postgres" {
  metadata {
    name = "postgres"

    labels = {
      app = "postgres"
    }
  }

  spec {
    port {
      port        = 5432
      target_port = 5432
    }

    selector = {
      app = "postgres"
    }

    type = "ClusterIP"
  }
  depends_on = [
    module.eks_consul_installer_test,
    kubectl_manifest.service_default_postgres
  ]
}
 
resource "kubectl_manifest" "postgres" {
  yaml_body = <<YAML
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgres
spec:
  replicas: 1
  selector:
    matchLabels:
      service: postgres
      app: postgres
  template:
    metadata:
      labels:
        service: postgres
        app: postgres
    spec:
      serviceAccountName: postgres
      containers:
        - name: postgres
          image: hashicorpdemoapp/product-api-db:v0.0.11
          ports:
            - containerPort: 5432
          env:
            - name: POSTGRES_DB
              value: products
            - name: POSTGRES_USER
              value: postgres
            - name: POSTGRES_PASSWORD
              value: password
          # only listen on loopback so only access is via connect proxy
          args: ["-c", "listen_addresses=127.0.0.1"]
          volumeMounts:
            - mountPath: "/var/lib/postgresql/data"
              name: "pgdata"
      volumes:
        - name: pgdata
          emptyDir: {}
YAML
  depends_on = [
    module.eks_consul_installer_test 
  ]
}


#################################################################################
# Product API
#################################################################################
resource "kubectl_manifest" "service_default_product" {
  yaml_body = <<YAML
apiVersion: consul.hashicorp.com/v1alpha1
kind: ServiceDefaults
metadata:
  name: product-api
spec:
  protocol: "http"
YAML
  depends_on = [
    module.eks_consul_installer_test
  ]
}

resource "kubectl_manifest" "service_intention_product" {
  yaml_body = <<YAML
apiVersion: consul.hashicorp.com/v1alpha1
kind: ServiceIntentions
metadata:
  name: product-api-to-postgres
spec:
  destination:
    name: postgres
  sources:
    - name: product-api
      action: allow
YAML
  depends_on = [
    module.eks_consul_installer_test,
    kubernetes_service_v1.postgres,
    kubernetes_service_v1.product_api
  ]
}


resource "kubectl_manifest" "db_configmap" {
  yaml_body = <<YAML
apiVersion: v1
kind: ConfigMap
metadata:
  name: db-configmap
data:
  config: |
    {
      "db_connection": "host=postgres.default.svc.cluster.local port=5432 user=postgres password=password dbname=products sslmode=disable",
      "bind_address": ":9090",
      "metrics_address": ":9103"
    }
YAML
  depends_on = [
    module.eks_consul_installer_test
  ]
}

resource "kubectl_manifest" "deployment_product_api" {
  yaml_body = <<YAML
apiVersion: apps/v1
kind: Deployment
metadata:
  name: product-api
  labels:
    app: product-api
spec:
  replicas: 1
  selector:
    matchLabels:
      app: product-api
  template:
    metadata:
      labels:
        app: product-api
    spec:
      serviceAccountName: product-api
      volumes:
      - name: config
        configMap:
          name: db-configmap
          items:
          - key: config
            path: conf.json
      containers:
        - name: product-api
          image: hashicorpdemoapp/product-api:v0.0.12
          ports:
            - containerPort: 9090
            - containerPort: 9103
          env:
            - name: "CONFIG_FILE"
              value: "/config/conf.json"
          livenessProbe:
            httpGet:
              path: /health
              port: 9090
            initialDelaySeconds: 15
            timeoutSeconds: 1
            periodSeconds: 10
            failureThreshold: 30
          volumeMounts:
            - name: config
              mountPath: /config
              readOnly: true
YAML
  depends_on = [
    module.eks_consul_installer_test,
    kubectl_manifest.db_configmap
  ]  
}

resource "kubernetes_service_account_v1" "product_api" {
  metadata {
    name = "product-api"
  }

  automount_service_account_token = true
  depends_on = [
    module.eks_consul_installer_test
  ]
}

resource "kubernetes_service_v1" "product_api" {
  metadata {
    name = "product-api"
  }

  spec {
    port {
      name        = "http"
      protocol    = "TCP"
      port        = 9090
      target_port = 9090
    }

    selector = {
      app = "product-api"
    }
  }
  depends_on = [
    module.eks_consul_installer_test,
    kubectl_manifest.service_default_product
  ]
}

 

#################################################################################
# Public API
#################################################################################
resource "kubectl_manifest" "service_default_public" {
  yaml_body = <<YAML
apiVersion: consul.hashicorp.com/v1alpha1
kind: ServiceDefaults
metadata:
  name: public-api
spec:
  protocol: "http"
YAML
  depends_on = [
    module.eks_consul_installer_test
  ]
}

resource "kubectl_manifest" "service_intention_public" {
  yaml_body = <<YAML
apiVersion: consul.hashicorp.com/v1alpha1
kind: ServiceIntentions
metadata:
  name: public-api-to-product-api
spec:
  destination:
    name: product-api
  sources:
    - name: public-api
      action: allow
YAML
  depends_on = [
    module.eks_consul_installer_test,
    kubernetes_service_v1.public_api,
    kubernetes_service_v1.product_api
  ]
}

resource "kubernetes_service_account_v1" "public_api" {
  metadata {
    name = "public-api"
  }

  automount_service_account_token = true
  depends_on = [
    module.eks_consul_installer_test
  ]
}


resource "kubernetes_service_v1" "public_api" {
  metadata {
    name = "public-api"

    labels = {
      app = "public-api"
    }
  }

  spec {
    port {
      port        = 8080
      target_port = "8080"
    }

    selector = {
      app = "public-api"
    }

    type = "ClusterIP"
  }

  depends_on = [
    module.eks_consul_installer_test,
    kubectl_manifest.service_default_public
  ]
}

resource "kubectl_manifest" "public_api" {
  yaml_body = <<YAML
apiVersion: apps/v1
kind: Deployment
metadata:
  name: public-api
spec:
  replicas: 1
  selector:
    matchLabels:
      service: public-api
      app: public-api
  template:
    metadata:
      labels:
        service: public-api
        app: public-api
    spec:
      serviceAccountName: public-api
      containers:
        - name: public-api
          image: hashicorpdemoapp/public-api:v0.0.3
          ports:
            - containerPort: 8080
          env:
            - name: BIND_ADDRESS
              value: ":8080"
            - name: PRODUCT_API_URI
              value: "http://product-api.default.svc.cluster.local:9090"
YAML
  depends_on = [
    module.eks_consul_installer_test
  ]
}
 

# Check Result
#    aws eks --region ap-northeast-2 update-kubeconfig --name eks-cluster-dk
#    kubectl get pods --namespace default 
#    kubectl get pods --namespace consul
#
# Service 확인 
#     kubectl port-forward deploy/frontend 8080:80 
#     http://localhost:8080 
#
# UI 활성화 확인
#    kubectl port-forward service/consul-server 8500:8500 -n consul
#    http://localhost:8500/ui/dc1/services
#
# Promethues 확인
#    kubectl port-forward deploy/prometheus-server 9090:9090
#    http://localhost:9090
#    sum by(__name__)({app="product-api"})!= 0
#
# Grafana
#    kubectl port-forward svc/grafana 3000:3000   
#    http://localhost:3000
#    Username : admin Password: password
#
# 정리
#  terraform destroy --auto-approve
