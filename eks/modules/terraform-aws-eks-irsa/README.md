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
module "iam_eks_role" {
  source    = "../eks/modules/iam-role-for-service-accounts-eks"
  role_name = "my-app"

  oidc_providers = {
    one = {
      provider_arn               = "arn:aws:iam::012345678901:oidc-provider/oidc.eks.us-east-1.amazonaws.com/id/5C54DDF35ER19312844C7333374CC09D"
      namespace_service_accounts = ["default:my-app-staging", "canary:my-app-staging"]
    }
    two = {
      provider_arn               = "arn:aws:iam::012345678901:oidc-provider/oidc.eks.ap-southeast-1.amazonaws.com/id/5C54DDF35ER54476848E7333374FF09G"
      namespace_service_accounts = ["default:my-app-staging"]
    }
  }
}
```