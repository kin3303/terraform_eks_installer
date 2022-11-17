variable "provider_arn" {
  description = "k8s provider arn"
  type        = string
}

variable "resource_name_prefix" {
  type        = string
  description = "(Required) Resource name prefix used for tagging and naming AWS resources"
}