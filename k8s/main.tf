###########################################################################
# EKS Install Test
###########################################################################
resource "kubernetes_namespace" "lbtest" {
  metadata {
    name = "lbtest"
  }
}

resource "kubernetes_service_v1" "nlb_sample_service" {
  metadata {
    name      = "nlb-sample-service"
    namespace = "lbtest"

    annotations = {
      "service.beta.kubernetes.io/aws-load-balancer-type" = "nlb"
      # External DNS - Create Record Set to AWS Route 53
      "external-dns.alpha.kubernetes.io/hostname" = "sample.idtplateer.com"
    }
  }

  spec {
    port {
      protocol    = "TCP"
      port        = 80
      target_port = "80"
    }

    selector = {
      app = "nginx"
    }

    type = "LoadBalancer"
  }

  depends_on = [
    module.eks_s3_readonly_role
  ]
}

resource "kubernetes_deployment_v1" "example" {
  metadata {
    name      = "nlb-sample-app"
    namespace = "lbtest"
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "nginx"
      }
    }

    template {
      metadata {
        labels = {
          app = "nginx"
        }
      }

      spec {
        container {
          image = "nginx:1.21.6"
          name  = "nginx"

          resources {
            limits = {
              cpu    = "0.5"
              memory = "512Mi"
            }
            requests = {
              cpu    = "250m"
              memory = "50Mi"
            }
          }

          liveness_probe {
            http_get {
              path = "/"
              port = 80

              http_header {
                name  = "X-Custom-Header"
                value = "Awesome"
              }
            }

            initial_delay_seconds = 3
            period_seconds        = 3
          }
        }
      }
    }
  }

  depends_on = [
    module.eks_s3_readonly_role
  ]
}

# terraform init
# terraform apply --auto-approve
# aws eks --region ap-northeast-2 update-kubeconfig --name eks-cluster-dk
# kubectl get all -n lbtest
# terraform destroy --auto-approve
# kubectl get all -n lbtest

###########################################################################
# IRSA Module Test 
###########################################################################
locals {
  oidc_provider_arn = data.terraform_remote_state.eks.outputs.eks_oidc_provider.arn
  cluster_id        = data.terraform_remote_state.eks.outputs.eks_cluster.cluster_id
}

module "eks_s3_readonly_role" {
  source                     = "../eks/modules/terraform-aws-eks-irsa"
  provider_arn               = local.oidc_provider_arn
  role_name                  = "irsa-s3-readonly-role"
  namespace_service_accounts = ["default:s3-readonly-sa"]
  role_policy_arns           = ["arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"]
}

resource "kubernetes_service_account_v1" "s3_readonly_sa" {
  metadata {
    name = var.sa_s3_readonly

    annotations = {
      "eks.amazonaws.com/role-arn" = module.eks_s3_readonly_role.iam_role_arn # aws_iam_role.irsa_s3_read_only_role.arn 
    }
  }
}

resource "kubernetes_job_v1" "irsa_test" {
  metadata {
    name = "irsa-test"

    labels = {
      app = "irsa-test"
    }
  }

  spec {
    template {
      metadata {
        labels = {
          app = "irsa-test"
        }
      }

      spec {
        container {
          name    = "irsa-test"
          image   = "amazon/aws-cli:latest"
          command = ["aws", "s3", "ls"]
        }

        restart_policy       = "Never"
        service_account_name = "s3-readonly-sa"
      }
    }
  }
}

# terraform init
# terraform apply --auto-approve
# aws eks --region ap-northeast-2 update-kubeconfig --name eks-cluster-dk
# kubectl get sa
# kubectl get job
# kubectl describe job irsa-test
# kubectl logs -f -l app=irsa-test  --max-log-requests=100
# terraform state list
#   terraform taint kubernetes_job_v1.irsa_test
#   terraform apply --auto-approve
# terraform apply -replace kubernetes_job_v1.irsa_test


###########################################################################
# EBS Addon Test
###########################################################################
/*
resource "kubernetes_storage_class_v1" "ebs-sc" {
  metadata {
    name = "ebs-sc"
  }

  parameters = {
    type = "gp3"
  }

  storage_provisioner    = "ebs.csi.aws.com"
  reclaim_policy         = "Retain"
  allow_volume_expansion = true
  volume_binding_mode    = "WaitForFirstConsumer"
  depends_on = [
     module.eks_ebs_csi_iam_role,
     aws_eks_addon.ebs-csi-addon
  ]
}

resource "kubernetes_persistent_volume_claim_v1" "pvc_ebs" {
  metadata {
    name = "ebs-pvc"
  }

  spec {
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = kubernetes_storage_class_v1.ebs-sc.metadata.0.name
    resources {
      requests = {
        storage = "4Gi"
      }
    }
  }
}

resource "kubernetes_pod_v1" "app_gp_3" {
  metadata {
    name = "app-gp3"
  }

  spec {
    volume {
      name = "persistent-storage"

      persistent_volume_claim {
        claim_name = kubernetes_persistent_volume_claim_v1.pvc_ebs.metadata.0.name
      }
    }

    container {
      name    = "app"
      image   = "centos"
      command = ["/bin/sh"]
      args    = ["-c", "while true; do echo $(date -u) >> /data/out.txt; sleep 5; done"]

      volume_mount {
        name       = "persistent-storage"
        mount_path = "/data"
      }
    }
  }
}
*/

# terraform init
# terraform apply --auto-approve
# aws eks --region ap-northeast-2 update-kubeconfig --name eks-cluster-dk
# kubectl get pod
# kubectl get pvc
# kubectl get pv <PVC_VOLUME_ID> 

###########################################################################
# k8s Auth aws-auth ConfigMap
###########################################################################
locals {
  configmap_roles = [
    {
      rolearn  = aws_iam_role.eks_admin_role.arn
      username = "eks-admin"
      groups   = ["system:masters"]
    },
    {
      rolearn  = aws_iam_role.eks_readonly_role.arn
      username = "eks-readonly"
      groups   = [kubernetes_cluster_role_binding_v1.eksreadonly_clusterrolebinding.subject[0].name] # "eks-readonly-group"
    },
    {
      rolearn  = aws_iam_role.eks_developer_role.arn
      username = "eks-developer"
      groups   = [kubernetes_role_binding_v1.eksdeveloper_rolebinding.subject[0].name] # "eks-developer-group"
    },
  ]
  configmap_users = [
    {
      userarn  = aws_iam_user.admin_user.arn
      username = aws_iam_user.admin_user.name
      groups   = ["system:masters"]
    },
    {
      userarn  = aws_iam_user.basic_user.arn
      username = aws_iam_user.basic_user.name
      groups   = ["system:masters"]
    },
  ]
}

module "eks_auth_controller" {
  source                      = "../eks/modules/terraform-aws-eks-auth"
  manage_aws_auth_configmap   = true
  create_aws_auth_configmap   = false
  aws_auth_node_iam_role_arns = [data.terraform_remote_state.eks.outputs.eks_roles.nodegroup_role_arn]
  aws_auth_roles              = local.configmap_roles
  aws_auth_users              = local.configmap_users

  depends_on = [
    aws_iam_role.eks_admin_role,
    aws_iam_role.eks_readonly_role,
    aws_iam_role.eks_developer_role,
    kubernetes_cluster_role_binding_v1.eksreadonly_clusterrolebinding,
    kubernetes_cluster_role_binding_v1.eksdeveloper_clusterrolebinding,
    kubernetes_role_binding_v1.eksdeveloper_rolebinding
  ]
}

# k8s Auth - Test user auth
resource "aws_iam_user" "admin_user" {
  name          = "eksadmin1"
  path          = "/"
  force_destroy = true
}

resource "aws_iam_user" "basic_user" {
  name          = "eksbasic1"
  path          = "/"
  force_destroy = true
}


resource "aws_iam_user_policy_attachment" "admin_user" {
  user       = aws_iam_user.admin_user.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_user_policy" "basic_user_eks_policy" {
  name = "eks-full-access-policy"
  user = aws_iam_user.basic_user.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "iam:ListRoles",
          "eks:*",
          "ssm:GetParameter"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}


# terraform apply --auto-approve
# aws eks --region ap-northeast-2 update-kubeconfig --name eks-cluster-dk
# kubectl -n kube-system get configmap aws-auth -o yaml
# aws iam create-login-profile --user-name eksadmin1 --password "@EKSUser101" --no-password-reset-required
# aws iam create-access-key --user-name eksadmin1
# aws configure --profile eksadmin1 
#      AWS Access Key ID [None]: <ACCESS KEY>
#      AWS Secret Access Key [None]: <SECRET KEY>
#      Default region name [None]: ap-northeast-2
#      Default output format [None]: json
# aws eks --region ap-northeast-2 update-kubeconfig --name eks-cluster-dk --profile eksadmin1
# cat $HOME/.kube/config
# kubectl get nodes



# k8s Auth - Test role auth

# Role
resource "aws_iam_role" "eks_admin_role" {
  name = "eks-admin-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
      },
    ]
  })

  inline_policy {
    name = "eks-full-access-policy"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action   = ["iam:ListRoles", "eks:*", "ssm:GetParameter"]
          Effect   = "Allow"
          Sid      = ""
          Resource = "*"
        },
      ]
    })
  }
}


# User & Group
resource "aws_iam_user" "eksadmin_guser" {
  name          = "eksadmin-guser"
  path          = "/"
  force_destroy = true
}

resource "aws_iam_group" "eksadmin_iam_group" {
  name = "eksadmins-group"
  path = "/"

  depends_on = [
    aws_iam_role.eks_admin_role,
  ]
}

resource "aws_iam_group_policy" "eksadmin_iam_group" {
  name  = "eksadmins-group-policy"
  group = aws_iam_group.eksadmin_iam_group.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sts:AssumeRole",
        ]
        Sid      = "AllowAssumeOrganizationAccountRole"
        Effect   = "Allow"
        Resource = aws_iam_role.eks_admin_role.arn
      },
    ]
  })
}

resource "aws_iam_group_membership" "eksadmins_membership" {
  name = "eksadmin-group-membership"

  users = [
    aws_iam_user.eksadmin_guser.name,
  ]

  group = aws_iam_group.eksadmin_iam_group.name
}

# terraform import kubernetes_config_map_v1.aws_auth kube-system/aws-auth
# terraform apply --auto-approve
#
# [Test in bastion]
# Configure aws cli eksadmin-guser Profile 
#    aws iam create-login-profile --user-name eksadmin-guser --password "@EKSUser101" --no-password-reset-required
#    aws iam create-access-key --user-name eksadmin-guser
#    aws configure --profile eksadmin-guser 
#         AWS Access Key ID [None]: <ACCESS KEY>
#         AWS Secret Access Key [None]: <SECRET KEY>
#         Default region name [None]: ap-northeast-2
#         Default output format [None]: json
#    aws configure list
#    export AWS_DEFAULT_PROFILE=eksadmin-guser
#    aws sts get-caller-identity
#
# Export AWS Account ID
#    ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
#    echo $ACCOUNT_ID
#
# Assume IAM Role (GUI 에서 eksadmin-guser 의 arn 조회후 아래 명령 수행)
#    aws sts assume-role --role-arn "arn:aws:iam::${ACCOUNT_ID}:role/eks-admin-role" --role-session-name mytest
#    export AWS_ACCESS_KEY_ID=RoleAccessKeyID 
#    export AWS_SECRET_ACCESS_KEY=RoleSecretAccessKey
#    export AWS_SESSION_TOKEN=RoleSessionToken
#
# Verify current user configured in aws cli
#    aws sts get-caller-identity
#
# Configure kubeconfig for kubectl
#    aws eks --region ap-northeast-2 update-kubeconfig --name eks-cluster-dk
#    cat $HOME/.kube/config
#    kubectl get nodes
#
# Switch to default profile
#    unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN
#    export AWS_DEFAULT_PROFILE=default
#    aws sts get-caller-identity
#
# Login as eksadmin-guser user AWS Mgmt Console and Switch Roles
#    Login to AWS Mgmt Console
#    Username: eksadmin-guser
#    Password: @EKSUser101
#    Go to EKS Servie 
#    Click on Switch Role
#        Account: eksadmin-guser
#        Role: eks-admin-role
#        Display Name: eksadmin-session201
#        Select Color: any color
#        Access EKS Cluster -> hr-dev-eksdemo1
#           Overview Tab
#           Workloads Tab
#           Configuration Tab



# k8s Auth - Test role auth (readonly)

resource "aws_iam_role" "eks_readonly_role" {
  name = "eks-readonly-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
      },
    ]
  })

  # https://docs.aws.amazon.com/eks/latest/userguide/view-kubernetes-resources.html
  inline_policy {
    name = "eks-readonly-access-policy"

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action = [
            "iam:ListRoles",
            "ssm:GetParameter",
            "eks:DescribeNodegroup",
            "eks:ListNodegroups",
            "eks:DescribeCluster",
            "eks:ListClusters",
            "eks:AccessKubernetesApi",
            "eks:ListUpdates",
            "eks:ListFargateProfiles",
            "eks:ListIdentityProviderConfigs",
            "eks:ListAddons",
            "eks:DescribeAddonVersions"
          ]
          Effect   = "Allow"
          Resource = "*"
        },
      ]
    })
  }

  tags = {
    tag-key = "eks-readonly-role"
  }
}


# User & Group
resource "aws_iam_user" "eksreadonly_guser" {
  name          = "eksreadonly-guser"
  path          = "/"
  force_destroy = true
}


resource "aws_iam_group" "eksreadonly_iam_group" {
  name = "eksreadonly-group"
  path = "/"

  depends_on = [
    aws_iam_role.eks_readonly_role,
  ]
}

resource "aws_iam_group_policy" "eksreadonly_iam_group" {
  name  = "eksreadonly-group-policy"
  group = aws_iam_group.eksreadonly_iam_group.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sts:AssumeRole",
        ]
        Sid      = "AllowAssumeOrganizationAccountRole"
        Effect   = "Allow"
        Resource = aws_iam_role.eks_readonly_role.arn
      },
    ]
  })
}


# Group Membership
resource "aws_iam_group_membership" "eksreadonly_membership" {
  name = "eksreadonly-group-membership"

  users = [
    aws_iam_user.eksreadonly_guser.name,
  ]

  group = aws_iam_group.eksreadonly_iam_group.name
}

# Cluster Role & Cluster Role Binding
resource "kubernetes_cluster_role_v1" "eksreadonly_clusterrole" {
  metadata {
    name = "eksreadonly-clusterrole"
  }

  rule {
    api_groups = [""] # core APIs 
    resources  = ["nodes", "namespaces", "pods", "events", "services", "configmaps"]
    verbs      = ["get", "list"]
  }
  rule {
    api_groups = ["apps"]
    resources  = ["deployments", "daemonsets", "statefulsets", "replicasets"]
    verbs      = ["get", "list"]
  }
  rule {
    api_groups = ["batch"]
    resources  = ["jobs"]
    verbs      = ["get", "list"]
  }
}

resource "kubernetes_cluster_role_binding_v1" "eksreadonly_clusterrolebinding" {
  metadata {
    name = "eksreadonly-clusterrolebinding"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role_v1.eksreadonly_clusterrole.metadata.0.name
  }
  subject {
    kind      = "Group"
    name      = "eks-readonly-group"
    api_group = "rbac.authorization.k8s.io"
  }
}

# Check ConfigMap
#    aws eks --region ap-northeast-2 update-kubeconfig --name eks-cluster-dk
#    cat $HOME/.kube/config
#    kubectl -n kube-system get configmap aws-auth -o yaml


# k8s Auth - Test role auth (developer)

resource "aws_iam_role" "eks_developer_role" {
  name = "eks-developer-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
      },
    ]
  })
  inline_policy {
    name = "eks-developer-access-policy"

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action = [
            "iam:ListRoles",
            "ssm:GetParameter",
            "eks:DescribeNodegroup",
            "eks:ListNodegroups",
            "eks:DescribeCluster",
            "eks:ListClusters",
            "eks:AccessKubernetesApi",
            "eks:ListUpdates",
            "eks:ListFargateProfiles",
            "eks:ListIdentityProviderConfigs",
            "eks:ListAddons",
            "eks:DescribeAddonVersions"
          ]
          Effect   = "Allow"
          Resource = "*"
        },
      ]
    })
  }
}

resource "aws_iam_user" "eksdeveloper_user" {
  name          = "eksdeveloper"
  path          = "/"
  force_destroy = true
}

resource "aws_iam_group" "eksdeveloper_iam_group" {
  name = "eksdeveloper"
  path = "/"
}

resource "aws_iam_group_policy" "eksdeveloper_iam_group" {
  name  = "eksdeveloper-group-policy"
  group = aws_iam_group.eksdeveloper_iam_group.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sts:AssumeRole",
        ]
        Effect   = "Allow"
        Sid      = "AllowAssumeOrganizationAccountRole"
        Resource = "${aws_iam_role.eks_developer_role.arn}"
      },
    ]
  })
}

resource "aws_iam_group_membership" "eksdeveloper" {
  name = "eksdeveloper-group-membership"
  users = [
    aws_iam_user.eksdeveloper_user.name
  ]
  group = aws_iam_group.eksdeveloper_iam_group.name
}


resource "kubernetes_cluster_role_v1" "eksdeveloper_clusterrole" {
  metadata {
    name = "eksdeveloper-clusterrole"
  }

  rule {
    api_groups = [""]
    resources  = ["nodes", "namespaces", "pods", "events", "services", "configmaps", "serviceaccounts"]
    verbs      = ["get", "list"]
  }
  rule {
    api_groups = ["apps"]
    resources  = ["deployments", "daemonsets", "statefulsets", "replicasets"]
    verbs      = ["get", "list"]
  }
  rule {
    api_groups = ["batch"]
    resources  = ["jobs"]
    verbs      = ["get", "list"]
  }
}

resource "kubernetes_cluster_role_binding_v1" "eksdeveloper_clusterrolebinding" {
  metadata {
    name = "eksdeveloper-clusterrolebinding"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role_v1.eksdeveloper_clusterrole.metadata.0.name
  }
  subject {
    kind      = "Group"
    name      = "eks-developer-group"
    api_group = "rbac.authorization.k8s.io"
  }
}

resource "kubernetes_namespace_v1" "k8s_dev" {
  metadata {
    name = "dev"
  }
}

resource "kubernetes_role_v1" "eksdeveloper_role" {
  metadata {
    name      = "eksdeveloper-role"
  }

  rule {
    api_groups = ["", "extensions", "apps"]
    resources  = ["*"]
    verbs      = ["*"]
  }
  rule {
    api_groups = ["batch"]
    resources  = ["jobs", "cronjobs"]
    verbs      = ["*"]
  }
}

resource "kubernetes_role_binding_v1" "eksdeveloper_rolebinding" {
  metadata {
    name      = "eksdeveloper-rolebinding"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role_v1.eksdeveloper_role.metadata.0.name
  }
  subject {
    kind      = "Group"
    name      = "eks-developer-group"
    api_group = "rbac.authorization.k8s.io"
  }
}

# Check ConfigMap
#    aws eks --region ap-northeast-2 update-kubeconfig --name eks-cluster-dk
#    cat $HOME/.kube/config
#    kubectl -n kube-system get configmap aws-auth -o yaml


###########################################################################
# Ingress Class
#     https://kubernetes.io/docs/concepts/services-networking/ingress-controllers/
#     https://kubernetes.io/docs/concepts/services-networking/ingress/#ingress-class
#     https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.4/guide/ingress/ingress_class/
###########################################################################
resource "kubernetes_ingress_class_v1" "ingress_class_default" {
  metadata {
    name = "my-aws-ingress-class"
    annotations = {
      "ingressclass.kubernetes.io/is-default-class" = "true"
    }
  }

  spec {
    controller = "ingress.k8s.aws/alb"
  }
}

###########################################################################
# Ingress 
###########################################################################
resource "kubernetes_deployment_v1" "app_1__nginx_deployment" {
  metadata {
    name = "app1-nginx-deployment"

    labels = {
      app = "app1-nginx"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "app1-nginx"
      }
    }

    template {
      metadata {
        labels = {
          app = "app1-nginx"
        }
      }

      spec {
        container {
          name  = "app1-nginx"
          image = "kin3303/mynginx1"

          port {
            container_port = 80
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "app_1__nginx_nodeport_service" {
  metadata {
    name = "app1-nginx-nodeport-service"

    labels = {
      app = "app1-nginx"
    }

    annotations = {
      "alb.ingress.kubernetes.io/healthcheck-path" = "/app1/index.html"
    }
  }

  spec {
    port {
      port        = 80
      target_port = "80"
    }

    selector = {
      app = "app1-nginx"
    }

    type = "NodePort"
  }
}

resource "kubernetes_deployment_v1" "app_2__nginx_deployment" {
  metadata {
    name = "app2-nginx-deployment"

    labels = {
      app = "app2-nginx"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "app2-nginx"
      }
    }

    template {
      metadata {
        labels = {
          app = "app2-nginx"
        }
      }

      spec {
        container {
          name  = "app2-nginx"
          image = "kin3303/mynginx2"

          port {
            container_port = 80
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "app_2__nginx_nodeport_service" {
  metadata {
    name = "app2-nginx-nodeport-service"

    labels = {
      app = "app2-nginx"
    }

    annotations = {
      "alb.ingress.kubernetes.io/healthcheck-path" = "/app2/index.html"
    }
  }

  spec {
    port {
      port        = 80
      target_port = "80"
    }

    selector = {
      app = "app2-nginx"
    }

    type = "NodePort"
  }
}

resource "kubernetes_deployment_v1" "default_nginx_deployment" {
  metadata {
    name = "default-nginx-deployment"
    labels = {
      app = "default-nginx"
    }
  }

  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "default-nginx"
      }
    }

    template {
      metadata {
        labels = {
          app = "default-nginx"
        }
      }

      spec {
        container {
          name  = "default-nginx"
          image = "nginx:latest"
          port {
            container_port = 80
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "default_nginx_nodeport_service" {
  metadata {
    name = "default-nginx-nodeport-service"

    labels = {
      app = "default-nginx"
    }

    annotations = {
      "alb.ingress.kubernetes.io/healthcheck-path" = "/index.html"
    }
  }

  spec {
    port {
      port        = 80
      target_port = "80"
    }

    selector = {
      app = "default-nginx"
    }

    type = "NodePort"
  }
}

# SSL Certificate (Amazon Issued)
/*
resource "aws_acm_certificate" "acm_cert" {
  domain_name       = "k8s.idtplateer.com"
  validation_method = "DNS" 

  lifecycle {
    create_before_destroy = true
   }
}

data "aws_route53_zone" "zone" {
  name         = "idtplateer.com"
  private_zone = false
}

resource "aws_route53_record" "dns_record" {
  for_each = {
    for dvo in aws_acm_certificate.acm_cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }
  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.zone.zone_id
}

resource "aws_acm_certificate_validation" "example" {
  certificate_arn         = aws_acm_certificate.acm_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.dns_record : record.fqdn]
}
*/

# Annotations
#   https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.1/guide/ingress/annotations/
# SSL
#   https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.1/guide/ingress/cert_discovery/
# External DNS Annoatation
#   https://github.com/kubernetes-sigs/external-dns/tree/master/charts/external-dns#configuration
#   https://github.com/kubernetes-sigs/external-dns/blob/master/docs/tutorials/alb-ingress.md
#   https://github.com/kubernetes-sigs/external-dns/blob/master/docs/tutorials/aws.md

resource "kubernetes_ingress_v1" "ingress_conthext_path_test" {
  metadata {
    name = "ingress-conthext-path-test"

    annotations = {
      # Load balancer name
      "alb.ingress.kubernetes.io/load-balancer-name" = "ingress-cpr"

      # Ingress core settings
      "alb.ingress.kubernetes.io/scheme" = "internet-facing"

      # Health check settings
      "alb.ingress.kubernetes.io/healthcheck-interval-seconds" = "15"
      "alb.ingress.kubernetes.io/healthcheck-port"             = "traffic-port"
      "alb.ingress.kubernetes.io/healthcheck-protocol"         = "HTTP"
      "alb.ingress.kubernetes.io/healthcheck-timeout-seconds"  = "5"
      "alb.ingress.kubernetes.io/healthy-threshold-count"      = "2"
      "alb.ingress.kubernetes.io/success-codes"                = "200"
      "alb.ingress.kubernetes.io/unhealthy-threshold-count"    = "2"

      # SSL
      "alb.ingress.kubernetes.io/listen-ports" = jsonencode([{ "HTTPS" = 443 }, { "HTTP" = 80 }])
      #"alb.ingress.kubernetes.io/certificate-arn" = "arn:aws:acm:ap-northeast-2:960249453675:certificate/3915d0da-6dd2-4384-8fb0-558b25bf1ff4"
      #"alb.ingress.kubernetes.io/ssl-policy" = "ELBSecurityPolicy-TLS-1-1-2017-01"
      "alb.ingress.kubernetes.io/ssl-redirect" = 443

      # External DNS - Create Record Set to AWS Route 53
      "external-dns.alpha.kubernetes.io/hostname" = "k8s.idtplateer.com"
    }
  }

  spec {
    ingress_class_name = "my-aws-ingress-class"

    default_backend {
      service {
        name = kubernetes_service_v1.default_nginx_nodeport_service.metadata[0].name
        port {
          number = 80
        }
      }
    }

    tls {
      hosts = ["*.idtplateer.com"]
    }

    rule {
      host = "k8sapp1.idtplateer.com"
      http {
        path {
          #path      = "/app1"
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = kubernetes_service_v1.app_1__nginx_nodeport_service.metadata[0].name
              port {
                number = 80
              }
            }
          }
        }
      }
    }

    rule {
      host = "k8sapp2.idtplateer.com"
      http {
        path {
          #path      = "/app2"
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = kubernetes_service_v1.app_2__nginx_nodeport_service.metadata[0].name
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }
}

# Check Ingress
#    aws eks --region ap-northeast-2 update-kubeconfig --name eks-cluster-dk
#    


###########################################################################
# Ingress Group
###########################################################################
resource "kubernetes_deployment_v1" "app_1_group_nginx_deployment" {
  metadata {
    name = "app1-group-nginx-deployment"

    labels = {
      app = "app1-group-nginx"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "app1-group-nginx"
      }
    }

    template {
      metadata {
        labels = {
          app = "app1-group-nginx"
        }
      }

      spec {
        container {
          name  = "app1-group-nginx"
          image = "kin3303/mynginx1"

          port {
            container_port = 80
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "app_1_group_nginx_nodeport_service" {
  metadata {
    name = "app1-group-nginx-nodeport-service"

    labels = {
      app = "app1-group-nginx"
    }

    annotations = {
      "alb.ingress.kubernetes.io/healthcheck-path" = "/app1/index.html"
    }
  }

  spec {
    port {
      port        = 80
      target_port = "80"
    }

    selector = {
      app = "app1-group-nginx"
    }

    type = "NodePort"
  }
}

resource "kubernetes_deployment_v1" "app_2_group_nginx_deployment" {
  metadata {
    name = "app2-group-nginx-deployment"

    labels = {
      app = "app2-group-nginx"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "app2-group-nginx"
      }
    }

    template {
      metadata {
        labels = {
          app = "app2-group-nginx"
        }
      }

      spec {
        container {
          name  = "app2-group-nginx"
          image = "kin3303/mynginx2"

          port {
            container_port = 80
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "app_2_group_nginx_nodeport_service" {
  metadata {
    name = "app2-group-nginx-nodeport-service"

    labels = {
      app = "app2-group-nginx"
    }

    annotations = {
      "alb.ingress.kubernetes.io/healthcheck-path" = "/app2/index.html"
    }
  }

  spec {
    port {
      port        = 80
      target_port = "80"
    }

    selector = {
      app = "app2-group-nginx"
    }

    type = "NodePort"
  }
}

resource "kubernetes_deployment_v1" "default_group_nginx_deployment" {
  metadata {
    name = "default-group-nginx-deployment"
    labels = {
      app = "default-group-nginx"
    }
  }

  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "default-group-nginx"
      }
    }

    template {
      metadata {
        labels = {
          app = "default-group-nginx"
        }
      }

      spec {
        container {
          name  = "default-group-nginx"
          image = "nginx:latest"
          port {
            container_port = 80
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "default_group_nginx_nodeport_service" {
  metadata {
    name = "default-group-nginx-nodeport-service"

    labels = {
      app = "default-group-nginx"
    }

    annotations = {
      "alb.ingress.kubernetes.io/healthcheck-path" = "/index.html"
    }
  }

  spec {
    port {
      port        = 80
      target_port = "80"
    }

    selector = {
      app = "default-group-nginx"
    }

    type = "NodePort"
  }
}

resource "kubernetes_ingress_v1" "ingress_group_app1" {
  metadata {
    name = "ingress-group-test-app1"

    annotations = {
      # Load balancer name
      "alb.ingress.kubernetes.io/load-balancer-name" = "ingress-group"

      # Ingress core settings
      "alb.ingress.kubernetes.io/scheme" = "internet-facing"

      # Health check settings
      "alb.ingress.kubernetes.io/healthcheck-interval-seconds" = "15"
      "alb.ingress.kubernetes.io/healthcheck-port"             = "traffic-port"
      "alb.ingress.kubernetes.io/healthcheck-protocol"         = "HTTP"
      "alb.ingress.kubernetes.io/healthcheck-timeout-seconds"  = "5"
      "alb.ingress.kubernetes.io/healthy-threshold-count"      = "2"
      "alb.ingress.kubernetes.io/success-codes"                = "200"
      "alb.ingress.kubernetes.io/unhealthy-threshold-count"    = "2"

      # SSL
      "alb.ingress.kubernetes.io/listen-ports"    = jsonencode([{ "HTTPS" = 443 }, { "HTTP" = 80 }])
      "alb.ingress.kubernetes.io/certificate-arn" = "arn:aws:acm:ap-northeast-2:960249453675:certificate/3915d0da-6dd2-4384-8fb0-558b25bf1ff4"
      "alb.ingress.kubernetes.io/ssl-policy"      = "ELBSecurityPolicy-TLS-1-1-2017-01"
      "alb.ingress.kubernetes.io/ssl-redirect"    = 443

      # External DNS - Create Record Set to AWS Route 53
      "external-dns.alpha.kubernetes.io/hostname" = "k8sgroup.idtplateer.com"

      # Ingress Groups
      "alb.ingress.kubernetes.io/group.name"  = "myapps.web"
      "alb.ingress.kubernetes.io/group.order" = 10
    }
  }

  spec {
    ingress_class_name = "my-aws-ingress-class"

    rule {
      http {
        path {
          path      = "/app1"
          path_type = "Prefix"

          backend {
            service {
              name = kubernetes_service_v1.app_1_group_nginx_nodeport_service.metadata[0].name
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_ingress_v1" "ingress_group_app2" {
  metadata {
    name = "ingress-group-test-app2"

    annotations = {
      # Load balancer name
      "alb.ingress.kubernetes.io/load-balancer-name" = "ingress-group"

      # Ingress core settings
      "alb.ingress.kubernetes.io/scheme" = "internet-facing"

      # Health check settings
      "alb.ingress.kubernetes.io/healthcheck-interval-seconds" = "15"
      "alb.ingress.kubernetes.io/healthcheck-port"             = "traffic-port"
      "alb.ingress.kubernetes.io/healthcheck-protocol"         = "HTTP"
      "alb.ingress.kubernetes.io/healthcheck-timeout-seconds"  = "5"
      "alb.ingress.kubernetes.io/healthy-threshold-count"      = "2"
      "alb.ingress.kubernetes.io/success-codes"                = "200"
      "alb.ingress.kubernetes.io/unhealthy-threshold-count"    = "2"

      # SSL
      "alb.ingress.kubernetes.io/listen-ports"    = jsonencode([{ "HTTPS" = 443 }, { "HTTP" = 80 }])
      "alb.ingress.kubernetes.io/certificate-arn" = "arn:aws:acm:ap-northeast-2:960249453675:certificate/3915d0da-6dd2-4384-8fb0-558b25bf1ff4"
      "alb.ingress.kubernetes.io/ssl-policy"      = "ELBSecurityPolicy-TLS-1-1-2017-01"
      "alb.ingress.kubernetes.io/ssl-redirect"    = 443

      # External DNS - Create Record Set to AWS Route 53
      "external-dns.alpha.kubernetes.io/hostname" = "k8sgroup.idtplateer.com"

      # Ingress Groups
      "alb.ingress.kubernetes.io/group.name"  = "myapps.web"
      "alb.ingress.kubernetes.io/group.order" = 20
    }
  }

  spec {
    ingress_class_name = "my-aws-ingress-class"

    rule {
      http {
        path {
          path      = "/app2"
          path_type = "Prefix"

          backend {
            service {
              name = kubernetes_service_v1.app_2_group_nginx_nodeport_service.metadata[0].name
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_ingress_v1" "ingress_group_app3" {
  metadata {
    name = "ingress-group-test-app3"

    annotations = {
      # Load balancer name
      "alb.ingress.kubernetes.io/load-balancer-name" = "ingress-group"

      # Ingress core settings
      "alb.ingress.kubernetes.io/scheme" = "internet-facing"

      # Health check settings
      "alb.ingress.kubernetes.io/healthcheck-interval-seconds" = "15"
      "alb.ingress.kubernetes.io/healthcheck-port"             = "traffic-port"
      "alb.ingress.kubernetes.io/healthcheck-protocol"         = "HTTP"
      "alb.ingress.kubernetes.io/healthcheck-timeout-seconds"  = "5"
      "alb.ingress.kubernetes.io/healthy-threshold-count"      = "2"
      "alb.ingress.kubernetes.io/success-codes"                = "200"
      "alb.ingress.kubernetes.io/unhealthy-threshold-count"    = "2"

      # SSL
      "alb.ingress.kubernetes.io/listen-ports"    = jsonencode([{ "HTTPS" = 443 }, { "HTTP" = 80 }])
      "alb.ingress.kubernetes.io/certificate-arn" = "arn:aws:acm:ap-northeast-2:960249453675:certificate/3915d0da-6dd2-4384-8fb0-558b25bf1ff4"
      "alb.ingress.kubernetes.io/ssl-policy"      = "ELBSecurityPolicy-TLS-1-1-2017-01"
      "alb.ingress.kubernetes.io/ssl-redirect"    = 443

      # External DNS - Create Record Set to AWS Route 53
      "external-dns.alpha.kubernetes.io/hostname" = "k8sgroup.idtplateer.com"

      # Ingress Groups
      "alb.ingress.kubernetes.io/group.name"  = "myapps.web"
      "alb.ingress.kubernetes.io/group.order" = 30
    }
  }

  spec {
    ingress_class_name = "my-aws-ingress-class"

    default_backend {
      service {
        name = kubernetes_service_v1.default_group_nginx_nodeport_service.metadata[0].name
        port {
          number = 80
        }
      }
    }
  }
}
