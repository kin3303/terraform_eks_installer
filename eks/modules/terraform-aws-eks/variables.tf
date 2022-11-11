
################################################################################################
# Common
################################################################################################
variable "resource_name_prefix" {
  type        = string
  description = "(Required) String value for friendly name prefix for AWS resource names."
}


################################################################################################
# EKS Cluster
################################################################################################
variable "cluster_name" {
  type        = string
  description = "(Required) EKS cluster name"

}

variable "cluster_service_ipv4_cidr" {
  type        = string
  description = <<EOT
    (Optional) The CIDR block to assign Kubernetes pod and service IP addresses from. 
    If you don't specify a block, Kubernetes assigns addresses from either the 10.100.0.0/16 or 172.20.0.0/16 CIDR blocks. 
    We recommend that you specify a block that does not overlap with resources in other networks that are peered or connected to your VPC.
  EOT

  default = "172.20.0.0/16"
}

variable "cluster_version" {
  type        = string
  description = "(Optional) EKS cluster version"
  default     = "1.22"
}

variable "cluster_endpoint_private_access" {
  type        = bool
  description = "(Optional) Amazon EKS private API server endpoint is enabled."
  default     = true
}

variable "cluster_endpoint_public_access" {
  type        = bool
  description = "(Optional) Amazon EKS public API server endpoint is enabled."
  default     = true
}

variable "cluster_public_access_cidrs" {
  type        = list(string)
  description = "(Optional) List of CIDR blocks which can access the Amazon EKS public API server endpoint."
  default     = ["0.0.0.0/0"]
}

variable "cluster_subnet_ids" {
  type        = list(string)
  description = <<EOT
    (Required) List of subnet IDs. Must be in at least two different availability zones. 
    Amazon EKS creates cross-account elastic network interfaces in these subnets to allow communication between your worker nodes and the Kubernetes control plane.
  EOT
}


################################################################################################
# EKS Node Group
################################################################################################
variable "nodegroup_public_subnet_ids" {
  type        = list(string)
  description = <<EOT
    (Required) Identifiers of EC2 Subnets to associate with the EKS Public Node Group. 
    These subnets must have the following resource tag: `kubernetes.io/cluster/CLUSTER_NAME` (where `CLUSTER_NAME` is replaced with the name of the EKS Cluster).
  EOT
}

variable "nodegroup_private_subnet_ids" {
  type        = list(string)
  description = <<EOT
    (Required) Identifiers of EC2 Subnets to associate with the EKS Public Node Group. 
    These subnets must have the following resource tag: `kubernetes.io/cluster/CLUSTER_NAME` (where `CLUSTER_NAME` is replaced with the name of the EKS Cluster).
  EOT
}

variable "nodegroup_ssh_key" {
  type        = string
  description = "(Optional) EC2 Key Pair name that provides access for SSH communication with the worker nodes in the EKS Node Group"
  default     = null
}

variable "nodegroup_ssh_allowed_security_group_ids" {
  type        = list(string)
  description = <<EOT
   (Optional) Set of EC2 Security Group IDs to allow SSH access (port 22) from on the worker nodes. 
   If you specify `nodegroup_ssh_key`, but do not specify this configuration when you create an EKS Node Group, port 22 on the worker nodes is opened to the Internet (0.0.0.0/0)
  EOT
  default     = []
}