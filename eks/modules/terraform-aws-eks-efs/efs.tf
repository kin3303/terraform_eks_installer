###########################################################################
# EFS CSI Controller Install
#     https://docs.aws.amazon.com/ko_kr/eks/latest/userguide/efs-csi.html
###########################################################################

resource "helm_release" "efs_controller" {

  name       = "aws-efs-csi-driver"
  repository = "https://kubernetes-sigs.github.io/aws-efs-csi-driver"
  chart      = "aws-efs-csi-driver"
  namespace  = "kube-system"

  set {
    name  = "image.repository"
    value = "602401143452.dkr.ecr.${var.aws_region}.amazonaws.com/eks/aws-efs-csi-driver"
  }

  set {
    name  = "serviceAccount.create"
    value = "true"
  }

  set {
    name  = "serviceAccount.name"
    value = var.service_account_name
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.eks_efs_csi_iam_iam_role.iam_role_arn
  }

  depends_on = [
    module.eks_efs_csi_iam_iam_role
  ]
}

###########################################################################
# EFS Provisionting  
###########################################################################
locals {
  security_group = {
    efs = {
      name        = "${var.resource_name_prefix}-efs-allow-nfs-from-eks-vpc"
      description = "Allow Inbound NFS Traffic from EKS VPC CIDR"
      ingress = {
        nfs = {
          from        = 2049
          to          = 2049
          protocol    = "tcp"
          description = "Allow Inbound NFS Traffic from EKS VPC CIDR to EFS File System"
          cidr_blocks = [var.allowed_inbound_cidrs]
        }
      }
      egress = {
        all = {
          from        = 0
          to          = 0
          protocol    = "-1"
          description = "Allow  outbound traffic from all"
          cidr_blocks = ["0.0.0.0/0"]
        }
      }
    }
  }
}

# EFS Security Group
resource "aws_security_group" "efs_sg" {
  for_each = local.security_group

  name        = each.value.name
  description = each.value.description
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = each.value.ingress
    content {
      cidr_blocks = ingress.value.cidr_blocks
      from_port   = ingress.value.from
      protocol    = ingress.value.protocol
      to_port     = ingress.value.to
    }
  }

  dynamic "egress" {
    for_each = each.value.egress
    content {
      cidr_blocks = egress.value.cidr_blocks
      from_port   = egress.value.from
      protocol    = egress.value.protocol
      to_port     = egress.value.to
    }
  }
}

# EFS File System
resource "aws_efs_file_system" "efs_file_system" {
  creation_token                  = "${var.resource_name_prefix}-efs"
  encrypted                       = var.encrypted != true && var.kms_key_id != null ? true : false
  kms_key_id                      = var.encrypted != true && var.kms_key_id != null ? var.kms_key_id : null
  performance_mode                = var.performance_mode
  provisioned_throughput_in_mibps = var.performance_mode == "provisioned" ? var.provisioned_throughput_in_mibps : null
  throughput_mode                 = var.throughput_mode

  dynamic "lifecycle_policy" {
    for_each = var.transition_to_ia != null ? [var.transition_to_ia] : []

    content {
      transition_to_ia = lifecycle_policy.value
    }
  }

  dynamic "lifecycle_policy" {
    for_each = length(var.transition_to_primary_storage_class) > 0 ? [1] : []
    content {
      transition_to_primary_storage_class = try(var.transition_to_primary_storage_class[0], null)
    }
  }

  tags = {
    Name = "${var.resource_name_prefix}-efs"
  }
}

resource "aws_efs_backup_policy" "policy" {
  file_system_id = aws_efs_file_system.efs_file_system.id

  backup_policy {
    status = "ENABLED"
  }
}

# EFS Mount Target 
resource "aws_efs_mount_target" "efs_mount_target" {
  for_each = toset(var.efs_subnet_ids)

  file_system_id  = aws_efs_file_system.efs_file_system.id
  subnet_id       = each.value
  security_groups = [aws_security_group.efs_sg["efs"].id]
}
