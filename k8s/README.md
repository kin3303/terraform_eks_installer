
## Install k2tf

- [Install k2tf CLI](https://github.com/sl1pm4t/k2tf)
 
## kubeconfig
- [EKS configure kubectl](https://docs.aws.amazon.com/eks/latest/userguide/getting-started-console.html#eks-configure-kubectl)


## k8s cheatsheet
- [k8s cheatsheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet)


## Use k2tf

```console
cat .\k2tf\ns.yaml | C:\Windows\Terraform\k2tf.exe
resource "kubernetes_namespace" "lbtest" {
  metadata {
    name = "lbtest"
  }
}
```

## Depoly k8s Resources

```console
terraform init
terraform apply --auto-approve
aws eks --region ap-northeast-2 update-kubeconfig --name eks-cluster-dk
```
