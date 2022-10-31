output "eks_cluster" {
  value = module.eks.eks_cluster
}

output "eks_public_node_group" {
  value = module.eks.eks_public_node_group
}

output "eks_private_node_group" {
  value = module.eks.eks_private_node_group
}