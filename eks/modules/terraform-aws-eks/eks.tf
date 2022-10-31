################################################################################################
# EKS Cluster
#    https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_cluster
################################################################################################

# Cluster
resource "aws_eks_cluster" "eks_cluster" {
  name     = local.resource_names.cluster_name
  role_arn = aws_iam_role.eks_master_role.arn
  version  = var.cluster_version

  # 클러스터와 연결된 VPC 의 구성 블록
  #   endpoint_private_access : API Server 와 Private Access 허용여부 
  #   endpoint_public_access : API Server 와 Public Access 허용여부 
  #   public_access_cidrs : EKS 퍼블릭 API 서버 엔드포인트에 액세스할 수 있는 CIDR 블록
  #   subnet_ids : Amazon EKS는 ENI 를 해당 서브넷에 생성하여 Worker Node 와 Kubernetes Contorl Plane 간의 통신을 허용
  #   security_group_ids :  Amazon EKS 가 생성하는 ENI 에 적용할 Security Group, 없으면 자동 생성됨
  vpc_config {
    endpoint_private_access = var.cluster_endpoint_private_access
    endpoint_public_access  = var.cluster_endpoint_public_access
    public_access_cidrs     = var.cluster_public_access_cidrs
    subnet_ids              = var.eks_subnet_ids
    #security_group_ids = 
  }

  # Kubernetes 서비스용 network 설정
  kubernetes_network_config {
    service_ipv4_cidr = var.cluster_service_ipv4_cidr
  }

  # Enabling Control Plane Logging
  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  depends_on = [
    aws_iam_role_policy_attachment.eks-AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.eks-AmazonEKSVPCResourceController,
  ]
}
