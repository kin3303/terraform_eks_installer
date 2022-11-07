
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
  source = "./modules/terraform-aws-eks" #"git@github.com:kin3303/eks_installer.git//eks/modules/terraform-aws-eks?ref=v1.2.0"
  # Common
  resource_name_prefix = local.name

  # EKS Cluster
  cluster_name   = var.cluster_name
  cluster_subnet_ids = var.cluster_subnet_ids

  # EKS Node Group
  nodegroup_private_subnet_ids = var.nodegroup_private_subnet_ids
  nodegroup_public_subnet_ids  = var.nodegroup_public_subnet_ids
  nodegroup_ssh_key                 = var.nodegroup_ssh_key
  nodegroup_ssh_allowed_security_group_ids      = var.nodegroup_ssh_allowed_security_group_ids
}
