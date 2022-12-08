# https://developer.hashicorp.com/vault/tutorials/kubernetes/kubernetes-raft-deployment-guide

module "eks_vault_installer_test" {
  source = "../eks/modules/terraform-aws-eks-vault" 

  resource_name_prefix    = "idt-aa"
  aws_region              = var.aws_region
  cluster_name            = data.terraform_remote_state.eks.outputs.eks_cluster.cluster_id
  provider_arn            = data.terraform_remote_state.eks.outputs.eks_oidc_provider.arn
  public_dns_name         = "idtplateer.com"
  acm_vault_arn           = "arn:aws:acm:ap-northeast-2:960249453675:certificate/3915d0da-6dd2-4384-8fb0-558b25bf1ff4"
  node_group_public_name  = data.terraform_remote_state.eks.outputs.eks_public_node_group.node_group_public_name
  node_group_private_name = data.terraform_remote_state.eks.outputs.eks_private_node_group.node_group_private_name
}

# Check Result
#    aws eks --region ap-northeast-2 update-kubeconfig --name eks-cluster-dk 
# 
# Vault Unseal
#    kubectl get pod -n vault-server
#    kubectl exec -it vault-0 /bin/sh -n vault-server
#    vault status
#    vault operator init 
#    vault operator unseal 
#    vault login
#    vault operator raft list-peers
#    https://vault.idtplateer.com