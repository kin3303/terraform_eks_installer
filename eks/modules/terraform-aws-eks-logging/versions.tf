terraform {
  required_version = ">= 0.13"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.14"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.11"
    }

    http = {
      source = "hashicorp/http"
      version = "~> 2.1"
    }

    kubectl = {
      source = "gavinbunney/kubectl"
      version = "1.14.0"
    }      
  }
}
