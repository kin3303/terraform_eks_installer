###########################################################################
# Consul Install
#     https://github.com/hashicorp/consul-k8s
#     https://developer.hashicorp.com/consul/docs/k8s/installation/install
#     https://developer.hashicorp.com/consul/tutorials/kubernetes/kubernetes-reference-architecture
#     https://developer.hashicorp.com/consul/docs/k8s/helm#h-global
#
#     https://registry.terraform.io/modules/basisai/consul/kubernetes/latest
#     https://www.linkedin.com/pulse/how-easily-setup-consul-service-mesh-aws-eks-ihar-vauchok
###########################################################################
resource "helm_release" "consul" {
  name       = var.release_name
  chart      = var.chart_name
  repository = var.chart_repository
  version    = var.chart_version
  namespace  = var.chart_namespace

  max_history = var.max_history
  timeout     = var.chart_timeout

  values = concat([local.chart_values], var.additional_chart_values)
}

resource "null_resource" "consul_values" {
  count    = var.consul_raw_values ? 1 : 0
  triggers = local.consul_values
}


locals {
  chart_values = templatefile("${path.module}/templates/values.yaml", local.consul_values)

  consul_values = {
    name      = var.name != null ? jsonencode(var.name) : "null"
    image     = "${var.consul_image_name}:${var.consul_image_tag}"
    image_k8s = "${var.consul_k8s_image}:${var.consul_k8s_tag}"

    pod_security_policy_enable = var.pod_security_policy_enable
    log_json_enable            = var.log_json_enable

    gossip_enable_auto_generate = var.gossip_enable_auto_generate
    gossip_secret               = var.gossip_encryption_key != null ? kubernetes_secret.gossip[0].metadata[0].name : "null"
    gossip_key                  = var.gossip_encryption_key != null ? "gossip" : "null"

    datacenter = var.server_datacenter

    consul_domain                      = var.consul_domain
    server_replicas                    = var.server_replicas
    server_storage                     = var.server_storage
    server_storage_class               = var.server_storage_class # kubernetes_storage_class_v1.efs_sc.metadata[0].name
    server_resources                   = yamlencode(var.server_resources)
    server_extra_config                = jsonencode(jsonencode(var.server_extra_config))
    server_extra_volumes               = jsonencode(var.server_extra_volumes)
    server_affinity                    = jsonencode(var.server_affinity)
    server_tolerations                 = jsonencode(var.server_tolerations)
    server_priority_class              = var.server_priority_class
    server_annotations                 = jsonencode(var.server_annotations)
    consul_recursors                   = jsonencode(var.consul_recursors)
    server_service_account_annotations = jsonencode(var.server_service_account_annotations)
    server_topology_spread_constraints = jsonencode(var.server_topology_spread_constraints)
    server_update_partition            = var.server_update_partition

    manage_system_acls = var.manage_system_acls
    acl_bootstrap_token = yamlencode({
      secretName = var.acl_bootstrap_token.secret_name
      secretKey  = var.acl_bootstrap_token.secret_key
    })
    create_replication_token = var.create_replication_token
    replication_token = yamlencode({
      secretName = var.replication_token.secret_name
      secretKey  = var.replication_token.secret_key
    })
    acl_tolerations = var.acl_tolerations

    client_grpc           = var.client_grpc
    client_resources      = yamlencode(var.client_resources)
    client_extra_config   = jsonencode(jsonencode(var.client_extra_config))
    client_extra_volumes  = jsonencode(var.client_extra_volumes)
    client_affinity       = var.client_affinity != null ? jsonencode(var.client_affinity) : "null"
    client_tolerations    = jsonencode(var.client_tolerations)
    client_priority_class = var.client_priority_class
    client_annotations    = jsonencode(var.client_annotations)
    client_labels         = jsonencode(var.client_labels)

    client_service_account_annotations = jsonencode(var.client_service_account_annotations)

    server_security_context = jsonencode(var.server_security_context)
    client_security_context = jsonencode(var.client_security_context)

    tls_enabled                    = var.tls_enabled
    tls_server_additional_dns_sans = jsonencode(var.tls_server_additional_dns_sans)
    tls_server_additional_ip_sans  = jsonencode(var.tls_server_additional_ip_sans)
    tls_verify                     = var.tls_verify
    tls_https_only                 = var.tls_https_only
    tls_enable_auto_encrypt        = jsonencode(var.tls_enable_auto_encrypt)

    tls_cacert_secret_name = var.tls_ca_cert != null && var.tls_ca_cert_key != null ? kubernetes_secret.ca_certificate[0].metadata[0].name : "null"
    tls_cacert_secret_key  = var.tls_ca_cert != null && var.tls_ca_cert_key != null ? "tls.crt" : "null"
    tls_cakey_secret_name  = var.tls_ca_cert != null && var.tls_ca_cert_key != null ? kubernetes_secret.ca_certificate[0].metadata[0].name : "null"
    tls_cakey_secret_key   = var.tls_ca_cert != null && var.tls_ca_cert_key != null ? "tls.key" : "null"

    tls_server_cert_secret = var.tls_server_cert != null && var.tls_server_cert_key != null ? kubernetes_secret.server_certificate[0].metadata[0].name : "null"

    enable_sync_catalog           = jsonencode(var.enable_sync_catalog)
    sync_by_default               = var.sync_by_default
    sync_to_consul                = var.sync_to_consul
    sync_to_k8s                   = var.sync_to_k8s
    sync_k8s_prefix               = var.sync_k8s_prefix
    sync_k8s_tag                  = var.sync_k8s_tag
    sync_cluster_ip_services      = var.sync_cluster_ip_services
    sync_node_port_type           = var.sync_node_port_type
    sync_add_k8s_namespace_suffix = var.sync_add_k8s_namespace_suffix
    sync_affinity                 = jsonencode(var.sync_affinity)
    sync_tolerations              = jsonencode(var.sync_tolerations)
    sync_resources                = yamlencode(var.sync_resources)
    sync_priority_class           = var.sync_priority_class
    sync_acl_token = yamlencode({
      secretName = var.sync_acl_token.secret_name
      secretKey  = var.sync_acl_token.secret_key
    })


    sync_service_account_annotations = jsonencode(var.sync_service_account_annotations)

    ui_service_type    = var.ui_service_type
    ui_annotations     = jsonencode(var.ui_annotations)
    ui_additional_spec = jsonencode(var.ui_additional_spec)

    connect_enable                = jsonencode(var.connect_enable)
    enable_connect_inject         = var.enable_connect_inject
    connect_inject_replicas       = var.connect_inject_replicas
    connect_inject_by_default     = var.connect_inject_by_default
    connect_inject_affinity       = jsonencode(var.connect_inject_affinity)
    connect_inject_tolerations    = jsonencode(var.connect_inject_tolerations)
    connect_inject_resources      = jsonencode(var.connect_inject_resources)
    connect_inject_priority_class = var.connect_inject_priority_class

    connect_inject_namespace_selector = var.connect_inject_namespace_selector != null ? jsonencode(var.connect_inject_namespace_selector) : "null"
    connect_inject_allowed_namespaces = jsonencode(var.connect_inject_allowed_namespaces)
    connect_inject_denied_namespaces  = jsonencode(var.connect_inject_denied_namespaces)
    connect_inject_log_level          = var.connect_inject_log_level
    connect_inject_failure_policy     = var.connect_inject_failure_policy

    connect_inject_sidecar_proxy_resources = yamlencode(var.connect_inject_sidecar_proxy_resources)
    connect_inject_init_resources          = yamlencode(var.connect_inject_init_resources)
    consul_sidecar_container_resources     = yamlencode(var.consul_sidecar_container_resources)
    envoy_extra_args                       = var.envoy_extra_args != null ? jsonencode(var.envoy_extra_args) : "null"

    connect_inject_acl_binding_rule_selector = var.connect_inject_acl_binding_rule_selector
    connect_inject_override_auth_method_name = jsonencode(var.connect_inject_override_auth_method_name)

    controller_enable           = var.controller_enable
    controller_replicas         = var.controller_replicas
    controller_log_level        = var.controller_log_level
    controller_resources        = yamlencode(var.controller_resources)
    controller_node_selector    = var.controller_node_selector != null ? jsonencode(var.controller_node_selector) : "null"
    controller_node_tolerations = var.controller_node_tolerations != null ? jsonencode(var.controller_node_tolerations) : "null"
    controller_node_affinity    = var.controller_node_affinity != null ? jsonencode(var.controller_node_affinity) : "null"
    controller_priority_class   = var.controller_priority_class
    controller_acl_token = yamlencode({
      secretName = var.controller_acl_token.secret_name
      secretKey  = var.controller_acl_token.secret_key
    })

    controller_service_account_annotations = jsonencode(var.controller_service_account_annotations)

    transparent_proxy_default_enabled          = var.transparent_proxy_default_enabled
    transparent_proxy_default_overwrite_probes = var.transparent_proxy_default_overwrite_probes

    terminating_gateway_enable   = var.terminating_gateway_enable
    terminating_gateway_defaults = yamlencode(var.terminating_gateway_defaults)
    terminating_gateways         = yamlencode(var.terminating_gateways)

    metrics_enabled              = var.metrics_enabled
    enable_agent_metrics         = var.enable_agent_metrics
    agent_metrics_retention_time = var.agent_metrics_retention_time
    enable_gateway_metrics       = var.enable_gateway_metrics

    ui_metrics_provider = var.ui_metrics_provider
    ui_metrics_base_url = var.ui_metrics_base_url

    connect_inject_default_enable_merging         = var.connect_inject_default_enable_merging
    connect_inject_default_merged_metrics_port    = var.connect_inject_default_merged_metrics_port
    connect_inject_default_prometheus_scrape_port = var.connect_inject_default_prometheus_scrape_port
    connect_inject_default_prometheus_scrape_path = var.connect_inject_default_prometheus_scrape_path

    connect_inject_service_account_annotations = jsonencode(var.connect_inject_service_account_annotations)

    # Data Plane
    image_dataplane = "${var.consul_dataplane_name}:${var.consul_dataplane_tag}"
  }
}

resource "kubernetes_secret" "gossip" {
  count = var.gossip_encryption_key != null ? 1 : 0

  metadata {
    name        = "${var.secret_name}-gossip-key"
    annotations = var.secret_annotation
    namespace   = var.chart_namespace
  }

  type = "Opaque"

  data = {
    gossip = var.gossip_encryption_key
  }
}

resource "kubernetes_secret" "ca_certificate" {
  count = var.tls_ca_cert != null && var.tls_ca_cert_key != null ? 1 : 0

  metadata {
    name        = "${var.secret_name}-server-certificate"
    annotations = var.secret_annotation
    namespace   = var.chart_namespace
  }

  type = "Opaque"

  data = {
    "tls.crt" = file(var.tls_ca_cert)
    "tls.key" = file(var.tls_ca_cert_key)
  }
}


resource "kubernetes_secret" "server_certificate" {
  count = var.tls_server_cert != "" && var.tls_server_cert_key != "" ? 1 : 0
  metadata {
    name        = "${var.secret_name}-ca-certificate"
    annotations = var.secret_annotation
    namespace   = var.chart_namespace
  }

  type = "Opaque"

  data = {
    "tls.crt" =  file(var.tls_server_cert)
    "tls.key" = file(var.tls_server_cert_key)
  }
}

