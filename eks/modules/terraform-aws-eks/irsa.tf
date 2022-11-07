################################################################################################
# EKS IRSA
#    https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_cluster
#    https://github.com/terraform-aws-modules/terraform-aws-eks/tree/v11.0.0/examples/irsa
################################################################################################ 
data "aws_partition" "current" {}

data "tls_certificate" "example" {
  url = aws_eks_cluster.eks_cluster.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "oidc_provider" {
  client_id_list  = ["sts.${data.aws_partition.current.dns_suffix}"] # sts.amazonaws.com
  thumbprint_list = [data.tls_certificate.example.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.eks_cluster.identity[0].oidc[0].issuer

  tags = {
    Name = "${var.cluster_name}-eks-irsa"
  }
}