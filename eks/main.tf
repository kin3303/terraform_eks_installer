
locals {
  owners      = var.business_divsion
  environment = var.environment
  name        = "${var.business_divsion}-${var.environment}"

  common_tags = {
    owners      = local.owners
    environment = local.environment
  }
}

module "eks" {
  source = "./modules/terraform-aws-eks"

  # Common
  resource_name_prefix = local.name

  # EKS Cluster
  cluster_name         = var.cluster_name
  eks_subnet_ids       = var.eks_subnet_ids

  # EKS Node Group
  eks_private_nodegroup_subnet_ids = var.eks_private_nodegroup_subnet_ids
  eks_public_nodegroup_subnet_ids = var.eks_public_nodegroup_subnet_ids
  eks_node_ssh_key = var.eks_node_ssh_key
  eks_node_security_group_ids = var.eks_node_security_group_ids
}
