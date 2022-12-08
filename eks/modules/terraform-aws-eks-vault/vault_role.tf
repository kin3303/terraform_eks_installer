
#############################################################################################
# Vault Role
#############################################################################################
resource "aws_iam_policy" "vault_iam_policy" {
  name        = local.resource_names.vault_iam_policy_name
  path        = "/"
  description = "EKS Vault Policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = [
          "logs:CreateLogStream",
          "logs:DescribeLogStreams"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:vault-audit-logs"
      },
      {
        Action   = [
          "logs:PutLogEvents",
        ]
        Effect   = "Allow"
        Resource = "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:vault-audit-logs:log-stream:*"
      },
      {
        Action   = [
          "ec2:DescribeInstances",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action   = [
          "s3:*",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "kms:*",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action   = [
          "iam:GetRole"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:secretsmanager:${var.aws_region}:${data.aws_caller_identity.current.account_id}:role/${local.resource_names.vault_iam_role_name}"
      }
    ]
  })
}

module "vault_iam_role" {
  source                     = "../terraform-aws-eks-irsa"
  provider_arn               = var.provider_arn
  role_name                  = local.resource_names.vault_iam_role_name
  namespace_service_accounts = ["vault-server:boot-vault"]
  role_policy_arns           = [aws_iam_policy.vault_iam_policy.arn] #["arn:aws:iam::aws:policy/AdministratorAccess"] 
}

resource "kubernetes_service_account_v1" "boot_vault" {
  metadata {
    name = "boot-vault"
    namespace = "vault-server"
    labels = {
      "app.kubernetes.io/name" = "boot-vault"
    }
    annotations = {
      "eks.amazonaws.com/role-arn" = module.vault_iam_role.iam_role_arn
    }
  }
}

resource "kubernetes_cluster_role_v1" "boot_vault" {
  metadata {
    name = kubernetes_service_account_v1.boot_vault.metadata[0].name
  }

  rule {
    api_groups = [""]
    resources  = ["pods/exec", "pods", "pods/log", "secrets", "tmp/secrets"]
    verbs      = ["get", "list", "create", "update"]
  }

  rule {
    api_groups = ["certificates.k8s.io"]
    resources  = ["certificatesigningrequests", "certificatesigningrequests/approval"]
    verbs      = ["get", "list", "create", "update"]
  }
}

resource "kubernetes_cluster_role_binding_v1" "boot_vault" {
  metadata {
    name = kubernetes_service_account_v1.boot_vault.metadata[0].name
    labels = {
        "app.kubernetes.io/name": "${kubernetes_service_account_v1.boot_vault.metadata[0].name}"
    }
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "${kubernetes_service_account_v1.boot_vault.metadata[0].name}"
  }
  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account_v1.boot_vault.metadata[0].name
    namespace = "vault-server"
  }
}