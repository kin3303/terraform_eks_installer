locals {
  max_postfix_length      = 8
  name_max_length         = 64
  name_prefix             = format("replaceme-%s-", lower(var.resource_name_prefix))
  name_max_postfix_length = floor((local.name_max_length - length(local.name_prefix)) / 2)
  name_postfix_length     = min(local.max_postfix_length, local.name_max_postfix_length)

  resource_names = {
    # IAM
    external_dns_iam_policy_name = replace(random_id.name.hex, "replaceme", "external-dns-policy")
    external_dns_iam_role_name   = replace(random_id.name.hex, "replaceme", "external-dns-role")
  }
}

resource "random_id" "name" {
  prefix      = local.name_prefix
  byte_length = local.name_postfix_length
}