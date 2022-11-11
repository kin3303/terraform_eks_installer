###########################################################################
# General Variables
###########################################################################
variable "aws_region" {
  description = "AWS Region to use"
  type        = string
  default     = "ap-northeast-2"
}


###########################################################################
# IRSA - Service Accounts
###########################################################################
variable "sa_s3_readonly" {
  type    = string
  default = "s3-readonly-sa"
}

