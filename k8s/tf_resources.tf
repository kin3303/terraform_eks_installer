# https://github.com/terraform-aws-modules/terraform-aws-iam/tree/v5.5.5/modules/iam-role-for-service-accounts-eks
# https://aws.amazon.com/blogs/security/announcing-an-update-to-iam-role-trust-policy-behavior/
# https://github.com/ahmad-hamade/terraform-eks-config/tree/v4.0.0/modules/eks-iam-role-with-oidc
# https://github.com/terraform-aws-modules/terraform-aws-iam/tree/v5.5.5/modules/iam-role-for-service-accounts-eks




# IAM Role trust policy(assume_role_policy) - Role에 연결되는 정책으로 역할을 수임할 수 있는 보안 주체 Entity (여기서는 oidc_provider) 가 사용할 수 있게 한다.
#     Principal(oidc provider) 에게 현 Resouce(role) 에 대한 Action(sts:AssumeRoleWithWebIdentity) 을 Effect(Allow) 한다. 

locals {
  oidc_provider_arn         = data.terraform_remote_state.eks.outputs.eks_oidc_provider.arn
}


resource "aws_iam_role" "irsa_s3_read_only_role" {
  name = "irsa-s3-readonly-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Federated =  "${replace(local.oidc_provider_arn, "/^(.*provider/)/", "")}:sub" # https://docs.aws.amazon.com/ko_kr/IAM/latest/UserGuide/id_roles_providers.html
        }
        Condition = {
          StringEquals = { #oidc.eks.ap-northeast-2.amazonaws.com/id/A9CA35794A78F8EF8F3A154C3B892A73:sub
            "${local.oidc_provider_url_extract}" : "system:serviceaccount:default:${var.sa_s3_readonly}"
          }
        }
      },
    ]
  })

  tags = {
    tag-key = "irsa-s3-readonly-role"
  }
}

resource "aws_iam_role_policy_attachment" "irsa_iam_role_policy_attach" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
  role       = aws_iam_role.irsa_s3_read_only_role.name
}



module "eks_irsa_role" {
  source                     = "../eks/modules/terraform-aws-eks-irsa"
  provider_arn               = local.oidc_provider_arn
  role_name                  = "irsa-s3-readonly-role"
  namespace_service_accounts = ["default:${var.sa_s3_readonly}"]
  role_policy_arns           = ["arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"]
}