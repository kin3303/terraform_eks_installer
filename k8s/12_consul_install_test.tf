# https://developer.hashicorp.com/consul/tutorials/kubernetes/kubernetes-deployment-guide
locals {
  domain     = "consul"
  namespace  = "consul"
  datacenter = "dc1"
}

module "eks_consul_installer" {
  source = "../eks/modules/terraform-aws-eks-consul"
  
  create_namespace            = true 
  chart_namespace             = local.namespace
  
  # global
  consul_datacenter           = local.datacenter
  consul_domain               = local.domain

  # global.gossipEncryption
  gossip_enable_auto_generate = true
      ## 수동
      ## $ consul keygen
      # gossip_enable_auto_generate = false
      # gossip_encryption_key       = "/jNppi4XKThMjr2GyKh3suNyxdnal4f6rp2QHKwNyR0="

  # global.tls
  tls_enable_auto_encrypt = true
      ## 수동
      ## consul tls ca create 
      ## consul tls cert create -server -days 730 -domain consul -ca consul-agent-ca.pem -key consul-agent-ca-key.pem -dc dc1 
      # tls_enable_auto_encrypt = false
      # tls_ca_cert             = "D:/Workspaces/Terraform/eks_installer/certificate/consul-agent-ca.pem"
      # tls_ca_cert_key         = "D:/Workspaces/Terraform/eks_installer/certificate/consul-agent-ca-key.pem"
      # tls_server_cert         = "D:/Workspaces/Terraform/eks_installer/certificate/dc1-server-consul-0.pem"
      # tls_server_cert_key     = "D:/Workspaces/Terraform/eks_installer/certificate/dc1-server-consul-0-key.pem"

  # metrics
  metrics_enabled      = true
  enable_agent_metrics = true
  enable_gateway_metrics = true

   # connectInject
  enable_connect_inject                 = true
  connect_inject_by_default             = true
  connect_inject_default_enable_merging = true

  # acl
  manage_system_acls = false

  # ingressGateways    
  ingress_gateway_enable = true
  ingress_gateways = [
    {
      name = "ingress-gateway"
      service = {
        type = "LoadBalancer"
        ports = [
          {
            nodePort = null
            port     = 80
          }
        ]
      }
      consulNamespace = local.namespace
    }
  ]
}


# Check Result
#    aws eks --region ap-northeast-2 update-kubeconfig --name eks-cluster-dk
#
# UI 활성화 확인
#    kubectl port-forward service/consul-server --namespace consul 8501:8501
#    https://localhost:8501/ui/dc1/services
# 
# TLS 통신 확인
#    > $env:CONSUL_HTTP_ADDR = "https://localhost:8501"
#    > kubectl get secret --namespace consul consul-consul-ca-cert -o jsonpath="{.data['tls\.crt']}" | base64 --decode > ca.pem
#       LS0tLS1CRUdJTiBDRVJUSUZJQ0FU...
#    > [Text.Encoding]::Utf8.GetString([Convert]::FromBase64String('LS0tLS1CRUdJTiBDRVJUSUZJQ0FU...'))
#        -----BEGIN CERTIFICATE-----
#        MIIDQzCCAuigAwIBAgIUZq0EZ42dVTSNGn...
#        -----END CERTIFICATE-----
#    > 위 파일을 ca.pem 으로 저장
#    > consul members -ca-file ca.pem
 