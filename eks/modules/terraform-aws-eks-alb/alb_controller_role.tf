data "http" "lbc_iam_policy" {
  url = "https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/main/docs/install/iam_policy.json"

  request_headers = {
    Accept = "application/json"
  }
}

resource "aws_iam_policy" "lbc_iam_policy" {
  name        = local.resource_names.eks_alb_controller_iam_policy_name
  path        = "/"
  description = "AWS Load Balancer Controller IAM Policy"
  policy      = data.http.lbc_iam_policy.body
}

module "eks_alb_controller_iam_role" {
  source                     = "../terraform-aws-eks-irsa"
  provider_arn               = var.provider_arn
  role_name                  = local.resource_names.eks_alb_controller_iam_role_name
  namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
  role_policy_arns           = [aws_iam_policy.lbc_iam_policy.arn]
}
