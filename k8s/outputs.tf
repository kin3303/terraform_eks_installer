output "k8s" {
  value = {
    host = data.terraform_remote_state.eks.outputs.eks_cluster.cluster_endpoint
  }
}

