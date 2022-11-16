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

variable "service_account_name" {
  description =  "(Required) Name of the service account to which IRSA is applied"
  type        = string
}

variable "alb_controller_role_arn" {
  description =  "(Required) EKS load balancer controller role arn"
  type        = string
}

variable "service_account_namespace" {
  description =  "(Required) Namespace of the service account to which IRSA is applied"
  type        = string
}
