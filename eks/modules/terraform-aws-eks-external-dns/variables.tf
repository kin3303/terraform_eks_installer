variable "service_account_name" {
  description =  "(Required) Name of the service account to which IRSA is applied"
  type        = string
}

variable "service_account_namespace" {
  description =  "(Required) Namespace of the service account to which IRSA is applied"
  type        = string
}

variable "external_dns_role_arn" {
  description =  "(Required) EKS external dns controller role arn"
  type        = string
}