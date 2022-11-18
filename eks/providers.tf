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

    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.5"
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

provider "kubectl" {
  host                   = module.eks.kubeconfig.host
  cluster_ca_certificate = module.eks.kubeconfig.cluster_ca_certificate
  token                  = module.eks.kubeconfig.token
  load_config_file       = false
}
