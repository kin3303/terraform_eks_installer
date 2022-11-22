
###########################################################################
# Consul on Terraform
###########################################################################

module "eks_consul_installer" {
  source = "./modules/terraform-aws-eks-consul"

  server_datacenter = "dc1"
  consul_domain     = "consul"

  # consul keygen
  gossip_enable_auto_generate = false
  gossip_encryption_key       = "/jNppi4XKThMjr2GyKh3suNyxdnal4f6rp2QHKwNyR0="

  # consul tls ca create 
  # consul tls cert create -server -days 730 -domain consul -ca consul-agent-ca.pem -key consul-agent-ca-key.pem -dc dc1 
  tls_enable_auto_encrypt = false
  tls_ca_cert             = "D:/Workspaces/Terraform/eks_installer/certificate/consul-agent-ca.pem"
  tls_ca_cert_key         = "D:/Workspaces/Terraform/eks_installer/certificate/consul-agent-ca-key.pem"
  tls_server_cert         = "D:/Workspaces/Terraform/eks_installer/certificate/dc1-server-consul-0.pem"
  tls_server_cert_key     = "D:/Workspaces/Terraform/eks_installer/certificate/dc1-server-consul-0-key.pem"

  depends_on = [
    module.eks
  ]
}

# Check EFS Static Provisioning
#    consul keygen
#       /jNppi4XKThMjr2GyKh3suNyxdnal4f6rp2QHKwNyR0=
#    consul tls ca create 
#    consul tls cert create -server -days 730 -domain consul -ca consul-agent-ca.pem -key consul-agent-ca-key.pem -dc dc1 
##    kubectl create secret generic consul-server-cert  --from-file='tls.crt=./dc1-server-consul-0.pem' --from-file='tls.key=./dc1-server-consul-0-key.pem'
#    aws eks --region ap-northeast-2 update-kubeconfig --name eks-cluster-dk
#    kubectl port-forward service/consul-consul-server --namespace default 8501:8501
#    https://localhost:8501/ui/dc1/services
