resource "aws_iam_policy" "cluster_autoscaler_iam_policy" {
  name        = local.resource_names.cluster_autoscaler_iam_policy_name
  path        = "/"
  description = "EKS Cluster Autoscaler Policy"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : [
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:DescribeAutoScalingInstances",
          "autoscaling:DescribeInstances",
          "autoscaling:DescribeLaunchConfigurations",
          "autoscaling:DescribeTags",
          "autoscaling:SetDesiredCapacity",
          "autoscaling:TerminateInstanceInAutoScalingGroup",
          "ec2:DescribeLaunchTemplateVersions",
          "ec2:DescribeInstanceTypes"
        ],
        "Resource" : "*",
        "Effect" : "Allow"
      }
    ]
  })
}

module "eks_cluster_autoscaler_iam_role" {
  source                     = "../terraform-aws-eks-irsa"
  provider_arn               = var.provider_arn
  role_name                  = local.resource_names.cluster_autosacler_iam_role_name
  namespace_service_accounts = ["kube-system:cluster-autoscaler"]
  role_policy_arns           = [aws_iam_policy.cluster_autoscaler_iam_policy.arn]
}
