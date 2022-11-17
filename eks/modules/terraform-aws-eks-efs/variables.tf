variable "aws_region" {
  type        = string
  description = "(Required) AWS Region to use" 
}

variable "vpc_id" {
  type        = string
  description = "(Required) VPC ID" 
}

variable "resource_name_prefix" {
  type        = string
  description = "(Required) Resource name prefix used for tagging and naming AWS resources"
}

variable "service_account_name" {
  description =  "(Required) Name of the service account to which IRSA is applied"
  type        = string
}

variable "efs_subnet_ids" {
  type        = list(string)
  description = "(Required) The subnet IDs in which the EFS will have a mount."
}

variable "allowed_inbound_cidrs" {
  description = "(Required) VPC CIDR Block to allow inbound rule to ALB"
  type        = string
}


variable "encrypted" {
  type        = bool
  description = "If true, the disk will be encrypted."
  default = false
}

variable "kms_key_id" {
  type = string
  description = "The ARN for the KMS encryption key. When specifying kms_key_id, encrypted needs to be set to true."
  default = null
}

variable "performance_mode" {
  type = string
  description = "The file system performance mode. Can be either ''generalPurpose'' or ''maxIO'' (Default: ''generalPurpose'')"
  default = "generalPurpose"
}

variable "provisioned_throughput_in_mibps" {
  type        = number
  description = "The throughput, measured in MiB/s, that you want to provision for the file system. Only applicable with `throughput_mode` set to provisioned"
  default     = 0
}

variable "throughput_mode" {
  type = string
  description = "Throughput mode for the file system. Defaults to bursting. Valid values: bursting, provisioned. When using provisioned, also set provisioned_throughput_in_mibps."
  default = "bursting"
}

variable "transition_to_ia" {
  description = "Indicates how long it takes to transition files to the IA storage class. Valid values: AFTER_7_DAYS, AFTER_14_DAYS, AFTER_30_DAYS, AFTER_60_DAYS, or AFTER_90_DAYS."
  type        = string
  default     = null
}

variable "transition_to_primary_storage_class" {
  type        = list(string)
  description = "Describes the policy used to transition a file from Infrequent Access (IA) storage to primary storage. Valid values: AFTER_1_ACCESS."
  default     = []
  validation {
    condition = (
      length(var.transition_to_primary_storage_class) == 1 ? contains(["AFTER_1_ACCESS"], var.transition_to_primary_storage_class[0]) : length(var.transition_to_primary_storage_class) == 0
    )
    error_message = "Var `transition_to_primary_storage_class` must either be empty list or \"AFTER_1_ACCESS\"."
  }
}

variable "provider_arn" {
  description = "k8s provider arn"
  type        = string
}



