
module "grafana" {
  count           = var.enable_grafana == true ? 1 : 0
  source          = "../terraform-aws-eks-grafana"
  chart_namespace = "default" #var.chart_namespace

  depends_on = [
    helm_release.consul
  ]
}
