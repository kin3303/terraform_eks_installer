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

/*
eks_cluster = {
  "cluster_arn" = "arn:aws:eks:ap-northeast-2:960249453675:cluster/eks-cluster-dk"
  "cluster_certificate_authority_data" = "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUMvakNDQWVhZ0F3SUJBZ0lCQURBTkJna3Foa2lHOXcwQkFRc0ZBREFWTVJNd0VRWURWUVFERXdwcmRXSmwKY201bGRHVnpNQjRYRFRJeU1URXhNREF5TURNMU5Wb1hEVE15TVRFd056QXlNRE0xTlZvd0ZURVRNQkVHQTFVRQpBeE1LYTNWaVpYSnVaWFJsY3pDQ0FTSXdEUVlKS29aSWh2Y05BUUVCQlFBRGdnRVBBRENDQVFvQ2dnRUJBTlFCClFJenJyWnBPZUloZWxCVnVqUmhvWlkvajRwNDVyY05BdjlHSGRrSWlxUElqblJrYWlHdW9EcWwrTjhNWlVleXQKZ3VjcElCL3JkMzRtb1JNUzlwNVY5MUpJL3ZTVlRDOEh3YURSUE80WVlYMkIraGdPdzdIRithRVBneURaM2ExeQpiYU1PMjErb29qSlYwbzY2NnB2R2swRUYzZExUSXMweTdYS3dEaGRpYnpJeWwvZnBTbGZnblp2Q0ZoME1Bci94ClFsQTZKWFJQaXJFcVVPbHNObzZqMWxpSVBvWDI4NFJNeW0wTzRBT3lPSFdiQVljSTc4TzhadjhmcGd4MUxONncKeHo1and2Z2RONEFnREVtbmVlSUFseklRWkw4eE9RY05SeXBPTUhUWW14b3hhZDh5T2UrMmlvRThDVlBjMENmSwpSczB2d2ZXZkxqN0cxQldZTVBFQ0F3RUFBYU5aTUZjd0RnWURWUjBQQVFIL0JBUURBZ0trTUE4R0ExVWRFd0VCCi93UUZNQU1CQWY4d0hRWURWUjBPQkJZRUZLaTd2WDNiNnZQSEtHVFYvQ1JRSWRUdnNWeVFNQlVHQTFVZEVRUU8KTUF5Q0NtdDFZbVZ5Ym1WMFpYTXdEUVlKS29aSWh2Y05BUUVMQlFBRGdnRUJBTHNxSFpUTHNSTGsrWEJwbUU5eAp6SHdPMWZ1Nld5K1ZhSEVzSTdCMWYrU0JTdzdZV0V1d2MxQ0VoSTlPbldPa1BBa3A5QTVHa2RjQXBlSSt4UWFxCm94bzJySTRGSU9QVVA5cTNoalZQRVpOL3RDeWRQVE9KclJXK21VWVVPU21xV0tWdEdLZXRrbW1NanlrQWo1TGoKemxRQjVTYlBVSzVTZnFrWG5VSVFMb0Vuc1h1WDdiR0ZaeWl4cXRFeTE0MGJaT29WdnhFMzl0M0JvOUY2Wk1qVgp3RVhhVnFGeUlySTd4TUFrcTlqTVpzTzR4eXJGRlUrN294Mnl6aVJjb0JVRU9uS3NadXloQXppci94bEc5OFdBCkRKM0wwdXFlcXh6MDk4VHExaEIyaEs5S3dGMFJwMG16MUxEK3dza0JQbHIycXlaK2JaTG1PREg1ODJlSjJxOFAKVDBFPQotLS0tLUVORCBDRVJUSUZJQ0FURS0tLS0tCg=="
  "cluster_endpoint" = "https://A580320069C4603A4C760642985A31F0.gr7.ap-northeast-2.eks.amazonaws.com"
  "cluster_iam_role_arn" = "arn:aws:iam::960249453675:role/eks-master-role-idt-dev-e2f6f333b80828e0"
  "cluster_iam_role_name" = "eks-master-role-idt-dev-e2f6f333b80828e0"
  "cluster_id" = "eks-cluster-dk"
  "cluster_oidc_issuer_url" = "https://oidc.eks.ap-northeast-2.amazonaws.com/id/A580320069C4603A4C760642985A31F0"
  "cluster_primary_security_group_id" = "sg-0cb32c3a6a38e31bc"
  "cluster_version" = "1.22"
}
eks_oidc_provider = {
  "arn" = "arn:aws:iam::960249453675:oidc-provider/oidc.eks.ap-northeast-2.amazonaws.com/id/A580320069C4603A4C760642985A31F0"
  "url" = "oidc.eks.ap-northeast-2.amazonaws.com/id/A580320069C4603A4C760642985A31F0"
}
eks_private_node_group = {
  "node_group_private_arn" = "arn:aws:eks:ap-northeast-2:960249453675:nodegroup/eks-cluster-dk/eks-ng-private-idt-dev-e2f6f333b80828e0/50c22fa6-93b9-a67b-2158-23f9f0e59e0e"
  "node_group_private_id" = "eks-cluster-dk:eks-ng-private-idt-dev-e2f6f333b80828e0"
  "node_group_private_status" = "ACTIVE"
  "node_group_private_version" = "1.22"
}
eks_public_node_group = {
  "node_group_public_arn" = "arn:aws:eks:ap-northeast-2:960249453675:nodegroup/eks-cluster-dk/eks-ng-public-idt-dev-e2f6f333b80828e0/08c22fa6-93b6-4641-8394-6400dc9286a1"
  "node_group_public_id" = "eks-cluster-dk:eks-ng-public-idt-dev-e2f6f333b80828e0"
  "node_group_public_status" = "ACTIVE"
  "node_group_public_version" = "1.22"
}
eks_roles = {
  "master_role_arn" = "arn:aws:iam::960249453675:role/eks-master-role-idt-dev-e2f6f333b80828e0"
  "nodegroup_role_arn" = "arn:aws:iam::960249453675:role/eks-nodegroup-role-idt-dev-e2f6f333b80828e0"
}
*/

data "terraform_remote_state" "eks" {
    backend = "local"
    config = {
        path = "../eks/terraform.tfstate"
    }
}

data "aws_eks_cluster" "cluster" {
  name = data.terraform_remote_state.eks.outputs.eks_cluster.cluster_id
}

data "aws_eks_cluster_auth" "cluster_auth" {
  name = data.terraform_remote_state.eks.outputs.eks_cluster.cluster_id
}

data "aws_caller_identity" "current" {}

 