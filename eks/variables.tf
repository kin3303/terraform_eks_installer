################################################################################################
# Common
################################################################################################
variable "aws_region" {
  type        = string
  description = "(Required) AWS Region to use"

  default = "ap-northeast-2"
}

variable "environment" {
  type        = string
  description = "(Required) Environment Variable used as a prefix"

}

variable "business_divsion" {
  type        = string
  description = "(Required) Business Division"

}

################################################################################################
# Cluster
################################################################################################

variable "cluster_name" {
  type        = string
  description = "(Required) EKS cluster name"
}

variable "eks_subnet_ids" {
  type        = list(string)
  description = <<EOT
    (Required) List of subnet IDs. Must be in at least two different availability zones. 
    Amazon EKS creates cross-account elastic network interfaces in these subnets to allow communication between your worker nodes and the Kubernetes control plane.
  EOT
}


################################################################################################
# EKS Node Group
################################################################################################

variable "eks_public_nodegroup_subnet_ids" {
  type        = list(string)
  description = <<EOT
    (Required) Identifiers of EC2 Subnets to associate with the EKS Public Node Group. 
    These subnets must have the following resource tag: `kubernetes.io/cluster/CLUSTER_NAME` (where `CLUSTER_NAME` is replaced with the name of the EKS Cluster).
  EOT
}

variable "eks_private_nodegroup_subnet_ids" {
  type        = list(string)
  description = <<EOT
    (Required) Identifiers of EC2 Subnets to associate with the EKS Public Node Group. 
    These subnets must have the following resource tag: `kubernetes.io/cluster/CLUSTER_NAME` (where `CLUSTER_NAME` is replaced with the name of the EKS Cluster).
  EOT
}

variable "eks_node_ssh_key" {
  description = "(Optional) EC2 Key Pair name that provides access for SSH communication with the worker nodes in the EKS Node Group"
  type        = string
}

variable "eks_node_security_group_ids" {
  description = "(Optional) Set of EC2 Security Group IDs to allow SSH access (port 22) from on the worker nodes."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}


 
