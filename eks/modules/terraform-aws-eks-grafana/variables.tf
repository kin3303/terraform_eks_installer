variable "release_name" {
  description = "Helm release name for grafana"
  default     = "grafana"
}

variable "chart_name" {
  description = "Helm chart name to provision"
  default     = "grafana"
}

variable "chart_repository" {
  description = "Helm repository for the chart"
  default     = "https://grafana.github.io/helm-charts"

}

variable "chart_version" {
  description = "Version of Chart to install. Set to empty to install the latest version"
  default     = "6.23.1"
}

variable "chart_namespace" {
  description = "Namespace to install the chart into"
  default     = "default"
}

variable "chart_timeout" {
  description = "Timeout to wait for the Chart to be deployed. The chart waits for all Daemonset pods to be healthy before ending. Increase this for larger clusers to avoid timeout"
  default     = 1800
}

variable "additional_chart_values" {
  description = "Additional values for the grafana Helm Chart in YAML"
  type        = list(string)
  default     = []
}

variable "max_history" {
  description = "Max History for Helm"
  default     = 20
}