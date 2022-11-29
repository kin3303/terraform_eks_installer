
module "promethues" {
  count           = var.enable_prometheus == true ? 1 : 0
  source          = "../terraform-aws-eks-prometheus"
  chart_namespace = "default" #var.chart_namespace

  depends_on = [
    helm_release.consul
  ]
}
