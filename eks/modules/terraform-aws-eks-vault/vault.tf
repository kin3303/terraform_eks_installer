###########################################################################################
# Vault Installation
#   https://developer.hashicorp.com/vault/tutorials/kubernetes/kubernetes-raft-deployment-guide
###########################################################################################
resource "kubernetes_namespace" "vault" {
  metadata {
    name = "vault-server"
  }
}

data "template_file" "vault-values" {
  template = <<EOF
global:
  enabled: true
  imagePullSecrets: []
  tlsDisable: false
  externalVaultAddr: ""
  openshift: false
  psp:
    enable: false
    annotations: |
      seccomp.security.alpha.kubernetes.io/allowedProfileNames: docker/default,runtime/default
      apparmor.security.beta.kubernetes.io/allowedProfileNames: runtime/default
      seccomp.security.alpha.kubernetes.io/defaultProfileName:  runtime/default
      apparmor.security.beta.kubernetes.io/defaultProfileName:  runtime/default
  serverTelemetry:
    prometheusOperator: false
injector:
  enabled: "-"
  replicas: 1
  port: 8080
  leaderElector:
    enabled: true
  metrics:
    enabled: false
  externalVaultAddr: ""
  image:
    repository: "hashicorp/vault-k8s"
    tag: "1.0.1"
    pullPolicy: IfNotPresent
  agentImage:
    repository: "hashicorp/vault"
    tag: "1.12.0"
  agentDefaults:
    cpuLimit: "500m"
    cpuRequest: "250m"
    memLimit: "128Mi"
    memRequest: "64Mi"
    template: "map"
    templateConfig:
      exitOnRetryFailure: true
      staticSecretRenderInterval: ""
  authPath: "auth/kubernetes"
  logLevel: "info"
  logFormat: "standard"
  revokeOnShutdown: false
  webhook:
    failurePolicy: Ignore
    matchPolicy: Exact
    timeoutSeconds: 30
    namespaceSelector: {}
    objectSelector: |
      matchExpressions:
      - key: app.kubernetes.io/name
        operator: NotIn
        values:
        - {{ template "vault.name" . }}-agent-injector
    annotations: {}
  failurePolicy: Ignore
  namespaceSelector: {}
  objectSelector: {}
  webhookAnnotations: {}
  certs:
    secretName: null
    caBundle: ""
    certName: tls.crt
    keyName: tls.key
  securityContext:
    pod: {}
    container: {}
  resources: {}
  extraEnvironmentVars: {}
  affinity: |
    podAntiAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        - labelSelector:
            matchLabels:
              app.kubernetes.io/name: {{ template "vault.name" . }}-agent-injector
              app.kubernetes.io/instance: "{{ .Release.Name }}"
              component: webhook
          topologyKey: kubernetes.io/hostname
  topologySpreadConstraints: []
  tolerations: []
  nodeSelector: {}
  priorityClassName: ""
  annotations: {}
  extraLabels: {}
  hostNetwork: false
  service:
    annotations: {}
  serviceAccount:
    annotations: {}
  podDisruptionBudget: {}
  strategy: {}

server:
  enabled: "-"
  enterpriseLicense:
    secretName: ""
    secretKey: "license"
  image:
    repository: "hashicorp/vault"
    tag: "1.12.0"
    pullPolicy: IfNotPresent
  updateStrategyType: "OnDelete"
  logLevel: ""
  logFormat: ""
  resources:
    requests:
      memory: 1Gi
      cpu: 500m
    limits:
      memory: 2Gi
      cpu: 800m
  ingress:
    enabled: false
    labels: {}
    annotations: {}
    ingressClassName: ""
    pathType: Prefix
    activeService: true
    hosts:
      - host: chart-example.local
        paths: []
    extraPaths: []
    tls: []
  route:
    enabled: false
    activeService: true
    labels: {}
    annotations: {}
    host: chart-example.local
    tls:
      termination: passthrough
  authDelegator:
    enabled: true
  extraInitContainers: null
  extraContainers: null
  shareProcessNamespace: false
  extraArgs: ""
  readinessProbe:
    enabled: true
    path: "/v1/sys/health?standbyok=true&sealedcode=204&uninitcode=204"
    failureThreshold: 2
    initialDelaySeconds: 5
    periodSeconds: 5
    successThreshold: 1
    timeoutSeconds: 3
  livenessProbe:
    enabled: false
    path: "/v1/sys/health?standbyok=true"
    failureThreshold: 2
    initialDelaySeconds: 60
    periodSeconds: 5
    successThreshold: 1
    timeoutSeconds: 3
  terminationGracePeriodSeconds: 10
  preStopSleepSeconds: 5
  postStart: []
  extraEnvironmentVars:
    VAULT_CACERT: /vault/userconfig/vault-server-tls/vault.ca
  extraSecretEnvironmentVars: []
  extraVolumes:
  - type: secret
    name: vault-server-tls  
  volumes: null
  volumeMounts: null
  affinity: |
    podAntiAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        - labelSelector:
            matchLabels:
              app.kubernetes.io/name: {{ template "vault.name" . }}
              app.kubernetes.io/instance: "{{ .Release.Name }}"
              component: server
          topologyKey: kubernetes.io/hostname
  topologySpreadConstraints: []
  tolerations: []
  nodeSelector: |
    eks.amazonaws.com/nodegroup: ${var.node_group_private_name}
  networkPolicy:
    enabled: false
    egress: []
  priorityClassName: ""
  extraLabels: {}
  annotations: {}
  service:
    enabled: true
    publishNotReadyAddresses: true
    externalTrafficPolicy: Cluster
    port: 8200
    targetPort: 8200
    annotations: {}
  dataStorage:
    enabled: true
    size: 10Gi
    mountPath: "/vault/data"
    storageClass: null
    accessMode: ReadWriteOnce
    annotations: {}
  auditStorage:
    enabled: false
    size: 10Gi
    mountPath: "/vault/audit"
    storageClass: null
    accessMode: ReadWriteOnce
    annotations: {}
  dev:
    enabled: false
    devRootToken: "root"
  standalone:
    enabled: false
    config: |
      ui = true
      listener "tcp" {
        tls_disable = 1
        address = "[::]:8200"
        cluster_address = "[::]:8201"
      }
      storage "file" {
        path = "/vault/data"
      }
  ha:
    enabled: true
    replicas: 3
    apiAddr: null
    clusterAddr: null
    raft:
      enabled: true
      setNodeId: true
      config: |
        ui = true
        listener "tcp" {
          tls_disable = 0
          tls_cert_file = "/vault/userconfig/vault-server-tls/vault.crt"
          tls_key_file  = "/vault/userconfig/vault-server-tls/vault.key"
          tls_client_ca_file = "/vault/userconfig/vault-server-tls/vault.ca"		  
          address = "[::]:8200"
          cluster_address = "[::]:8201"
        }
        storage "raft" {
          path = "/vault/data"

          retry_join {
            leader_api_addr = "https://vault-0.vault-internal:8200"
            leader_client_cert_file = "/vault/userconfig/vault-server-tls/vault.crt"
            leader_client_key_file  = "/vault/userconfig/vault-server-tls/vault.key"
            leader_ca_cert_file = "/vault/userconfig/vault-server-tls/vault.ca"		  
          }
          retry_join {
            leader_api_addr = "https://vault-1.vault-internal:8200"
            leader_client_cert_file = "/vault/userconfig/vault-server-tls/vault.crt"
            leader_client_key_file  = "/vault/userconfig/vault-server-tls/vault.key"
            leader_ca_cert_file = "/vault/userconfig/vault-server-tls/vault.ca"		  
          }
          retry_join {
            leader_api_addr = "https://vault-2.vault-internal:8200"
            leader_client_cert_file = "/vault/userconfig/vault-server-tls/vault.crt"
            leader_client_key_file  = "/vault/userconfig/vault-server-tls/vault.key"
            leader_ca_cert_file = "/vault/userconfig/vault-server-tls/vault.ca"		  
          }

          autopilot {
            cleanup_dead_servers = "true"
            last_contact_threshold = "200ms"
            last_contact_failure_threshold = "10m"
            max_trailing_logs = 250000
            min_quorum = 5
            server_stabilization_time = "20s"
          }
        }
        
        service_registration "kubernetes" {}
        seal "awskms" {
          region     = "${var.aws_region}"
          kms_key_id = "${aws_kms_key.vault_kms.key_id}"
        }
    disruptionBudget:
      enabled: true
      maxUnavailable: null
  serviceAccount:
    create: false
    name: "${kubernetes_service_account_v1.boot_vault.metadata[0].name}"
    annotations: |
      eks.amazonaws.com/role-arn: "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${local.resource_names.vault_iam_role_name}"
  statefulSet:
    annotations: {}
    securityContext:
      pod: {}
      container: {}
  hostNetwork: false

ui:
  enabled: true
  externalPort: 443
  serviceType: "LoadBalancer"
  loadBalancerSourceRanges:
  - 0.0.0.0/0
  annotations: | 
    service.beta.kubernetes.io/aws-load-balancer-ssl-cert: ${var.acm_vault_arn}
    service.beta.kubernetes.io/aws-load-balancer-backend-protocol: https
    service.beta.kubernetes.io/aws-load-balancer-ssl-ports: "443,8200"
    service.beta.kubernetes.io/do-loadbalancer-healthcheck-path: "/ui/"
    service.beta.kubernetes.io/aws-load-balancer-internal: "false"
    external-dns.alpha.kubernetes.io/hostname: "vault.${var.public_dns_name}"
    external-dns.alpha.kubernetes.io/ttl: "30"

csi:
  enabled: false
  image:
    repository: "hashicorp/vault-csi-provider"
    tag: "1.2.0"
    pullPolicy: IfNotPresent
  volumes: null
  volumeMounts: null
  resources: {}
  daemonSet:
    updateStrategy:
      type: RollingUpdate
      maxUnavailable: ""
    annotations: {}
    providersDir: "/etc/kubernetes/secrets-store-csi-providers"
    kubeletRootDir: "/var/lib/kubelet"
    extraLabels: {}
    securityContext:
      pod: {}
      container: {}
  pod:
    annotations: {}
    tolerations: []
    extraLabels: {}
  priorityClassName: ""
  serviceAccount:
    annotations: {}
    extraLabels: {}
  readinessProbe:
    failureThreshold: 2
    initialDelaySeconds: 180
    periodSeconds: 5
    successThreshold: 1
    timeoutSeconds: 3
  livenessProbe:
    failureThreshold: 2
    initialDelaySeconds: 300
    periodSeconds: 5
    successThreshold: 1
    timeoutSeconds: 3
  debug: false
  extraArgs: []
serverTelemetry:
  serviceMonitor:
    enabled: false
    selectors: {}
    interval: 30s
    scrapeTimeout: 10s
  prometheusRules:
      enabled: false
      selectors: {}
      rules: {}
   EOF
}

resource "helm_release" "vault" {
  name              = var.release_name
  chart             = var.chart_name
  repository        = var.chart_repository
  version           = var.chart_version
  namespace         = kubernetes_namespace.vault.metadata[0].name
  create_namespace  = false
  max_history       = var.max_history
  timeout           = var.chart_timeout
  cleanup_on_fail   = true
  dependency_update = true

  values = concat([data.template_file.vault-values.rendered], var.additional_chart_values)

  depends_on = [
    kubernetes_secret.vault_server_tls_certificate
  ]
}


###########################################################################################
# Vault TLS Certificate
###########################################################################################
module "eks_private_cert" {
  source            = "../terraform-aws-eks-private-tls"
  organization_name = "Plateer, Inc"
  common_name       = "idtplateer.com"
  ca_common_name    = "idtplateer.com"
  dns_names = [
    "vault",
    "vault.vault-server",
    "vault.vault-server.svc",
    "vault.vault-server.svc.cluster.local",
    "vault-0.vault-internal",
    "vault-1.vault-internal",
    "vault-2.vault-internal"
  ]
  ip_addresses = [
    "127.0.0.1"
  ]
  validity_period_hours = 764

}


resource "kubernetes_secret" "vault_server_tls_certificate" {
  metadata {
    name      = "vault-server-tls"
    namespace = kubernetes_namespace.vault.metadata[0].name
  }

  type = "Opaque"

  data = {
    "vault.crt" = "${module.eks_private_cert.public_key}"
    "vault.key" = "${module.eks_private_cert.private_key}"
    "vault.ca"  = "${module.eks_private_cert.ca_public_key}"
  }
  depends_on = [
    module.eks_private_cert
  ]
}