locals {
  owners      = var.business_divsion
  environment = var.environment
  name        = "${var.business_divsion}-${var.environment}"

  common_tags = {
    owners      = local.owners
    environment = local.environment
  }
}

################################################################################
# EKS Installation
################################################################################

module "eks" {
  source = "./modules/terraform-aws-eks" #"git@github.com:kin3303/eks_installer.git//eks/modules/terraform-aws-eks?ref=v1.2.0"
  # Common
  resource_name_prefix = local.name

  # EKS Cluster
  cluster_name       = var.cluster_name
  cluster_subnet_ids = var.cluster_subnet_ids

  # EKS Node Group
  nodegroup_private_subnet_ids             = var.nodegroup_private_subnet_ids
  nodegroup_public_subnet_ids              = var.nodegroup_public_subnet_ids
  nodegroup_ssh_key                        = var.nodegroup_ssh_key
  nodegroup_ssh_allowed_security_group_ids = var.nodegroup_ssh_allowed_security_group_ids
}


################################################################################
# EKS Addon Installation (EBS CSI Controller)
################################################################################

module "eks_ebs_csi_iam_role" {
  source                     = "./modules/terraform-aws-eks-irsa"
  provider_arn               = module.eks.eks_oidc_provider.arn
  role_name                  = "irsa-ebs-csi-role"
  namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
  role_policy_arns           = ["arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"]

  depends_on = [
    module.eks
  ]
}

module "eks_ebs_csi_addon" {
  source       = "./modules/terraform-aws-eks-addon"
  cluster_name = module.eks.eks_cluster.cluster_id 
  cluster_addons = {
    ebs-csi-addon = {
      name                     = "aws-ebs-csi-driver"
      addon_version            = "v1.5.2-eksbuild.1"
      service_account_role_arn = module.eks_ebs_csi_iam_role.iam_role_arn
      tags = {
        "eks_addon" = "ebs-csi"
        "terraform" = "true"
      }
    }
  }

  depends_on = [
    module.eks_ebs_csi_iam_role
  ]
}

# aws eks --region ap-northeast-2 update-kubeconfig --name eks-cluster-dk
# aws eks list-addons --cluster-name eks-cluster-dk
# kubectl get deploy,ds,sa -l="app.kubernetes.io/name=aws-ebs-csi-driver" -n kube-system
# kubectl describe sa ebs-csi-node-sa -n kube-system >> Anotation 확인
# kubectl describe sa ebs-csi-node-sa -n kube-system >> Annotation 확인
# kubectl get sc


###########################################################################
# ALB Controller Install
###########################################################################

data "http" "lbc_iam_policy" {
  url = "https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/main/docs/install/iam_policy.json"

  request_headers = {
    Accept = "application/json"
  }
}

resource "aws_iam_policy" "lbc_iam_policy" {
  name        = "AWSLoadBalancerControllerIAMPolicy"
  path        = "/"
  description = "AWS Load Balancer Controller IAM Policy"
  policy      = data.http.lbc_iam_policy.body
}

module "eks_alb_controller_iam_role" {
  source                     = "./modules/terraform-aws-eks-irsa"
  provider_arn               = module.eks.eks_oidc_provider.arn
  role_name                  = "irsa-alb-role"
  namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
  role_policy_arns           = [aws_iam_policy.lbc_iam_policy.arn]

  depends_on = [
    module.eks
  ]
}

module "eks_alb_controller" {
  source = "./modules/terraform-aws-eks-alb"
  vpc_id = "vpc-0528a219b39f1c6f3"
  aws_region = var.aws_region

  cluster_name = module.eks.eks_cluster.cluster_id
  service_account_name = "aws-load-balancer-controller"
  alb_controller_role_arn = module.eks_alb_controller_iam_role.iam_role_arn
  image_registry = "602401143452.dkr.ecr.ap-northeast-2.amazonaws.com/amazon/aws-load-balancer-controller"

  depends_on = [
    module.eks_alb_controller_iam_role
  ]
}

# aws eks --region ap-northeast-2 update-kubeconfig --name eks-cluster-dk
# kubectl get deployment -n kube-system aws-load-balancer-controller -o yaml
# kubectl -n kube-system get svc aws-load-balancer-webhook-service -o yaml

