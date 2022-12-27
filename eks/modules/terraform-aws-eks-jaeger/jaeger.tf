resource "helm_release" "jaeger_operator" {
  name              = var.release_name
  chart             = var.chart_name
  repository        = var.chart_repository
  version           = var.chart_version
  namespace         = var.chart_namespace
  max_history       = var.max_history
  timeout           = var.chart_timeout
  create_namespace  = false
  cleanup_on_fail   = true
  dependency_update = true

  set {
    name  = "rbac.clusterRole"
    value = true
  }  
}


resource "kubectl_manifest" "jaeger" {
  yaml_body = <<YAML
apiVersion: jaegertracing.io/v1
kind: Jaeger
metadata:
  name: jaeger
spec:
  query:
    serviceType: ClusterIP
  ingress:
    enabled: false
YAML

  depends_on = [
    helm_release.jaeger_operator
  ]
}

/*
resource "kubectl_manifest" "jaeger" {
  yaml_body = <<YAML
apiVersion: jaegertracing.io/v1
kind: Jaeger
metadata:
  name: jaeger
spec:
  strategy: allInOne
  allInOne:
    image: jaegertracing/all-in-one:latest
    options:
      log-level: debug
  storage:
    type: memory
    options:
      memory:
      max-traces: 100000
  ingress:
    enabled: false
  agent:
    strategy: agent
  annotations:
    scheduler.alpha.kubernetes.io/critical-pod:
YAML

  depends_on = [
    helm_release.jaeger_operator
  ]
}
*/
