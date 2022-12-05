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

variable "chart_namespace" {
  description = "Namespace to install the chart into"
  default     = "default"
}

variable "create_namespace" {
  description = " Create the namespace if it does not yet exist"
  default     = false
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

variable "secret_name" {
  description = "Name of the secret for vault"
  default     = "vault"
}

variable "secret_annotation" {
  description = "Annotations for the Vault Secret"
  default     = {}
}

variable "tls_ca_cert" {
  description = "Self generated CA path for Vault Server TLS. Values should be PEM encoded"
  default     = ""
}

variable "tls_ca_cert_key" {
  description = "Self generated CA path for Vault Server TLS. Values should be PEM encoded"
  default     = ""
}

variable "tls_server_cert" {
  description = "Server certificate path for Vault Server TLS. Values should be PEM encoded"
  default     = ""
}

variable "tls_server_cert_key" {
  description = "Server certificate path for Vault Server TLS. Values should be PEM encoded"
  default     = ""
}