locals {
    aws_auth_configmap_data = {
    mapRoles = yamlencode(concat(
      [for role_arn in var.aws_auth_node_iam_role_arns : {
        rolearn  = role_arn
        username = "system:node:{{EC2PrivateDNSName}}"
        groups = [
          "system:bootstrappers",
          "system:nodes",
        ]
        }
      ],
      var.aws_auth_roles
    ))
    mapUsers = yamlencode(var.aws_auth_users)
  } 
}

resource "kubernetes_config_map_v1" "aws_auth" {
  count =  var.create_aws_auth_configmap ? 1 : 0

  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = local.aws_auth_configmap_data

  lifecycle { 
    ignore_changes = [data]
  }
}

resource "kubernetes_config_map_v1_data" "aws_auth" {
  count = var.manage_aws_auth_configmap ? 1 : 0

  force = true

  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = local.aws_auth_configmap_data

  depends_on = [ 
    kubernetes_config_map_v1.aws_auth,
  ]
}
