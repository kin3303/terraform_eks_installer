resource "helm_release" "grafana" {
  name             = var.release_name
  chart            = var.chart_name
  repository       = var.chart_repository
  version          = var.chart_version
  namespace        = var.chart_namespace
  max_history      = var.max_history
  timeout          = var.chart_timeout
  create_namespace = false
  cleanup_on_fail  = true
  values           = concat([local.chart_values], var.additional_chart_values)
}

locals {
  chart_values     = templatefile("${path.module}/templates/values.yaml", local.grafana_values)
  grafana_values = {}
}
