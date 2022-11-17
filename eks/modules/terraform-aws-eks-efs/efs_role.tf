# https://aws.amazon.com/blogs/containers/introducing-efs-csi-dynamic-provisioning

data "http" "efs_csi_iam_policy" {
  url = "https://raw.githubusercontent.com/kubernetes-sigs/aws-efs-csi-driver/v1.2.0/docs/iam-policy-example.json"

  request_headers = {
    Accept = "application/json"
  }
}

resource "aws_iam_policy" "efs_csi_iam_policy" {
  name        = local.resource_names.efs_csi_iam_policy_name
  path        = "/"
  description = "EFS CSI IAM Policy"
  policy      = data.http.efs_csi_iam_policy.body
}

module "eks_efs_csi_iam_iam_role" {
  source                     = "../terraform-aws-eks-irsa"
  provider_arn               = var.provider_arn
  role_name                  = local.resource_names.efs_csi_iam_role_name
  namespace_service_accounts = ["kube-system:efs-csi-controller-sa"]
  role_policy_arns           = [aws_iam_policy.efs_csi_iam_policy.arn]
}