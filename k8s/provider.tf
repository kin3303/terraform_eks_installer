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
      source = "hashicorp/helm"
      version = "~> 2.5"
    }

    http = {
      source = "hashicorp/http"
      #version = "2.1.0"
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
  host                   = data.terraform_remote_state.eks.outputs.eks_cluster.cluster_endpoint
  cluster_ca_certificate = base64decode(data.terraform_remote_state.eks.outputs.eks_cluster.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.cluster_auth.token
}

provider "helm" {
  kubernetes {
    host                   = data.terraform_remote_state.eks.outputs.eks_cluster.cluster_endpoint
    cluster_ca_certificate = base64decode(data.terraform_remote_state.eks.outputs.eks_cluster.cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.cluster_auth.token
  }
}

provider "http" {
}

provider "kubectl" {
  host                   = data.terraform_remote_state.eks.outputs.eks_cluster.cluster_endpoint
  cluster_ca_certificate = base64decode(data.terraform_remote_state.eks.outputs.eks_cluster.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.cluster_auth.token
  load_config_file       = false
}
