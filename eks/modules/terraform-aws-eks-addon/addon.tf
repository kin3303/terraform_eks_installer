################################################################################
# EKS Addons
################################################################################

resource "aws_eks_addon" "this" {
  for_each = { for k, v in var.cluster_addons : k => v }

  cluster_name = var.cluster_name
  addon_name   = try(each.value.name, each.key)

  addon_version            = lookup(each.value, "addon_version", null)
  resolve_conflicts        = lookup(each.value, "resolve_conflicts", null)
  service_account_role_arn = lookup(each.value, "service_account_role_arn", null)

  tags = lookup(each.value, "tags", null)
}