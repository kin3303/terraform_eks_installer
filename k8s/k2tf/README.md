## Install k2tf

- [Install k2tf CLI](# k2tf - https://github.com/sl1pm4t/k2tf)

## Test k2tf

```
cat ns.yaml | C:\Windows\Terraform\k2tf.exe
resource "kubernetes_namespace" "lbtest" {
  metadata {
    name = "lbtest"
  }
}
```

Online

```
https://www.javainuse.com/yaml2tcf
```