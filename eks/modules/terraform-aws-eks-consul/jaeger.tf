
module "jaeger" {
  count           = var.enable_jaeger == true ? 1 : 0
  source          = "../terraform-aws-eks-jaeger"
  chart_namespace = "default"

  depends_on = [
    helm_release.consul
  ]
}
