###############################################################################################
# KMS key to save Vault seal/unseal keys
###############################################################################################
resource "aws_kms_key" "vault_kms" {
  description             = "Vault Seal/Unseal key"
  deletion_window_in_days = 7

  policy = <<EOT
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "Enable IAM User Permissions",
      "Action": [
        "kms:*"
      ],
      "Principal": {
        "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      },
      "Effect": "Allow",
      "Resource": "*"
    },
    {
      "Sid": "Allow administration of the key",
      "Action": [
        "kms:Create*",
        "kms:Describe*",
        "kms:Enable*",
        "kms:List*",
        "kms:Put*",
        "kms:Update*",
        "kms:Revoke*",
        "kms:Disable*",
        "kms:Get*",
        "kms:Delete*",
        "kms:ScheduleKeyDeletion",
        "kms:CancelKeyDeletion"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root",
      "Principal": {
        "AWS": [
            "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${local.resource_names.vault_iam_role_name}"
        ]
       }
    },
    {
      "Sid": "Allow use of the key",
      "Action": [
        "kms:DescribeKey",
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey",
        "kms:GenerateDataKeyWithoutPlaintext"
      ],
      "Principal": {
        "AWS": [
            "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${local.resource_names.vault_iam_role_name}"
        ]
      },
      "Effect": "Allow",
      "Resource": "*"
    }
  ]

}
EOT
}

###############################################################################################
# Vault domain recording
###############################################################################################
data "kubernetes_service" "vault_ui" {
  metadata {
    name      = "vault-ui"
    namespace = "vault-server"
  }
  depends_on = [ 
    helm_release.vault
  ]
}

resource "aws_route53_record" "vault" {
  zone_id = data.aws_route53_zone.public.zone_id
  name    = "vault.${var.public_dns_name}"
  type    = "CNAME"
  ttl     = "300"
  records = [data.kubernetes_service.vault_ui.status.0.load_balancer.0.ingress.0.hostname]

  depends_on = [ 
    helm_release.vault,
    data.kubernetes_service.vault_ui
  ]
}