#################################################################################
# Chart
#################################################################################
variable "release_name" {
  description = "Helm release name for Consul"
  default     = "consul"
}

variable "chart_name" {
  description = "Helm chart name to provision"
  default     = "consul"
}

variable "chart_repository" {
  description = "Helm repository for the chart"
  default     = "https://helm.releases.hashicorp.com"
}

variable "chart_version" {
  description = "Version of Chart to install. Set to empty to install the latest version"
  default     = "1.0.1"
}

variable "chart_namespace" {
  description = "Namespace to install the chart into"
  default     = "default"
}

variable "create_namespace" {
  description = " Create the namespace if it does not yet exist"
  default     = false
}

variable "chart_timeout" {
  description = "Timeout to wait for the Chart to be deployed. The chart waits for all Daemonset pods to be healthy before ending. Increase this for larger clusers to avoid timeout"
  default     = 600
}

variable "max_history" {
  description = "Max History for Helm"
  default     = 20
}

variable "additional_chart_values" {
  description = "Additional values for the Consul Helm Chart in YAML"
  type        = list(string)
  default     = []
}

#################################################################################
# global
#################################################################################
variable "name" {
  description = "Sets the prefix used for all resources in the helm chart. If not set, the prefix will be \"<helm release name>-consul\"."
  default     = "consul"
}

variable "log_json_enable" {
  description = "Enable all component logs to be output in JSON format"
  default     = false
}

variable "consul_domain" {
  description = "Top level Consul domain for DNS queries"
  default     = "consul"
}

variable "pod_security_policy_enable" {
  description = "Create PodSecurityPolicy Resources"
  default     = true
}

variable "consul_datacenter" {
  description = "(Required) Datacenter to configure Consul as."
}


variable "consul_recursors" {
  description = "A list of addresses of upstream DNS servers that are used to recursively resolve DNS queries."
  type        = list(string)
  default     = []
}

#################################################################################
# global.gossipEncryption
#################################################################################
variable "gossip_enable_auto_generate" {
  description = "Automatically generate a gossip encryption key and save it to a Kubernetes or Vault secret."
  default     = false
}

variable "gossip_encryption_key" {
  description = "32 Bytes Base64 Encoded Consul Gossip Encryption Key. Set to `null` to disable"
  default     = null
}


#################################################################################
# global.tls
#################################################################################
variable "tls_enabled" {
  description = "Enable TLS for the cluster"
  default     = true
}

variable "tls_server_additional_dns_sans" {
  description = "List of additional DNS names to set as Subject Alternative Names (SANs) in the server certificate. This is useful when you need to access the Consul server(s) externally, for example, if you're using the UI."
  default     = []
}

variable "tls_server_additional_ip_sans" {
  description = "List of additional IP addresses to set as Subject Alternative Names (SANs) in the server certificate. This is useful when you need to access Consul server(s) externally, for example, if you're using the UI."
  default     = []
}

variable "tls_verify" {
  description = <<EOF
If true, 'verify_outgoing', 'verify_server_hostname', and
'verify_incoming_rpc' will be set to true for Consul servers and clients.
Set this to false to incrementally roll out TLS on an existing Consul cluster.
Note: remember to switch it back to true once the rollout is complete.
Please see this guide for more details:
https://learn.hashicorp.com/consul/security-networking/certificates
EOF

  default = true
}

variable "tls_https_only" {
  description = "If true, Consul will disable the HTTP port on both clients and servers and only accept HTTPS connections."
  default     = true
}

variable "tls_enable_auto_encrypt" {
  description = "Enable auto encrypt. Uses the connect CA to distribute certificates to clients"
  default     = false
}

variable "tls_ca_cert" {
  description = "Self generated CA path for Consul Server TLS. Values should be PEM encoded"
  default     = ""
}

variable "tls_ca_cert_key" {
  description = "Self generated CA path for Consul Server TLS. Values should be PEM encoded"
  default     = ""
}


variable "tls_server_cert" {
  description = "Server certificate path for Consul Server TLS. Values should be PEM encoded"
  default     = ""
}

variable "tls_server_cert_key" {
  description = "Server certificate path for Consul Server TLS. Values should be PEM encoded"
  default     = ""
}

#################################################################################
# global.acl
#################################################################################
variable "manage_system_acls" {
  description = "Manager ACL Tokens for Consul and consul-k8s components"
  type        = bool
  default     = false
}

variable "acl_bootstrap_token" {
  description = "Use an existing bootstrap token and the consul-k8s will not bootstrap anything"
  type = object({
    secret_name = string
    secret_key  = string
  })
  default = {
    secret_name = null
    secret_key  = null
  }
}

variable "create_replication_token" {
  description = "If true, an ACL token will be created that can be used in secondary datacenters for replication. This should only be set to true in the primary datacenter since the replication token must be created from that datacenter. In secondary datacenters, the secret needs to be imported from the primary datacenter"
  type        = bool
  default     = false
}

variable "replication_token" {
  description = "A secret containing the replication ACL token."
  type = object({
    secret_name = string
    secret_key  = string
  })
  default = {
    secret_name = null
    secret_key  = null
  }
}

variable "acl_tolerations" {
  description = " tolerations configures the taints and tolerations for the server-acl-init"
  default     = ""
}

#################################################################################
# global.metrics
#################################################################################
variable "metrics_enabled" {
  description = "Configures the Helm chart’s components to expose Prometheus metrics for the Consul service mesh."
  default     = false
}

variable "enable_agent_metrics" {
  description = "Configures consul agent metrics."
  default     = false
}

variable "agent_metrics_retention_time" {
  description = "Configures the retention time for metrics in Consul clients and servers. This must be greater than 0 for Consul clients and servers to expose any metrics at all."
  default     = "1m"
}

variable "enable_gateway_metrics" {
  description = "If true, mesh, terminating, and ingress gateways will expose their Envoy metrics on port `20200` at the `/metrics` path and all gateway pods will have Prometheus scrape annotations."
  default     = true
}

#################################################################################
# server
#################################################################################
variable "server_replicas" {
  description = "Number of server replicas to run"
  default     = 1
}

variable "server_storage" {
  description = "This defines the disk size for configuring the servers' StatefulSet storage. For dynamically provisioned storage classes, this is the desired size. For manually defined persistent volumes, this should be set to the disk size of the attached volume."
  default     = "10Gi"
}

variable "server_storage_class" {
  description = "The StorageClass to use for the servers' StatefulSet storage. It must be able to be dynamically provisioned if you want the storage to be automatically created. For example, to use Local storage classes, the PersistentVolumeClaims would need to be manually created. An empty value will use the Kubernetes cluster's default StorageClass."
  default     = ""
}

variable "server_resources" {
  description = "Resources for server"
  default = {
    requests = {
      cpu    = "100m"
      memory = "100Mi"
    }

    limits = {
      cpu    = "100m"
      memory = "100Mi"
    }
  }
}

variable "server_update_partition" {
  description = "This value is used to carefully control a rolling update of Consul server agents. This value specifies the partition (https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/#partitions) for performing a rolling update. Please read the linked Kubernetes documentation and https://www.consul.io/docs/k8s/upgrade#upgrading-consul-servers for more information."
  default     = 0
}

variable "server_security_context" {
  description = "Security context for server pods"
  default = {
    runAsNonRoot = true
    runAsGroup   = 1000
    runAsUser    = 100
    fsGroup      = 1000
  }
}

variable "server_extra_config" {
  description = "Additional configuration to include for servers in JSON/HCL"
  default     = {}
}

variable "server_extra_volumes" {
  description = "List of map of extra volumes specification for server pods. See https://www.consul.io/docs/platform/k8s/helm.html#v-server-extravolumes for the keys"
  default     = []
}

variable "server_affinity" {
  description = "A YAML string that can be templated via helm specifying the affinity for server pods"

  default = <<EOF
podAntiAffinity:
  requiredDuringSchedulingIgnoredDuringExecution:
    - labelSelector:
        matchLabels:
          app: {{ template "consul.name" . }}
          release: "{{ .Release.Name }}"
          component: server
      topologyKey: kubernetes.io/hostname
EOF

}

variable "server_tolerations" {
  description = "A YAML string that can be templated via helm specifying the tolerations for server pods"
  default     = ""
}

variable "server_topology_spread_constraints" {
  description = "YAML string for topology spread constraints for server pods"
  type        = string
  default     = ""
}

variable "client_affinity" {
  description = "affinity Settings for Client pods, formatted as a multi-line YAML string."
  default     = null
}

variable "server_priority_class" {
  description = "Priority class for servers"
  default     = ""
}

variable "server_annotations" {
  description = "A YAML string for server pods"
  default     = ""
}

variable "server_service_account_annotations" {
  description = "YAML string for annotations for server service account"
  type        = string
  default     = ""
}

variable "server_connect_enable" {
  description = "Enable consul connect. When enabled, the bootstrap will configure a default CA which can be tweaked using the Consul API later"
  default     = true
}

#################################################################################
# client
#################################################################################
variable "client_enable" {
  description = "Enable consul client"
  default     = false
}

variable "client_grpc" {
  description = "Enable GRPC port for clients. Required for Connect Inject"
  default     = true
}

variable "client_resources" {
  description = "Resources for clients"
  default = {
    requests = {
      cpu    = "100m"
      memory = "100Mi"
    }

    limits = {
      cpu    = "100m"
      memory = "100Mi"
    }
  }
}

variable "client_extra_config" {
  description = "Additional configuration to include for client agents"
  default     = {}
}

variable "client_security_context" {
  description = "Pod security context for client pods"
  default = {
    runAsNonRoot = true
    runAsGroup   = 1000
    runAsUser    = 100
    fsGroup      = 1000
  }
}

variable "client_extra_volumes" {
  description = "List of map of extra volumes specification. See https://www.consul.io/docs/platform/k8s/helm.html#v-client-extravolumes for the keys"
  default     = []
}

variable "client_tolerations" {
  description = "A YAML string that can be templated via helm specifying the tolerations for client pods"
  default     = ""
}

variable "client_annotations" {
  description = "A YAML string for client pods"
  default     = ""
}

variable "client_labels" {
  description = "Additional labels for client pods"
  default     = {}
}

variable "client_service_account_annotations" {
  description = "YAML string for annotations for client service account"
  type        = string
  default     = ""
}

variable "client_priority_class" {
  description = "Priority class for clients"
  default     = ""
}

#################################################################################
# sync
#################################################################################
variable "enable_sync_catalog" {
  description = "Enable Service catalog sync: https://www.consul.io/docs/platform/k8s/service-sync.html"
  default     = false
}

variable "sync_by_default" {
  description = "If true, all valid services in K8S are synced by default. If false, the service must be annotated properly to sync. In either case an annotation can override the default."
  default     = true
}

variable "sync_to_consul" {
  description = "If true, will sync Kubernetes services to Consul. This can be disabled to have a one-way sync."
  default     = true
}

variable "sync_to_k8s" {
  description = " If true, will sync Consul services to Kubernetes. This can be disabled to have a one-way sync."
  default     = true
}

variable "sync_k8s_prefix" {
  description = " A prefix to prepend to all services registered in Kubernetes from Consul. This defaults to '' where no prefix is prepended; Consul services are synced with the same name to Kubernetes. (Consul -> Kubernetes sync only)"
  default     = ""
}

variable "sync_k8s_tag" {
  description = "An optional tag that is applied to all of the Kubernetes services that are synced into Consul. If nothing is set, this defaults to 'k8s'. (Kubernetes -> Consul sync only)"
  default     = "k8s"
}

variable "sync_cluster_ip_services" {
  description = "If true, will sync Kubernetes ClusterIP services to Consul. This can be disabled to have the sync ignore ClusterIP-type services."
  default     = true
}

variable "sync_node_port_type" {
  description = "Configures the type of syncing that happens for NodePort services. The only valid options are: ExternalOnly, InternalOnly, and ExternalFirst. ExternalOnly will only use a node's ExternalIP address for the sync, otherwise the service will not be synced. InternalOnly uses the node's InternalIP address. ExternalFirst will preferentially use the node's ExternalIP address, but if it doesn't exist, it will use the node's InternalIP address instead."
  default     = "ExternalFirst"
}

variable "sync_add_k8s_namespace_suffix" {
  description = "Appends Kubernetes namespace suffix to each service name synced to Consul, separated by a dash."
  default     = true
}

variable "sync_affinity" {
  description = "YAML template string for Sync Catalog affinity"
  default     = ""
}

variable "sync_resources" {
  description = "Sync Catalog resources"
  default = {
    requests = {
      cpu    = "50m"
      memory = "50Mi"
    }
    limits = {
      cpu    = "50m"
      memory = "50Mi"
    }
  }
}

variable "sync_tolerations" {
  description = "Template string for Sync Catalog Tolerations"
  default     = ""
}

variable "sync_service_account_annotations" {
  description = "YAML string for annotations for sync catalog service account"
  type        = string
  default     = ""
}

variable "sync_priority_class" {
  description = "Priority Class Name for Consul Sync Catalog"
  default     = ""
}

variable "sync_acl_token" {
  description = "Secret containing ACL token if ACL is enabled and manage_system_acls is not enabled"
  type = object({
    secret_name = string
    secret_key  = string
  })
  default = {
    secret_name = null
    secret_key  = null
  }
}

#################################################################################
# ui
#################################################################################
variable "ui_service_type" {
  description = "Type of service for Consul UI"
  default     = "ClusterIP"
}

variable "ui_annotations" {
  description = "UI service annotations"
  default     = null
}

variable "ui_additional_spec" {
  description = "Additional Spec for the UI service"
  default     = null
}

variable "ui_metrics_provider" {
  description = "Provider for metrics. See https://www.consul.io/docs/agent/options#ui_config_metrics_provider"
  default     = "prometheus"
}

variable "ui_metrics_base_url" {
  description = "URL of the prometheus server, usually the service URL."
  default     = "http://prometheus-server"
}

#################################################################################
# connectInject
#################################################################################
variable "enable_connect_inject" {
  description = "Enable Connect Injector process"
  default     = true
}

variable "connect_inject_replicas" {
  description = "Number of replicas for Connect Inject deployment"
  type        = number
  default     = 1
}

variable "connect_inject_by_default" {
  description = "If true, the injector will inject the Connect sidecar into all pods by default. Otherwise, pods must specify the injection annotation to opt-in to Connect injection. If this is true, pods can use the same annotation to explicitly opt-out of injection."
  default     = false
}

variable "connect_inject_namespace_selector" {
  description = "A YAML string selector for restricting injection to only matching namespaces. By default all namespaces except the system namespace will have injection enabled."
  default     = <<-EOF
    matchExpressions:
      - key: "kubernetes.io/metadata.name"
        operator: "NotIn"
        values: ["kube-system","local-path-storage"]
    EOF
}

variable "connect_inject_allowed_namespaces" {
  description = "List of allowed namespaces to inject. "
  default     = ["*"]
}

variable "connect_inject_denied_namespaces" {
  description = "List of denied namespaces to inject. "
  default     = []
}

variable "connect_inject_affinity" {
  description = "Template string for Connect Inject Affinity"
  default     = ""
}

variable "connect_inject_tolerations" {
  description = "Template string for Connect Inject Tolerations"
  default     = ""
}

variable "connect_inject_resources" {
  description = "Resources for connect inject pod"
  default = {
    requests = {
      cpu    = "50m"
      memory = "50Mi"
    }
    limits = {
      cpu    = "100m"
      memory = "100Mi"
    }
  }
}

variable "connect_inject_priority_class" {
  description = "Pod Priority Class for Connect Inject"
  default     = ""
}

variable "connect_inject_log_level" {
  description = "Log verbosity level. One of debug, info, warn, or error."
  default     = ""
}

variable "connect_inject_failure_policy" {
  description = <<-EOF
  Sets the failurePolicy for the mutating webhook. By default this will cause pods not part of the consul installation to fail scheduling while the webhook
  is offline. This prevents a pod from skipping mutation if the webhook were to be momentarily offline.
  Once the webhook is back online the pod will be scheduled.
  In some environments such as Kind this may have an undesirable effect as it may prevent volume provisioner pods from running
  which can lead to hangs. In these environments it is recommend to use "Ignore" instead.
  This setting can be safely disabled by setting to "Ignore".
  EOF

  type    = string
  default = "Fail"
}

variable "connect_inject_sidecar_proxy_resources" {
  description = "Set default resources for sidecar proxy. If null, that resource won't be set."
  default = {
    requests = {
      cpu    = "100m"
      memory = "100Mi"
    }
    limits = {
      cpu    = "100m"
      memory = "100Mi"
    }
  }
}

variable "connect_inject_init_resources" {
  description = "Resource settings for the Connect injected init container."
  default = {
    requests = {
      cpu    = "50m"
      memory = "25Mi"
    }
    limits = {
      cpu    = "50m"
      memory = "150Mi"
    }
  }
}

variable "envoy_extra_args" {
  description = "Pass arguments to the injected envoy sidecar. Valid arguments to pass to envoy can be found here: https://www.envoyproxy.io/docs/envoy/latest/operations/cli"
  default     = ""
}

variable "connect_inject_acl_binding_rule_selector" {
  description = <<-EOF
    Query that defines which Service Accounts
    can authenticate to Consul and receive an ACL token during Connect injection.
    The default setting, i.e. serviceaccount.name!=default, prevents the
    'default' Service Account from logging in.
    If set to an empty string all service accounts can log in.
    This only has effect if ACLs are enabled.

    See https://www.consul.io/docs/acl/acl-auth-methods.html#binding-rules
    and https://www.consul.io/docs/acl/auth-methods/kubernetes.html#trusted-identity-attributes
    for more details.
    EOF
  type        = string
  default     = "serviceaccount.name!=default"
}

variable "connect_inject_override_auth_method_name" {
  description = "If you are not using global.acls.manageSystemACLs and instead manually setting up an auth method for Connect inject, set this to the name of your auth method."
  type        = string
  default     = ""
}

variable "connect_inject_default_enable_merging" {
  description = "Configures the Consul sidecar to run a merged metrics server to combine and serve both Envoy and Connect service metrics. This feature is available only in Consul v1.10-alpha or greater."
  default     = false
}

variable "connect_inject_default_merged_metrics_port" {
  description = "Configures the port at which the Consul sidecar will listen on to return combined metrics. This port only needs to be changed if it conflicts with the application's ports."
  default     = 20100
}

variable "connect_inject_default_prometheus_scrape_port" {
  description = <<-EOF
    Configures the port Prometheus will scrape metrics from, by configuring
    the Pod annotation `prometheus.io/port` and the corresponding listener in
    the Envoy sidecar.
    NOTE: This is *not* the port that your application exposes metrics on.
    That can be configured with the
    `consul.hashicorp.com/service-metrics-port` annotation.
    EOF
  default     = 20200
}

variable "connect_inject_default_prometheus_scrape_path" {
  description = <<-EOF
    Configures the path Prometheus will scrape metrics from, by configuring the pod
    annotation `prometheus.io/path` and the corresponding handler in the Envoy
    sidecar.
    NOTE: This is *not* the path that your application exposes metrics on.
    That can be configured with the
    `consul.hashicorp.com/service-metrics-path` annotation.
    EOF
  default     = "/metrics"
}

variable "connect_inject_service_account_annotations" {
  description = "YAML string with annotations for the Connect Inject service account"
  type        = string
  default     = ""
}


#################################################################################
# connectInject.transparentProxy
################################################################################# 
variable "transparent_proxy_default_enabled" {
  description = "Enable transparent proxy by default on all connect injected pods"
  type        = bool
  default     = true
}

variable "transparent_proxy_default_overwrite_probes" {
  description = "Overwrite HTTP probes by default when transparent proxy is in use"
  type        = bool
  default     = true
}
 
#################################################################################
# ingressGateways
#################################################################################
variable "ingress_gateway_enable" {
  description = "Deploy Ingress Gateways. Requires `connectInject.enabled=true` and `client.enabled=true`."
  type        = bool
  default     = false
}

#################################################################################
# terminatingGateways
#################################################################################
variable "terminating_gateway_enable" {
  description = "Deploy Terminating Gateways"
  type        = bool
  default     = false
}
 
#################################################################################
# Etc
#################################################################################
variable "secret_name" {
  description = "Name of the secret for Consul"
  default     = "consul"
}

variable "secret_annotation" {
  description = "Annotations for the Consul Secret"
  default     = {}
}

variable "enable_prometheus" {
  description = "When true, the Helm chart will install Prometheus server instance alongside Consul."
  default     = false
}

variable "enable_grafana" {
  description = "When true, the Helm chart will install Grtafana server instance alongside Consul."
  default     = false
}

