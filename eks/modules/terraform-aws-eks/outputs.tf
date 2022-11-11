data "aws_eks_cluster" "cluster" {
  name = aws_eks_cluster.eks_cluster.id
}

data "aws_eks_cluster_auth" "cluster_auth" {
  name = aws_eks_cluster.eks_cluster.id
}

output "kubeconfig" {
  value = {
    host                   = aws_eks_cluster.eks_cluster.endpoint
    cluster_ca_certificate = base64decode(aws_eks_cluster.eks_cluster.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.cluster_auth.token
  }
  sensitive = true
}

output "eks_cluster" {
  value = {
    cluster_id                         = aws_eks_cluster.eks_cluster.id
    cluster_arn                        = aws_eks_cluster.eks_cluster.arn
    cluster_certificate_authority_data = aws_eks_cluster.eks_cluster.certificate_authority[0].data
    cluster_endpoint                   = aws_eks_cluster.eks_cluster.endpoint
    cluster_version                    = aws_eks_cluster.eks_cluster.version
    cluster_iam_role_name              = aws_iam_role.eks_master_role.name
    cluster_iam_role_arn               = aws_iam_role.eks_master_role.arn
    cluster_oidc_issuer_url            = aws_eks_cluster.eks_cluster.identity[0].oidc[0].issuer
    cluster_primary_security_group_id  = aws_eks_cluster.eks_cluster.vpc_config[0].cluster_security_group_id
  }
}

output "eks_public_node_group" {
  value = {
    node_group_public_id      = aws_eks_node_group.eks_ng_public.id
    node_group_public_arn     = aws_eks_node_group.eks_ng_public.arn
    node_group_public_status  = aws_eks_node_group.eks_ng_public.status
    node_group_public_version = aws_eks_node_group.eks_ng_public.version
  }
}

output "eks_private_node_group" {
  value = {
    node_group_private_id      = aws_eks_node_group.eks_ng_private.id
    node_group_private_arn     = aws_eks_node_group.eks_ng_private.arn
    node_group_private_status  = aws_eks_node_group.eks_ng_private.status
    node_group_private_version = aws_eks_node_group.eks_ng_private.version
  }
}

output "eks_oidc_provider" {
  value = {
    arn = aws_iam_openid_connect_provider.oidc_provider.arn
    url = aws_iam_openid_connect_provider.oidc_provider.url
  }
}

output "eks_roles" {
  value = {
    master_role_arn    = aws_iam_role.eks_master_role.arn
    nodegroup_role_arn = aws_iam_role.eks_nodegroup_role.arn
  }
}
