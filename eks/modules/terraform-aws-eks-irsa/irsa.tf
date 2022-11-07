
data "aws_partition" "current" {}
data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  partition  = data.aws_partition.current.partition
  dns_suffix = data.aws_partition.current.dns_suffix
}

data "aws_iam_policy_document" "this" {
  statement {

    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(var.provider_arn, "/^(.*provider/)/", "")}:sub"
      values   = [for sa in var.namespace_service_accounts : "system:serviceaccount:${sa}"]
    }

    # https://aws.amazon.com/premiumsupport/knowledge-center/eks-troubleshoot-oidc-and-irsa/?nc1=h_ls
    condition {
      test     = "StringEquals"
      variable = "${replace(var.provider_arn, "/^(.*provider/)/", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "this" {
  name        = var.role_name
  path        = var.role_path
  description = var.role_description

  assume_role_policy    = data.aws_iam_policy_document.this.json
  max_session_duration  = var.max_session_duration
  permissions_boundary  = var.role_permissions_boundary_arn
  force_detach_policies = var.force_detach_policies

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "this" {
  count      = length(var.role_policy_arns)
  role       = aws_iam_role.this[0].name
  policy_arn = element(var.role_policy_arns, count.index)
}