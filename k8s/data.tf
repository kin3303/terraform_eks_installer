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
  "cluster_certificate_authority_data" = "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUMvakNDQWVhZ0F3SUJBZ0lCQURBTkJna3Foa2lHOXcwQkFRc0ZBREFWTVJNd0VRWURWUVFERXdwcmRXSmwKY201bGRHVnpNQjRYRFRJeU1URXhOakF5TVRreE5sb1hEVE15TVRFeE16QXlNVGt4Tmxvd0ZURVRNQkVHQTFVRQpBeE1LYTNWaVpYSnVaWFJsY3pDQ0FTSXdEUVlKS29aSWh2Y05BUUVCQlFBRGdnRVBBRENDQVFvQ2dnRUJBTnBWCmdmSE9GSmcxeEFWNzJMRkgwbnRsQ2lNb2NzNWx6a081SktDS1NHM3g2dmNId3V3Z1c0QkZqY0g5Wnl4elRMM1EKNDlKN0xHN2VOS1VaZ1EvMG1BVFNoUmRJNmdTUVloSGZnTHA3dU1jVTJDSDhZb1FicDVreVZROWZSVG10eWViWQp3WXlwY1BHcXVNWUVWdTNPTTE4SUsvRlZZMmV6ZVNBbjZmVy9zb2hOZ3FONEI3SHA2Mk01dkhUQ3REOFFPMTZTCnU0MjBTWDhOMEdKczVpTFFYRnpsSGJmRHFWYkk3VEk4Zi9JOVhHM3k3ckRlOGlXL3UzQ05vWkdlV3B4cTB1QjEKTkFVV0p0UExyVkt5TkZCUE1RZUtJWndweU1hTFdQQTNqWnFkTjhlaFIzcXdYL3crbW5hQVROTndaZ3liaEF0VwoxUVJjM0lXbHZZWlhaaExrNkVNQ0F3RUFBYU5aTUZjd0RnWURWUjBQQVFIL0JBUURBZ0trTUE4R0ExVWRFd0VCCi93UUZNQU1CQWY4d0hRWURWUjBPQkJZRUZJdWhJZW14VXVHUDN3WXlDMmxnZU5ISTIvbEFNQlVHQTFVZEVRUU8KTUF5Q0NtdDFZbVZ5Ym1WMFpYTXdEUVlKS29aSWh2Y05BUUVMQlFBRGdnRUJBRUZxSkc0L0xnR2N5dmhwRHRRZgowK3orS0paZ1lYdTdoNmVkZXVCWUU5cmlQZGFGbkVZcjdPakJ6VEpvSlhPM25va3kwQjBzT3AvcHRaWGp6eWdqClNqM0o4RjJQQXZjWHVaVlEwK3JUcVBKb3o3ajJEdTJ5UzF6QmVvcUlKek9Tb1BTNTdlWjZyYTdQbzRYT3QwMG4KRzYreVhvSEcrRHlTM3FXOUt4K1dlbmxtVEc2bG41ajcwdEEzNzdocWdoVklqKzR3TEo5dVZBaFdOMXY5RHlreQowNzNtajdobFZWYUkzQit0MXV1VmhBUXMzeUp6bHhkTzlwc0lhdXppTTVtZHFtc2lPVzF2UGhXcXFqVzBTZDRtCllBQ3hJNmVBWVpHWitXUEFCbWdtOXJBN0lFSkdIenpDN0R4VVdoTXdOZnlQTHFDK0dCOVBYeFViait1Nlo0MTMKWTNnPQotLS0tLUVORCBDRVJUSUZJQ0FURS0tLS0tCg=="
  "cluster_endpoint" = "https://250A48A8ED4623C7903DA4AE910998D2.gr7.ap-northeast-2.eks.amazonaws.com"
  "cluster_iam_role_arn" = "arn:aws:iam::960249453675:role/eks-master-role-idt-dev-f7ff47aefad1d23d"
  "cluster_iam_role_name" = "eks-master-role-idt-dev-f7ff47aefad1d23d"
  "cluster_id" = "eks-cluster-dk"
  "cluster_oidc_issuer_url" = "https://oidc.eks.ap-northeast-2.amazonaws.com/id/250A48A8ED4623C7903DA4AE910998D2"
  "cluster_primary_security_group_id" = "sg-0729a545635ab0030"
  "cluster_version" = "1.22"
}
eks_efs = {
  "efs_file_system_dns_name" = "fs-02b8a61822cdc4f1f.efs.ap-northeast-2.amazonaws.com"
  "efs_file_system_id" = "fs-02b8a61822cdc4f1f"
}
eks_efs_mount_target = {
  "efs_mount_target_availability_zone_name" = [
    "ap-northeast-2b",
    "ap-northeast-2a",
  ]
  "efs_mount_target_dns_name" = [
    "ap-northeast-2b.fs-02b8a61822cdc4f1f.efs.ap-northeast-2.amazonaws.com",
    "ap-northeast-2a.fs-02b8a61822cdc4f1f.efs.ap-northeast-2.amazonaws.com",
  ]
  "efs_mount_target_id" = [
    "fsmt-091fe0d75a9cba843",
    "fsmt-084bfa396b79837e2",
  ]
}
eks_kubeconfig = <sensitive>
eks_oidc_provider = {
  "arn" = "arn:aws:iam::960249453675:oidc-provider/oidc.eks.ap-northeast-2.amazonaws.com/id/250A48A8ED4623C7903DA4AE910998D2"
  "url" = "oidc.eks.ap-northeast-2.amazonaws.com/id/250A48A8ED4623C7903DA4AE910998D2"
}
eks_private_node_group = {
  "node_group_private_arn" = "arn:aws:eks:ap-northeast-2:960249453675:nodegroup/eks-cluster-dk/eks-ng-private-idt-dev-f7ff47aefad1d23d/bcc23f20-3808-b8e2-7ce4-4cc6dae235cb"
  "node_group_private_id" = "eks-cluster-dk:eks-ng-private-idt-dev-f7ff47aefad1d23d"
  "node_group_private_status" = "ACTIVE"
  "node_group_private_version" = "1.22"
}
eks_public_node_group = {
  "node_group_public_arn" = "arn:aws:eks:ap-northeast-2:960249453675:nodegroup/eks-cluster-dk/eks-ng-public-idt-dev-f7ff47aefad1d23d/34c23f20-381c-d91f-9936-98c43477a10a"
  "node_group_public_id" = "eks-cluster-dk:eks-ng-public-idt-dev-f7ff47aefad1d23d"
  "node_group_public_status" = "ACTIVE"
  "node_group_public_version" = "1.22"
}
eks_roles = {
  "master_role_arn" = "arn:aws:iam::960249453675:role/eks-master-role-idt-dev-f7ff47aefad1d23d"
  "nodegroup_role_arn" = "arn:aws:iam::960249453675:role/eks-nodegroup-role-idt-dev-f7ff47aefad1d23d"
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

 