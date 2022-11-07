/*
eks_cluster = {
  "cluster_arn" = "arn:aws:eks:ap-northeast-2:960249453675:cluster/eks-cluster-dk"
  "cluster_certificate_authority_data" = "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUMvakNDQWVhZ0F3SUJBZ0lCQURBTkJna3Foa2lHOXcwQkFRc0ZBREFWTVJNd0VRWURWUVFERXdwcmRXSmwKY201bGRHVnpNQjRYRFRJeU1URXdNakF4TlRZd01sb1hEVE15TVRBek1EQXhOVFl3TWxvd0ZURVRNQkVHQTFVRQpBeE1LYTNWaVpYSnVaWFJsY3pDQ0FTSXdEUVlKS29aSWh2Y05BUUVCQlFBRGdnRVBBRENDQVFvQ2dnRUJBTCtCCm95c3lSL0VOc2tHTDVHNUJsL2IzN1MyZVloeFRUWG8xNURCWWZNVVFPbjRPNUdWcVpYc0RIYlhUb3VhUDNDblUKeWZEemxsaVhOdk9SUVBZVVpvd1RQSGlXZ1lBUUgwOW00L1ZGY0tqUXRFb0MyOWNyN1ZudGRaTVIrdVFwdmFZMAoxZDhmeXZSMkxENzlrb2N0aWZUNyt6ckFzcnliekpVVWlTZ2FUOXBkZkE0NEt0VU5uYW1WZ1VFcUtyb1hES29JCjJLZ0V0OFgrVlN1cDR1UjI5aEt3T1hYYjBZOFJ0OXNmalkvcU0vWjdwL24rY1NmVE9IL1I0K3ZmbkwvdXgyV28Kb2oxaEsyaDZ6MjBBT3crVUVBTWk5VjQyMW51akl2QTRDRFkvQVJYZTBFSEg0SC9ZNG83R29MSlRwZUU2QjRHVwpFdWhjRm55Mm1BaWs5WGgzUnc4Q0F3RUFBYU5aTUZjd0RnWURWUjBQQVFIL0JBUURBZ0trTUE4R0ExVWRFd0VCCi93UUZNQU1CQWY4d0hRWURWUjBPQkJZRUZLaFhkNVRTbkp6UkRBMnpmVC9XbWZXanRyQXJNQlVHQTFVZEVRUU8KTUF5Q0NtdDFZbVZ5Ym1WMFpYTXdEUVlKS29aSWh2Y05BUUVMQlFBRGdnRUJBSmNaSTZubnFlV0tHNEFPSjZrNQpxUm56S1pFSk9QU2JLcFRhOGlYN3Vydk5NZjVNeitiZkF6bEV2YmgzN3V5UmVYS1RYT20wMkd2MklXTWZLekhUCnBtRlJYN3gyV3lJTW9TRWNET3FTa3pTYldZMytuNnRmZlgxcFluRnR0bE5yeE5ZbGFVem1VMngwa1gyTitlam4KVUt6RGdhdEhlMGNNa1d6azFqbllOVEhTR2J2L0lQV3pkWC9OQ3NQb0lMdmdSbGZLZTRqL09vVmYxR1RJY2E4YQpFVThJYjZ5L01BTE84dWZ1SHdIeitEYU0xQzJrSGluQmlmNmxMaDlOc2pkanlDb3dJYmZMSjJYWkRvTUtZOUVQCkthYVBOZEliYmFhNWhWVFQwbW1XQ3B1SDAzdE9Qa2RRTHZwQ2lFVnhqN2k0bmNBd0orUVJkbWdRanNsSDB3YjQKaVNVPQotLS0tLUVORCBDRVJUSUZJQ0FURS0tLS0tCg=="
  "cluster_endpoint" = "https://A9CA35794A78F8EF8F3A154C3B892A73.gr7.ap-northeast-2.eks.amazonaws.com"
  "cluster_iam_role_arn" = "arn:aws:iam::960249453675:role/eks-master-role-idt-dev-af7066e7e76dfc90"
  "cluster_iam_role_name" = "eks-master-role-idt-dev-af7066e7e76dfc90"
  "cluster_id" = "eks-cluster-dk"
  "cluster_oidc_issuer_url" = "https://oidc.eks.ap-northeast-2.amazonaws.com/id/A9CA35794A78F8EF8F3A154C3B892A73"
  "cluster_primary_security_group_id" = "sg-0310a37998a0ed66b"
  "cluster_version" = "1.22"
}
eks_oidc_provider = {
  "arn" = "arn:aws:iam::960249453675:oidc-provider/oidc.eks.ap-northeast-2.amazonaws.com/id/A9CA35794A78F8EF8F3A154C3B892A73"
  "url" = "oidc.eks.ap-northeast-2.amazonaws.com/id/A9CA35794A78F8EF8F3A154C3B892A73"
}
eks_private_node_group = {
  "node_group_private_arn" = "arn:aws:eks:ap-northeast-2:960249453675:nodegroup/eks-cluster-dk/eks-ng-private-idt-dev-af7066e7e76dfc90/54c21b09-70a5-bf85-483e-4e28d9979aa5"
  "node_group_private_id" = "eks-cluster-dk:eks-ng-private-idt-dev-af7066e7e76dfc90"
  "node_group_private_status" = "ACTIVE"
  "node_group_private_version" = "1.22"
}
eks_public_node_group = {
  "node_group_public_arn" = "arn:aws:eks:ap-northeast-2:960249453675:nodegroup/eks-cluster-dk/eks-ng-public-idt-dev-af7066e7e76dfc90/aac21b0b-af03-7895-f387-9500db1caa44"
  "node_group_public_id" = "eks-cluster-dk:eks-ng-public-idt-dev-af7066e7e76dfc90"
  "node_group_public_status" = "ACTIVE"
  "node_group_public_version" = "1.22"
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
