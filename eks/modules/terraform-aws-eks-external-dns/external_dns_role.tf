resource "aws_iam_policy" "externaldns_iam_policy" {
  name        = local.resource_names.external_dns_iam_policy_name
  path        = "/"
  description = "External DNS IAM Policy"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "route53:ChangeResourceRecordSets"
        ],
        "Resource" : [
          "arn:aws:route53:::hostedzone/*"
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "route53:ListHostedZones",
          "route53:ListResourceRecordSets"
        ],
        "Resource" : [
          "*"
        ]
      }
    ]
  })
}

module "eks_external_dns_controller_iam_role" {
  source                     = "../terraform-aws-eks-irsa"
  provider_arn               = var.provider_arn
  role_name                  = local.resource_names.external_dns_iam_role_name
  namespace_service_accounts = ["default:external-dns"]
  role_policy_arns           = [aws_iam_policy.externaldns_iam_policy.arn] 
}