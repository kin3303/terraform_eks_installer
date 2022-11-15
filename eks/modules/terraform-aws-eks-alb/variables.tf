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

variable "image_registry" {
  description =  "Amazon container image registry by region (https://docs.aws.amazon.com/eks/latest/userguide/add-ons-images.html)"
  type        = string
  default     = "602401143452.dkr.ecr.ap-northeast-2.amazonaws.com/amazon/aws-load-balancer-controller"
}

variable "service_account_namespace" {
  description =  "(Required) Namespace of the service account to which IRSA is applied"
  type        = string
}
