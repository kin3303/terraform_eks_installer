output "eks_cluster" {
  value = module.eks.eks_cluster
}

output "eks_public_node_group" {
  value = module.eks.eks_public_node_group
}

output "eks_private_node_group" {
  value = module.eks.eks_private_node_group
}

output "eks_oidc_provider" {
  value =  module.eks.eks_oidc_provider
}

output "eks_roles" {
  value = module.eks.eks_roles
}

output "eks_kubeconfig" {
  value = module.eks.kubeconfig
  sensitive = true
}


# EFS
output "eks_efs" {
  value = module.eks_efs_csi_controller.eks_efs
}

output "eks_efs_mount_target" {
  value = module.eks_efs_csi_controller.eks_efs_mount_target
}