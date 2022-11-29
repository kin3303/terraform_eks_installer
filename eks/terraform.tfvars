/*

bastion = {
  "bastion_host_eip" = "15.164.205.28"
  "bastion_host_id" = "i-0559e8e105291aca3"
  "key_pair" = "eks-terraform-key"
  "sequrity_group_id" = "sg-07d00e7cd0ebc55db"
}
eks = {
  "cluster_name" = "eks-cluster-dk"
}
vpc = {
  "azs" = tolist([
    "ap-northeast-2a",
    "ap-northeast-2c",
  ])
  "database_subnets" = [
    "subnet-00e49ef85a573f8e2",
    "subnet-0e4069fa4d864e210",
  ]
  "nat_public_ips" = tolist([
    "3.39.15.93",
  ])
  "private_subnets" = [
    "subnet-03f28acce9d8c72d9",
    "subnet-034228098ab47d028",
  ]
  "public_subnets" = [
    "subnet-0f240aaf3e25256fb",
    "subnet-0d2aaf0566fce9a19",
  ]
  "vpc_cidr_block" = "10.0.0.0/16"
  "vpc_id" = "vpc-0549b392748a90e6f"
}
*/

################################################################################################
# Common
################################################################################################
aws_region       = "ap-northeast-2"
business_divsion = "idt"
environment      = "dev"
vpc_cidr_block   = "10.0.0.0/16"
vpc_id           = "vpc-0549b392748a90e6f"

################################################################################################
# EKS Cluster
################################################################################################
cluster_name = "eks-cluster-dk"
cluster_subnet_ids = [
  "subnet-0f240aaf3e25256fb",
  "subnet-0d2aaf0566fce9a19",
]

################################################################################################
# EKS Node Group
################################################################################################
nodegroup_public_subnet_ids = [
  "subnet-0f240aaf3e25256fb",
  "subnet-0d2aaf0566fce9a19",
]

nodegroup_private_subnet_ids = [
  "subnet-03f28acce9d8c72d9",
  "subnet-034228098ab47d028",
]

nodegroup_ssh_key                        = "eks-terraform-key"
nodegroup_ssh_allowed_security_group_ids = ["sg-07d00e7cd0ebc55db"]
