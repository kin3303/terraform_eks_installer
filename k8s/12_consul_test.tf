
###########################################################################
# Consul on Terraform
###########################################################################
locals {
    domain = "consul"
    namespace =  kubernetes_namespace.consul.metadata[0].name
    datacenter = "dc1"
}

resource "kubernetes_namespace" "consul" {
  metadata {
    name = "consul"
  }
}


module "eks_consul_installer" {
  source = "../eks/modules/terraform-aws-eks-consul"

  server_datacenter = local.datacenter
  consul_domain     = local.domain
  chart_namespace   = local.namespace

  gossip_enable_auto_generate = true
  ## consul keygen
  #gossip_encryption_key       = "/jNppi4XKThMjr2GyKh3suNyxdnal4f6rp2QHKwNyR0="

  tls_enable_auto_encrypt = true
  ## consul tls ca create 
  ## consul tls cert create -server -days 730 -domain consul -ca consul-agent-ca.pem -key consul-agent-ca-key.pem -dc dc1 
  #tls_ca_cert             = "D:/Workspaces/Terraform/eks_installer/certificate/consul-agent-ca.pem"
  #tls_ca_cert_key         = "D:/Workspaces/Terraform/eks_installer/certificate/consul-agent-ca-key.pem"
  #tls_server_cert         = "D:/Workspaces/Terraform/eks_installer/certificate/dc1-server-consul-0.pem"
  #tls_server_cert_key     = "D:/Workspaces/Terraform/eks_installer/certificate/dc1-server-consul-0-key.pem"

  connect_enable = true
  enable_connect_inject = true

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

  depends_on = [
    kubernetes_namespace.consul
  ]
}

# Check EFS Static Provisioning
#    aws eks --region ap-northeast-2 update-kubeconfig --name eks-cluster-dk
#    kubectl port-forward service/consul-consul-server --namespace consul 8501:8501
#    https://localhost:8501/ui/dc1/services
