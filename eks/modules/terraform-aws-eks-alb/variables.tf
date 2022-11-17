variable "aws_region" {
  type        = string
  description = "(Required) AWS Region to use" 
}

variable "vpc_id" {
  type        = string
  description = "(Required) ID of vpc in use by eks" 
}

variable "cluster_name" {
  type        = string
  description = "(Required) EKS cluster name"
}

variable "provider_arn" {
  description = "k8s provider arn"
  type        = string
}

variable "resource_name_prefix" {
  type        = string
  description = "(Required) Resource name prefix used for tagging and naming AWS resources"
}