# https://developer.hashicorp.com/consul/tutorials/kubernetes/kubernetes-vault-consul-secrets-management
# https://www.hashicorp.com/products/vault/kubernetes

locals { 
  namespace  = "vault" 
}

module "eks_vault_installer_test" {
  source = "../eks/modules/terraform-aws-eks-vault" 
  chart_namespace   = local.namespace
  create_namespace  = true
 
}
 
# Check Result
#    aws eks --region ap-northeast-2 update-kubeconfig --name eks-cluster-dk 
# 
# Vault Unseal
#    kubectl get pod -n vault
#    kubectl exec -it vault-0 /bin/sh -n vault
#    vault status
#    vault operator init 
#
# UI
#    kubectl port-forward svc/vault-ui --namespace vault 8200:8200
#    http://localhost:8200
#    unseal vault