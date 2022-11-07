
## Install kubectl CLI
- [Install kubectl CLI](https://docs.aws.amazon.com/eks/latest/userguide/install-kubectl.html)

 
## kubeconfig
- [EKS configure kubectl](https://docs.aws.amazon.com/eks/latest/userguide/getting-started-console.html#eks-configure-kubectl)


## k8s cheatsheet
- [k8s cheatsheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet)

```console
aws eks --region ap-northeast-2 update-kubeconfig --name eks-cluster-dk
kubectl get nodes
kubectl get nodes -o wide
kubectl get namespaces
kubectl get all -n kube-node-lease
kubectl get all -n kube-public
kubectl get all -n default
kubectl describe ds aws-node -n kube-system
kubectl describe ds kube-proxy -n kube-system
kubectl describe deploy coredns -n kube-system

```

## Bastion Host 에서 EKS Worker Node 접속후 아래 확인

```console
cd /tmp

# Connect Node
ssh -i eks-terraform-key.pem ec2-user@<Public-NodeGroup-EC2Instance-PrivateIP>
ssh -i eks-terraform-key.pem ec2-user@<Public-NodeGroup-EC2Instance-PublicIP>

# Verify if kubelet and kube-proxy running
ps -ef | grep kube

# Verify kubelet-config.json
cat /etc/kubernetes/kubelet/kubelet-config.json

# Verify kubelet kubeconfig
cat /var/lib/kubelet/kubeconfig

# Verify clusters.cluster.server value(EKS Cluster API Server Endpoint) 
wget <Kubernetes API Server Endpoint>
wget https://0cbda14fd801e669f05c2444fb16d1b5.gr7.us-east-1.eks.amazonaws.com
``` 