###########################################################################
# External DNS Controller Install
#     https://github.com/kubernetes-sigs/external-dns/tree/master/charts/external-dns
###########################################################################

resource "helm_release" "external_dns" {

  name       = "external-dns"
  repository = "https://kubernetes-sigs.github.io/external-dns/"
  chart      = "external-dns"
  namespace  = var.service_account_namespace

  set {
    name  = "image.repository"
    value = "k8s.gcr.io/external-dns/external-dns" 
  }

  set {
    name  = "serviceAccount.create"
    value = "true"
  }

  # Service Account 는 lbc_iam_role 에 설정한 system:serviceaccount:kube-system:aws-load-balancer-controller 이름을 가져야 함
  set {
    name  = "serviceAccount.name"
    value = var.service_account_name
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
    value = var.external_dns_role_arn
  }

  set {
    name  = "provider" # Default is aws (https://github.com/kubernetes-sigs/external-dns/tree/master/charts/external-dns)
    value = "aws"
  }    

  set {
    name  = "policy" # Default is "upsert-only" which means DNS records will not get deleted even equivalent Ingress resources are deleted (https://github.com/kubernetes-sigs/external-dns/tree/master/charts/external-dns)
    value = "sync"   # "sync" will ensure that when ingress resource is deleted, equivalent DNS record in Route53 will get deleted
  }    
}
