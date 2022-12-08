########################################################################################
# General
########################################################################################
variable "cluster_name" {
  type        = string
  description = "(Required) EKS cluster name"
}

variable "aws_region" {
  type        = string
  description = "(Required) AWS Region to use"
}

variable "resource_name_prefix" {
  type        = string
  description = "(Required) String value for friendly name prefix for AWS resource names."
}

variable "provider_arn" {
  description = "(Required) k8s provider arn"
  type        = string
}

variable "acm_vault_arn" {
  description = "(Required) ACM vault arn"
  type = string
}

variable "public_dns_name" {
  description = "Vault public DNS name."
  type    = string
}

variable "node_group_private_name" {
  description = "EKS private node group name"
  type    = string
}

variable "node_group_public_name" {
  description = "EKS public node group name"
  type    = string
}
 

########################################################################################
# Chart
########################################################################################
variable "release_name" {
  description = "Helm release name for vault"
  default     = "vault"
}

variable "chart_name" {
  description = "Helm chart name to provision"
  default     = "vault"
}

variable "chart_repository" {
  description = "Helm repository for the chart"
  default     = "https://helm.releases.hashicorp.com"
}

variable "chart_version" {
  description = "Version of Chart to install. Set to empty to install the latest version"
  default     = "0.22.1"
}

variable "chart_timeout" {
  description = "Timeout to wait for the Chart to be deployed. The chart waits for all Daemonset pods to be healthy before ending. Increase this for larger clusers to avoid timeout"
  default     = 600
}

variable "max_history" {
  description = "Max History for Helm"
  default     = 20
}

variable "additional_chart_values" {
  description = "Additional values for the Vault Helm Chart in YAML"
  type        = list(string)
  default     = []
}
