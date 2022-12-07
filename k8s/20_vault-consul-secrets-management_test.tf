# https://developer.hashicorp.com/consul/tutorials/kubernetes/kubernetes-vault-consul-secrets-management
# https://github.com/hashicorp/learn-consul-kubernetes/blob/main/hcp-vault-eks/consul-values.yaml

locals {
  vault_namespace   = "vault"
  consul_domain     = "consul"
  consul_namespace  = "consul"
  consul_datacenter = "dc1"
}

module "eks_vault_installer_test" {
  source           = "../eks/modules/terraform-aws-eks-vault"
  chart_namespace  = local.vault_namespace
  create_namespace = true
}


# Check Result
#    aws eks --region ap-northeast-2 update-kubeconfig --name eks-cluster-dk 
# 
# Vault Unseal
#    kubectl get pod -n vault
#    kubectl exec -it vault-0 /bin/sh -n vault
#    vault status
#    vault operator init 
#    vault operator unseal
# UI
#    kubectl port-forward svc/vault-ui --namespace vault 8200:8200
#    http://localhost:8200
#    unseal vault
#
# Vault Settings
#    export VAULT_TOKEN=<ROOT TOKEN>
#    export VAULT_ADDR=http://localhost:8200
#
# Store Consul gossip key in Vault
#    vault secrets enable -path=consul kv-v2
#    consul keygen
#       8a5pzlWytikR3HwU6GHeNXe7kZKMcxo2N8Z4H0+nbjI=
#    vault kv put consul/secret/gossip gossip="8a5pzlWytikR3HwU6GHeNXe7kZKMcxo2N8Z4H0+nbjI="
#
# Setup PKI secrets engine for TLS and service mesh CA
#    vault secrets enable pki
#    vault write -field=certificate pki/root/generate/internal common_name="dc1.consul"  ttl=87600h | tee consul_ca.crt
#    vault write pki/roles/consul-server `
#        allowed_domains="dc1.consul,consul-server,consul-server.consul,consul-server.consul.svc" `
#        allow_subdomains=true `
#        allow_bare_domains=true `
#        allow_localhost=true `
#        generate_lease=true `
#        max_ttl="720h"
#    vault secrets enable -path connect-root pki
#
# Configure Kubernetes authentication
#    vault auth enable kubernetes
#    kubectl config view --raw --minify --flatten -o jsonpath='{.clusters[].cluster.server}'
#       https://BAEE9A570032DF9C668E984CE11C2CAC.yl4.ap-northeast-2.eks.amazonaws.com
#    vault write auth/kubernetes/config `
#      kubernetes_host="https://BAEE9A570032DF9C668E984CE11C2CAC.yl4.ap-northeast-2.eks.amazonaws.com"
#
# Generate Vault policies
#    gossip-policy
#      path "consul/data/secret/gossip" {
#        capabilities = ["read"]
#      }
#
#    consul-server
#      path "kv/data/consul-server"
#      {
#        capabilities = ["read"]
#      }
#      path "pki/issue/consul-server"
#      {
#        capabilities = ["read","update"]
#      }
#      path "pki/cert/ca"
#      {
#        capabilities = ["read"]
#      }
#
#    ca-policy
#      path "pki/cert/ca" {
#        capabilities = ["read"]
#      }
#
#    connect 
#      path "/sys/mounts/connect-root" {
#        capabilities = [ "create", "read", "update", "delete", "list" ]
#      }
#      path "/sys/mounts/connect-intermediate-dc1" {
#        capabilities = [ "create", "read", "update", "delete", "list" ]
#      }
#      path "/sys/mounts/connect-intermediate-dc1/tune" {
#        capabilities = [ "update" ]
#      }
#      path "/connect-root/*" {
#        capabilities = [ "create", "read", "update", "delete", "list" ]
#      }
#      path "/connect-intermediate-dc1/*" {
#        capabilities = [ "create", "read", "update", "delete", "list" ]
#      }
#      path "auth/token/renew-self" {
#        capabilities = [ "update" ]
#      }
#      path "auth/token/lookup-self" {
#        capabilities = [ "read" ]
#      }
#
#  Configure Kubernetes authentication roles in Vault
#    Consul server role
#      vault write auth/kubernetes/role/consul-server `
#          bound_service_account_names=consul-server `
#          bound_service_account_namespaces=consul `
#          policies="gossip-policy,consul-server,connect" `
#          ttl=24h
#    Consul client role
#      vault write auth/kubernetes/role/consul-client `
#          bound_service_account_names=consul-client `
#          bound_service_account_namespaces=consul `
#          policies="gossip-policy,ca-policy" `
#          ttl=24h
#
#    Define access to Consul CA root certificate
#      vault write auth/kubernetes/role/consul-ca `
#          bound_service_account_names="*" `
#          bound_service_account_namespaces=consul `
#          policies=ca-policy `
#          ttl=1h
#
#  Deploy Consul
#     kubectl get pod -n vault -o wide

/*
resource "kubernetes_service_account_v1" "consul-server" {
  metadata {
    name = "consul-server"
    namespace = "consul"
  }
  depends_on = [
    module.eks_vault_installer_test
  ]
}


resource "kubernetes_service_account_v1" "consul-client" {
  metadata {
    name = "consul-client"
    namespace = "consul"
  }
  depends_on = [
    module.eks_vault_installer_test
  ]
}
*/

module "eks_consul_installer" {
  source = "../eks/modules/terraform-aws-eks-consul"

  create_namespace  = true
  chart_namespace   = local.consul_namespace
  consul_datacenter = local.consul_datacenter
  consul_domain     = local.consul_domain

  # global.gossipEncryption
  gossip_enable_auto_generate   = false
  gossip_encryption_secret_name = "consul/data/secret/gossip"
  gossip_encryption_secret_key  = "gossip"

  # tls
  tls_enabled             = true
  tls_enable_auto_encrypt = true
  tls_cacert_secret_name  = "pki/cert/ca"

  # server
  server_expose_gossip_and_rpc_ports = true
  tls_server_cert_secret_name        = "pki/issue/consul-server"

  # metrics
  metrics_enabled        = true
  enable_agent_metrics   = true
  enable_gateway_metrics = true

  # connectInject
  enable_connect_inject                 = true
  connect_inject_by_default             = true
  connect_inject_default_enable_merging = true

  # acl
  manage_system_acls = false

  # Vault Backend
  enable_secret_backend_vault = true
  vault_consul_server_role    = "consul-server"
  vault_consul_client_role    = "consul-client"
  vault_consul_ca_role        = "consul-ca"
  vault_addr                  = "http://10.0.1.66:8200" ###### 수정
  vault_root_pki_path         = "connect-root/"
  vault_intermediate_pki_path = "connect-intermediate-dc1/"

  # ingressGateways    
  ingress_gateway_enable = true
  ingress_gateways = [
    {
      name = "ingress-gateway"
      service = {
        type = "LoadBalancer"
      }
      consulNamespace = local.consul_namespace
    }
  ]

  # terminatingGateways
  terminating_gateway_enable = true
  terminating_gateways = [
    {
      name = "terminating-gateway"
      service = {
        type = "LoadBalancer"
      }
      consulNamespace = local.consul_namespace
    }
  ]


  depends_on = [
    module.eks_vault_installer_test
  ]
}

# UI 활성화 확인
#    kubectl port-forward service/consul-server --namespace consul 8501:8501
#    https://localhost:8501/ui/dc1/services
