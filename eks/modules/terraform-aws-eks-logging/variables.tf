variable "aws_region" {
  type        = string
  description = "(Required) AWS Region to use"
}

variable "cluster_name" {
  type        = string
  description = "(Required) EKS cluster name"
}
