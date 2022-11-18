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

###########################################################################
# ALB Controller Install
###########################################################################
module "eks_alb_controller" {
  source               = "./modules/terraform-aws-eks-alb"
  resource_name_prefix = local.name
  cluster_name         = module.eks.eks_cluster.cluster_id
  provider_arn         = module.eks.eks_oidc_provider.arn
  aws_region           = var.aws_region
  vpc_id               = "vpc-0528a219b39f1c6f3"

  depends_on = [
    module.eks
  ]
}

###########################################################################
# External DNS Controller Install
###########################################################################
module "eks_external_dns_controller" {
  source               = "./modules/terraform-aws-eks-external-dns"
  resource_name_prefix = local.name
  provider_arn         = module.eks.eks_oidc_provider.arn

  depends_on = [
    module.eks
  ]
}

###########################################################################
# EFS CSI Controller Install
###########################################################################
module "eks_efs_csi_controller" {
  source                = "./modules/terraform-aws-eks-efs"
  resource_name_prefix  = local.name
  aws_region            = var.aws_region
  vpc_id                = var.vpc_id
  provider_arn          = module.eks.eks_oidc_provider.arn
  efs_subnet_ids        = var.nodegroup_private_subnet_ids
  allowed_inbound_cidrs = var.vpc_cidr_block

  depends_on = [
    module.eks
  ]
}

###########################################################################
# Cluster Autoscaler Install
###########################################################################
module "eks_cluster_autoscaler" {
  source               = "./modules/terraform-aws-eks-cluster-autoscaler"
  resource_name_prefix = local.name
  aws_region           = var.aws_region
  cluster_name         = module.eks.eks_cluster.cluster_id
  provider_arn         = module.eks.eks_oidc_provider.arn

  depends_on = [
    module.eks
  ]
}

###########################################################################
# Pod Autoscaler Install
###########################################################################
module "eks_pod_autoscaler" {
  source               = "./modules/terraform-aws-eks-pod-scaler"
  resource_name_prefix = local.name

  depends_on = [
    module.eks
  ]
}

###########################################################################
# Logging
#   모듈화 하면 동작하지 않는 이슈가 있고 개선되지 않고 있는듯..
#   https://github.com/gavinbunney/terraform-provider-kubectl/issues/61
#   임시 조치로 monitoring.tf 로 설치
###########################################################################
/*
module "eks_logging" {
  source       = "./modules/terraform-aws-eks-logging"
  aws_region   = var.aws_region
  cluster_name = module.eks.eks_cluster.cluster_id

  depends_on = [
    module.eks
  ]
}
*/