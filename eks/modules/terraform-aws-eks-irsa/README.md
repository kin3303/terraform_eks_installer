## IAM Role for Service Accounts in EKS

EKS 내에서 일반적으로 사용되는 Controller/Custom 리소스에 대한 선택적 정책을 사용하여 AWS EKS 서비스 계정에서 가정할 수 있는 IAM Role 을 생성한다.
IAM Role 생성시 지원되는 선택적 AWS Policy 는 아래와 같다.

- [Cert-Manager](https://cert-manager.io/docs/configuration/acme/dns01/route53/#set-up-an-iam-role)
- [Cluster Autoscaler](https://github.com/kubernetes/autoscaler/blob/master/cluster-autoscaler/cloudprovider/aws/README.md)
- [EBS CSI Driver](https://github.com/kubernetes-sigs/aws-ebs-csi-driver/blob/master/docs/example-iam-policy.json)
- [EFS CSI Driver](https://github.com/kubernetes-sigs/aws-efs-csi-driver/blob/master/docs/iam-policy-example.json)
- [External DNS](https://github.com/kubernetes-sigs/external-dns/blob/master/docs/tutorials/aws.md#iam-policy)
- [External Secrets](https://github.com/external-secrets/kubernetes-external-secrets#add-a-secret)
- [FSx for Lustre CSI Driver](https://github.com/kubernetes-sigs/aws-fsx-csi-driver/blob/master/docs/README.md)
- [Karpenter](https://github.com/aws/karpenter/blob/main/website/content/en/preview/getting-started/cloudformation.yaml)
- [Load Balancer Controller](https://github.com/kubernetes-sigs/aws-load-balancer-controller/blob/main/docs/install/iam_policy.json)
- [Load Balancer Controller Target Group Binding Only](https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.4/deploy/installation/#iam-permission-subset-for-those-who-use-targetgroupbinding-only-and-dont-plan-to-use-the-aws-load-balancer-controller-to-manage-security-group-rules)
- [App Mesh Controller](https://github.com/aws/aws-app-mesh-controller-for-k8s/blob/master/config/iam/controller-iam-policy.json)
- [App Mesh Envoy Proxy](https://raw.githubusercontent.com/aws/aws-app-mesh-controller-for-k8s/master/config/iam/envoy-iam-policy.json)
- [Managed Service for Prometheus](https://docs.aws.amazon.com/prometheus/latest/userguide/set-up-irsa.html)
- [Node Termination Handler](https://github.com/aws/aws-node-termination-handler#5-create-an-iam-role-for-the-pods)
- [Velero](https://github.com/vmware-tanzu/velero-plugin-for-aws#option-1-set-permissions-with-an-iam-user)
- [VPC CNI](https://docs.aws.amazon.com/eks/latest/userguide/cni-iam-role.html)
 
EKS에서 '서비스 계정'이 IAM 역할을 수행할 수 있는 방법에 대한 자세한 내용은 아래 페이지를 참고하자.
- [EKS documentation](https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html).


이 모듈의 기본 설정은 아래와 같다.

```hcl
# 기존
locals {
  oidc_provider_arn         = data.terraform_remote_state.eks.outputs.eks_oidc_provider.arn
  oidc_provider_url_extract = "${replace(data.terraform_remote_state.eks.outputs.eks_oidc_provider.url, "https://", "")}:sub"
}

resource "aws_iam_role" "irsa_s3_read_only_role" {
  name = "irsa-s3-readonly-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Federated = local.oidc_provider_arn # https://docs.aws.amazon.com/ko_kr/IAM/latest/UserGuide/id_roles_providers.html
        }
        Condition = {
          StringEquals = { #oidc.eks.ap-northeast-2.amazonaws.com/id/A9CA35794A78F8EF8F3A154C3B892A73:sub
            "${local.oidc_provider_url_extract}" : "system:serviceaccount:default:${var.sa_s3_readonly}"
          }
        }
      },
    ]
  })

  tags = {
    tag-key = "irsa-s3-readonly-role"
  }
}

resource "aws_iam_role_policy_attachment" "irsa_iam_role_policy_attach" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
  role       = aws_iam_role.irsa_s3_read_only_role.name
}

# 모듈사용
module "eks_irsa_role" {
  source                     = "../eks/modules/terraform-aws-eks-irsa"
  provider_arn               = local.oidc_provider_arn
  role_name                  = "irsa-s3-readonly-role"
  namespace_service_accounts = ["default:${var.sa_s3_readonly}"]
  role_policy_arns           = ["arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"]
}
```
