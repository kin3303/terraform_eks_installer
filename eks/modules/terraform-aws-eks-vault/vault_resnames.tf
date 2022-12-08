data "aws_caller_identity" "current" {}

data "aws_route53_zone" "public" {
  name         = var.public_dns_name
  private_zone = false
}

locals {
  max_postfix_length      = 8
  name_max_length         = 64
  name_prefix             = format("replaceme-%s-", lower(var.resource_name_prefix))
  name_max_postfix_length = floor((local.name_max_length - length(local.name_prefix)) / 2)
  name_postfix_length     = min(local.max_postfix_length, local.name_max_postfix_length)

  resource_names = {
    # IAM
    vault_iam_policy_name = replace(random_id.name.hex, "replaceme", "vault-policy")
    vault_iam_role_name   = replace(random_id.name.hex, "replaceme", "vault-role")
    vault_unseal_iam_policy_name = replace(random_id.name.hex, "replaceme", "vault-unseal-policy")
    vault_unseal_iam_role_name   = replace(random_id.name.hex, "replaceme", "vault-unseal-role")

    # KMS
    vault_secret_kms_name =  replace(random_id.name.hex, "replaceme", "vault_secret")

    # S3
     vault_bucket_name =  format("vault-bucket-%s-%s", lower(var.resource_name_prefix), random_string.lower.result) # "vaultbackup-prefix-abcdefgh"
     
  }
}

resource "random_id" "name" {
  prefix      = local.name_prefix
  byte_length = local.name_postfix_length
}

resource "random_string" "lower" {
  length  = local.name_postfix_length
  upper   = false
  lower   = true
  numeric = false
  special = false
}
