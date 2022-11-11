variable "provider_arn" {
  description = "k8s provider arn"
  type        = string
}

variable "namespace_service_accounts" {
  description = "k8s namespace and service account names" # ["default:my-app-staging", "canary:my-app-staging"]
  type        = list(string)
  default     = []
}

variable "role_name" {
  description = "IAM role name"
  type        = string
}

variable "role_path" {
  description = "Path of IAM role"
  type        = string
  default     = "/"
}

variable "role_description" {
  description = "IAM Role description"
  type        = string
  default     = null
}

variable "tags" {
  description = "A map of tags to add the the IAM role"
  type        = map(any)
  default     = {}
}

variable "role_policy_arns" {
  description = "ARNs of any policies to attach to the IAM role"
  type        = list(string)
  default     = []
}

variable "max_session_duration" {
  description = "Maximum CLI/API session duration in seconds between 3600 and 43200"
  type        = number
  default     = null
}

variable "role_permissions_boundary_arn" {
  description = "Permissions boundary ARN to use for IAM role"
  type        = string
  default     = null
}

variable "force_detach_policies" {
  description = "Whether policies should be detached from this role when destroying"
  type        = bool
  default     = true
}