###########################################################################
# ALB Controller Install
#     https://artifacthub.io/packages/helm/aws/aws-load-balancer-controller
#     https://docs.aws.amazon.com/ko_kr/eks/latest/userguide/aws-load-balancer-controller.html
#     https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.4/deploy/installation/
###########################################################################

resource "helm_release" "loadbalancer_controller" {

  name              = "aws-load-balancer-controller"
  repository        = "https://aws.github.io/eks-charts"
  chart             = "aws-load-balancer-controller"
  namespace         = "kube-system"
  cleanup_on_fail   = true
  dependency_update = true

  # Region 에 따라 Repository URL 변경 : https://docs.aws.amazon.com/eks/latest/userguide/add-ons-images.html
  set {
    name  = "image.repository"
    value = "602401143452.dkr.ecr.${var.aws_region}.amazonaws.com/amazon/aws-load-balancer-controller"
  }

  set {
    name  = "serviceAccount.create"
    value = "true"
  }

  # Service Account 는 lbc_iam_role 에 설정한 system:serviceaccount:kube-system:aws-load-balancer-controller 이름을 가져야 함
  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  /*
  apiVersion: v1
  kind: ServiceAccount
  metadata:
    ...
    annotations:
      eks.amazonaws.com/role-arn: <AmazonEKSLoadBalancerControllerRoleArn>
  */
  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.eks_alb_controller_iam_role.iam_role_arn
  }

  set {
    name  = "vpcId"
    value = var.vpc_id
  }

  set {
    name  = "region"
    value = var.aws_region
  }

  set {
    name  = "clusterName"
    value = var.cluster_name
  }

  depends_on = [
    module.eks_alb_controller_iam_role
  ]
}
