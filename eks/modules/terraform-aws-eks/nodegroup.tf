################################################################################################
# EKS Cluster Node Group - Public
#    https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_node_group
################################################################################################

# Public 
resource "aws_eks_node_group" "eks_ng_public" {
  cluster_name    = aws_eks_cluster.eks_cluster.name
  node_group_name = local.resource_names.public_node_group_name
  node_role_arn   = aws_iam_role.eks_nodegroup_role.arn
  subnet_ids      = var.eks_public_nodegroup_subnet_ids

  ami_type       = "AL2_x86_64"
  capacity_type  = "ON_DEMAND"
  disk_size      = 20
  instance_types = ["t2.medium"]

  dynamic "remote_access" {
    for_each = var.eks_node_ssh_key == null ? [] : [1]

    content {
      ec2_ssh_key = var.eks_node_ssh_key
    }
  }

  scaling_config {
    desired_size = 1
    min_size     = 1
    max_size     = 2
  }

  update_config {
    #max_unavailable = 1
    max_unavailable_percentage = 50
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.eks-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.eks-AmazonEC2ContainerRegistryReadOnly,
  ]

  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]
  }

  tags = {
    Name = "${var.resource_name_prefix}-eks-public-node-group"
  }
}

# Private
resource "aws_eks_node_group" "eks_ng_private" {
  cluster_name    = aws_eks_cluster.eks_cluster.name
  node_group_name = local.resource_names.private_node_group_name
  node_role_arn   = aws_iam_role.eks_nodegroup_role.arn
  subnet_ids      = var.eks_private_nodegroup_subnet_ids

  ami_type       = "AL2_x86_64"
  capacity_type  = "ON_DEMAND"
  disk_size      = 20
  instance_types = ["t2.medium"]

  dynamic "remote_access" {
    for_each = var.eks_node_ssh_key == null && length(var.eks_node_security_group_ids) == 0 ? [] : [1]

    content {
      ec2_ssh_key               = var.eks_node_ssh_key
      source_security_group_ids = var.eks_node_security_group_ids
    }
  }

  scaling_config {
    desired_size = 1
    min_size     = 1
    max_size     = 2
  }

  update_config {
    #max_unavailable = 1
    max_unavailable_percentage = 50
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.eks-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.eks-AmazonEC2ContainerRegistryReadOnly,
  ]

  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]
  }

  tags = {
    Name = "${var.resource_name_prefix}-eks-private-node-group"
  }
}
