terraform {
  required_version = ">= 1.1.2"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.7"
    }

    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.5"
    }

    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "1.14.0"
    }
  }
}
