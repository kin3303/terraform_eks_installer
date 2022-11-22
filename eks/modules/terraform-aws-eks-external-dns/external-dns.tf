###########################################################################
# External DNS Controller Install
#     https://github.com/kubernetes-sigs/external-dns/tree/master/charts/external-dns
#     https://github.com/kubernetes-sigs/external-dns/blob/master/charts/external-dns/values.yaml
###########################################################################
resource "helm_release" "external_dns" {
  name       = "external-dns"
  repository = "https://kubernetes-sigs.github.io/external-dns/"
  chart      = "external-dns"
  namespace  = "default"

  set {
    name  = "image.repository"
    value = "k8s.gcr.io/external-dns/external-dns"
  }

  set {
    name  = "serviceAccount.create"
    value = "true"
  }

  set {
    name  = "serviceAccount.name"
    value = "external-dns"
  }

  /*
  apiVersion: v1
  kind: ServiceAccount
  metadata:
    ...
    annotations:
      eks.amazonaws.com/role-arn: <AmazonExternalDnsControllerRoleArn>
  */
  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.eks_external_dns_controller_iam_role.iam_role_arn
  }

  set {
    name  = "provider" # Default is aws (https://github.com/kubernetes-sigs/external-dns/tree/master/charts/external-dns)
    value = "aws"
  }

  set {
    name  = "policy" # Default is "upsert-only" which means DNS records will not get deleted even equivalent Ingress resources are deleted (https://github.com/kubernetes-sigs/external-dns/tree/master/charts/external-dns)
    value = "sync"   # "sync" will ensure that when ingress resource is deleted, equivalent DNS record in Route53 will get deleted
  }

  depends_on = [
    module.eks_external_dns_controller_iam_role
  ]
}
