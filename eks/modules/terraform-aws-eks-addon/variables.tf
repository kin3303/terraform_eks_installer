variable "cluster_name" {
  type        = string
  description = "(Required) EKS cluster name"

}

variable "cluster_addons" {
  description = "(Required) Map of cluster addon configurations to enable for the cluster. Addon name can be the map keys or set with `name`"
  type        = any
  default     = {}
}
