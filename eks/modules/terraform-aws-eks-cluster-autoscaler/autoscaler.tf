###########################################################################
# Cluster Node Autoscaler Install 
#     https://docs.aws.amazon.com/ko_kr/eks/latest/userguide/autoscaling.html
#     https://github.com/kubernetes/autoscaler/blob/master/cluster-autoscaler/cloudprovider/aws/README.md
#     https://github.com/kubernetes/autoscaler/tree/master/charts/cluster-autoscaler#aws---using-auto-discovery-of-tagged-instance-groups
#     https://github.com/kubernetes/autoscaler/blob/master/cluster-autoscaler/FAQ.md#what-are-the-parameters-to-ca
#     https://github.com/terraform-aws-modules/terraform-aws-eks/issues/801#issuecomment-696733518
###########################################################################

resource "helm_release" "cluster_autoscaler_release" {
  name              = "cluster-autoscaler"
  repository        = "https://kubernetes.github.io/autoscaler"
  chart             = "cluster-autoscaler"
  version           = "9.10.8"
  namespace         = "kube-system"
  create_namespace  = false
  cleanup_on_fail   = true
  dependency_update = true

  set {
    name  = "cloudProvider"
    value = "aws"
  }

  set {
    name  = "autoDiscovery.clusterName"
    value = var.cluster_name
  }

  set {
    name  = "awsRegion"
    value = var.aws_region
  }

  set {
    name  = "rbac.create"
    value = "true"
  }

  set {
    name  = "autoDiscovery.enabled"
    value = "true"
  }

  set {
    name  = "rbac.serviceAccount.create"
    value = "true"
  }

  set {
    name  = "rbac.serviceAccount.name"
    value = "cluster-autoscaler"
  }

  set {
    name  = "rbac.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.eks_cluster_autoscaler_iam_role.iam_role_arn
  }

  depends_on = [
    module.eks_cluster_autoscaler_iam_role
  ]
}
