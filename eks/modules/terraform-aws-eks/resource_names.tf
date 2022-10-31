locals {
  max_postfix_length      = 8
  name_max_length         = 64
  name_prefix             = format("replaceme-%s-", lower(var.resource_name_prefix))
  name_max_postfix_length = floor((local.name_max_length - length(local.name_prefix)) / 2)
  name_postfix_length     = min(local.max_postfix_length, local.name_max_postfix_length)

  resource_names = {
    # IAM
    eks_master_role_name    = replace(random_id.name.hex, "replaceme", "eks-master-role")    # "eks-master-role-prefix-dec5ac0e50847943"
    eks_nodegroup_role_name    = replace(random_id.name.hex, "replaceme", "eks-nodegroup-role")    # "eks-nodegroup-role-prefix-dec5ac0e50847943"

    # Cluster
    cluster_name = var.cluster_name
    
    # NodeGroup
    public_node_group_name    = replace(random_id.name.hex, "replaceme", "eks-ng-public")    # "eks-ng-public-prefix-dec5ac0e50847943"
    private_node_group_name    = replace(random_id.name.hex, "replaceme", "eks-ng-private")    # "eks-ng-private-prefix-dec5ac0e50847943"

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