variable "cluster_name" {
  type        = string
  description = "(Required) EKS cluster name"
}

variable "aws_region" {
  type        = string
  description = "(Required) AWS Region to use"
}

variable "service_account_name" {
  description = "(Required) Name of the service account to which IRSA is applied"
  type        = string
}

variable "resource_name_prefix" {
  type        = string
  description = "(Required) String value for friendly name prefix for AWS resource names."
}

variable "provider_arn" {
  description = "k8s provider arn"
  type        = string
}
