terraform {
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

    http = {
      source = "hashicorp/http"
      #version = "2.1.0"
      version = "~> 2.1"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

provider "kubernetes" {
  host                   = module.eks.kubeconfig.host
  cluster_ca_certificate = module.eks.kubeconfig.cluster_ca_certificate
  token                  = module.eks.kubeconfig.token
}

provider "helm" {
  kubernetes {
    host                   = module.eks.kubeconfig.host
    cluster_ca_certificate = module.eks.kubeconfig.cluster_ca_certificate
    token                  = module.eks.kubeconfig.token
  }
}

provider "http" {
}
