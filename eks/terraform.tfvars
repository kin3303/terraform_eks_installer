/*
bastion = {
  "bastion_host_eip" = "54.180.42.161"
  "bastion_host_id" = "i-0b2d08d0645c144f5"
  "key_pair" = "eks-terraform-key"
  "sequrity_group_id" = "sg-07bb632c4584ab8ba"
}
eks = {
  "cluster_name" = "eks-cluster-dk"
}
vpc = {
  "azs" = tolist([
    "ap-northeast-2a",
    "ap-northeast-2b",
    "ap-northeast-2c",
    "ap-northeast-2d",
  ])
  "database_subnets" = [
    "subnet-00f7906460fafbd48",
    "subnet-0d6375182eb23a820",
  ]
  "nat_public_ips" = tolist([
    "43.200.41.1",
  ])
  "private_subnets" = [
    "subnet-0ad3d30843b74f01c",
    "subnet-0603559f57f8358ef",
  ]
  "public_subnets" = [
    "subnet-094c4b28ca7d219f0",
    "subnet-075001c74a15ce1e9",
  ]
  "vpc_cidr_block" = "10.0.0.0/16"
  "vpc_id" = "vpc-0528a219b39f1c6f3"
}
*/

################################################################################################
# Common
################################################################################################
aws_region       = "ap-northeast-2"
business_divsion = "idt"
environment      = "dev"
vpc_cidr_block   = "10.0.0.0/16"
vpc_id           = "vpc-0528a219b39f1c6f3"

################################################################################################
# EKS Cluster
################################################################################################
cluster_name = "eks-cluster-dk"
cluster_subnet_ids = [
  "subnet-094c4b28ca7d219f0",
  "subnet-075001c74a15ce1e9",
]

################################################################################################
# EKS Node Group
################################################################################################
nodegroup_public_subnet_ids = [
  "subnet-094c4b28ca7d219f0",
  "subnet-075001c74a15ce1e9",
]

nodegroup_private_subnet_ids = [
  "subnet-0ad3d30843b74f01c",
  "subnet-0603559f57f8358ef",
]

nodegroup_ssh_key                        = "eks-terraform-key"
nodegroup_ssh_allowed_security_group_ids = ["sg-07bb632c4584ab8ba"]
