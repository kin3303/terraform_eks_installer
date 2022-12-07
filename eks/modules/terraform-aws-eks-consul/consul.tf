###########################################################################
# Consul on Terraform 
#     Consul Helm Chart
#         https://github.com/hashicorp/consul-k8s
#         https://developer.hashicorp.com/consul/docs/k8s/helm
#
#     Consul Install
#         https://developer.hashicorp.com/consul/docs/k8s/installation/install  
#
#     Tutorials
#        https://developer.hashicorp.com/consul/tutorials/get-started-kubernetes
#        https://github.com/hashicorp/learn-consul-kubernetes/tree/main/service-mesh/deploy
#        https://developer.hashicorp.com/consul/tutorials/kubernetes-features/service-mesh-observability
#        https://github.com/hashicorp/learn-consul-kubernetes.git
#
#     Use Cases
#        https://developer.hashicorp.com/consul/tutorials/kubernetes
#  
#     Web Search
#         https://istio.io/latest/docs/examples/bookinfo/
#         https://www.linkedin.com/pulse/how-easily-setup-consul-service-mesh-aws-eks-ihar-vauchok 
###########################################################################
resource "helm_release" "consul" {
  name              = var.release_name
  chart             = var.chart_name
  repository        = var.chart_repository
  version           = var.chart_version
  namespace         = var.create_namespace == true ? kubernetes_namespace.consul[0].metadata[0].name : var.chart_namespace
  create_namespace  = false
  max_history       = var.max_history
  timeout           = var.chart_timeout
  cleanup_on_fail   = true
  dependency_update = true

  values = concat([local.chart_values], var.additional_chart_values)
}

locals {
  chart_values = templatefile("${path.module}/templates/values.yaml", local.consul_values)

  consul_values = {
    ###########################################################################
    # global
    ###########################################################################
    log_json_enable            = var.log_json_enable
    name                       = var.name != null ? var.name : "null"
    consul_domain              = var.consul_domain
    consul_datacenter          = var.consul_datacenter
    pod_security_policy_enable = var.pod_security_policy_enable
    consul_recursors           = jsonencode(var.consul_recursors)

    # global.gossipEncryption
    gossip_enable_auto_generate = var.gossip_enable_auto_generate
    gossip_secret               = var.gossip_encryption_secret_name != "" ?  var.gossip_encryption_secret_name : (var.gossip_encryption_key != null ? kubernetes_secret.gossip[0].metadata[0].name : "")
    gossip_key                  = var.gossip_encryption_secret_key != "" ? var.gossip_encryption_secret_key : (var.gossip_encryption_key != null ? "gossip" : "")

    # global.tls
    tls_enabled                    = var.tls_enabled
    tls_server_additional_dns_sans = jsonencode(var.tls_server_additional_dns_sans)
    tls_server_additional_ip_sans  = jsonencode(var.tls_server_additional_ip_sans)
    tls_verify                     = var.tls_verify
    tls_https_only                 = var.tls_https_only
    tls_enable_auto_encrypt        = jsonencode(var.tls_enable_auto_encrypt)
    tls_cacert_secret_name         = var.tls_cacert_secret_name != "" ? var.tls_cacert_secret_name : (var.tls_ca_cert != "" && var.tls_ca_cert_key != "" ? kubernetes_secret.ca_certificate[0].metadata[0].name : "null")
    tls_cacert_secret_key          = var.tls_cacert_secret_key != "" ? var.tls_cacert_secret_key : (var.tls_ca_cert != "" && var.tls_ca_cert_key != "" ? "tls.crt" : "null") 
    tls_cakey_secret_name          = var.tls_ca_cert != "" && var.tls_ca_cert_key != "" ? kubernetes_secret.ca_certificate[0].metadata[0].name : "null"
    tls_cakey_secret_key           = var.tls_ca_cert != "" && var.tls_ca_cert_key != "" ? "tls.key" : "null"
    tls_server_cert_secret         = var.tls_server_cert_secret_name != "" ? var.tls_server_cert_secret_name : (var.tls_server_cert != "" && var.tls_server_cert_key != "" ? kubernetes_secret.server_certificate[0].metadata[0].name : "null")

    # global.acl
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
    acl_tolerations = jsonencode(var.acl_tolerations)

    # global.metrics
    metrics_enabled              = var.metrics_enabled
    enable_agent_metrics         = var.enable_agent_metrics
    agent_metrics_retention_time = var.agent_metrics_retention_time
    enable_gateway_metrics       = var.enable_gateway_metrics

    # global.federation
    federation_enable        = var.federation_enable
    create_federation_secret = var.create_federation_secret

    ###########################################################################
    # server
    ###########################################################################
    server_replicas                    = var.server_replicas
    server_storage                     = var.server_storage
    server_storage_class               = var.server_storage_class # kubernetes_storage_class_v1.efs_sc.metadata[0].name
    server_resources                   = yamlencode(var.server_resources)
    server_connect_enable              = var.server_connect_enable
    server_extra_config                = jsonencode(jsonencode(var.server_extra_config))
    server_extra_volumes               = jsonencode(var.server_extra_volumes)
    server_affinity                    = jsonencode(var.server_affinity)
    server_tolerations                 = jsonencode(var.server_tolerations)
    server_priority_class              = var.server_priority_class
    server_annotations                 = jsonencode(var.server_annotations)
    server_service_account_annotations = jsonencode(var.server_service_account_annotations)
    server_topology_spread_constraints = jsonencode(var.server_topology_spread_constraints)
    server_update_partition            = var.server_update_partition
    server_security_context            = jsonencode(var.server_security_context)
    server_expose_gossip_and_rpc_ports = var.server_expose_gossip_and_rpc_ports

    ###########################################################################
    # client
    ###########################################################################
    client_enable                      = var.client_enable
    client_grpc                        = var.client_grpc
    client_resources                   = yamlencode(var.client_resources)
    client_extra_config                = jsonencode(jsonencode(var.client_extra_config))
    client_extra_volumes               = jsonencode(var.client_extra_volumes)
    client_affinity                    = var.client_affinity != null ? jsonencode(var.client_affinity) : "null"
    client_tolerations                 = jsonencode(var.client_tolerations)
    client_priority_class              = var.client_priority_class
    client_annotations                 = jsonencode(var.client_annotations)
    client_labels                      = jsonencode(var.client_labels)
    client_service_account_annotations = jsonencode(var.client_service_account_annotations)
    client_security_context            = jsonencode(var.client_security_context)

    ###########################################################################
    # sync
    ###########################################################################
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

    ###########################################################################
    # ui
    ###########################################################################
    ui_service_type     = var.ui_service_type
    ui_annotations      = jsonencode(var.ui_annotations)
    ui_additional_spec  = jsonencode(var.ui_additional_spec)
    ui_metrics_provider = var.ui_metrics_provider
    ui_metrics_base_url = var.ui_metrics_base_url

    ###########################################################################
    # connectInject
    ###########################################################################
    enable_connect_inject                         = var.enable_connect_inject
    connect_inject_replicas                       = var.connect_inject_replicas
    connect_inject_by_default                     = var.connect_inject_by_default
    connect_inject_affinity                       = jsonencode(var.connect_inject_affinity)
    connect_inject_tolerations                    = jsonencode(var.connect_inject_tolerations)
    connect_inject_resources                      = jsonencode(var.connect_inject_resources)
    connect_inject_priority_class                 = var.connect_inject_priority_class
    connect_inject_namespace_selector             = var.connect_inject_namespace_selector != null ? jsonencode(var.connect_inject_namespace_selector) : "null"
    connect_inject_allowed_namespaces             = jsonencode(var.connect_inject_allowed_namespaces)
    connect_inject_denied_namespaces              = jsonencode(var.connect_inject_denied_namespaces)
    connect_inject_log_level                      = var.connect_inject_log_level
    connect_inject_failure_policy                 = var.connect_inject_failure_policy
    connect_inject_sidecar_proxy_resources        = yamlencode(var.connect_inject_sidecar_proxy_resources)
    connect_inject_init_resources                 = yamlencode(var.connect_inject_init_resources)
    envoy_extra_args                              = var.envoy_extra_args != null ? jsonencode(var.envoy_extra_args) : "null"
    connect_inject_acl_binding_rule_selector      = var.connect_inject_acl_binding_rule_selector
    connect_inject_override_auth_method_name      = jsonencode(var.connect_inject_override_auth_method_name)
    transparent_proxy_default_enabled             = var.transparent_proxy_default_enabled
    transparent_proxy_default_overwrite_probes    = var.transparent_proxy_default_overwrite_probes
    connect_inject_default_enable_merging         = var.connect_inject_default_enable_merging
    connect_inject_default_merged_metrics_port    = var.connect_inject_default_merged_metrics_port
    connect_inject_default_prometheus_scrape_port = var.connect_inject_default_prometheus_scrape_port
    connect_inject_default_prometheus_scrape_path = var.connect_inject_default_prometheus_scrape_path
    connect_inject_service_account_annotations    = jsonencode(var.connect_inject_service_account_annotations)

    ###########################################################################
    # ingressGateways
    ###########################################################################
    ingress_gateway_enable = var.ingress_gateway_enable
    ingress_gateways       = yamlencode(var.ingress_gateways)

    ###########################################################################
    # terminatingGateway
    ###########################################################################
    terminating_gateway_enable = var.terminating_gateway_enable
    terminating_gateways       = yamlencode(var.terminating_gateways)

    ###########################################################################
    # Vault Secret Backend
    ###########################################################################
    enable_secret_backend_vault   = var.enable_secret_backend_vault
    vault_ca_additional_config    = var.vault_ca_additional_config
    vault_consul_server_role      = var.vault_consul_server_role
    vault_consul_client_role      = var.vault_consul_client_role
    vault_consul_ca_role          = var.vault_consul_ca_role
    vault_addr                    = var.vault_addr
    vault_root_pki_path           = var.vault_root_pki_path
    vault_intermediate_pki_path   = var.vault_intermediate_pki_path
    vault_consul_agent_annotation = var.vault_consul_agent_annotation

  }
}

resource "kubernetes_namespace" "consul" {
  count = var.create_namespace == true ? 1 : 0
  metadata {
    name = var.chart_namespace
  }
}

resource "kubernetes_secret" "gossip" {
  count = var.gossip_encryption_key != null ? 1 : 0

  metadata {
    name        = "${var.secret_name}-gossip-key"
    annotations = var.secret_annotation
    namespace   = var.create_namespace == true ? kubernetes_namespace.consul[0].metadata[0].name : var.chart_namespace
  }

  type = "Opaque"

  data = {
    gossip = var.gossip_encryption_key
  }
}

resource "kubernetes_secret" "ca_certificate" {
  count = var.tls_ca_cert != "" && var.tls_ca_cert_key != "" ? 1 : 0

  metadata {
    name        = "${var.secret_name}-server-certificate"
    annotations = var.secret_annotation
    namespace   = var.create_namespace == true ? kubernetes_namespace.consul[0].metadata[0].name : var.chart_namespace
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
    namespace   = var.create_namespace == true ? kubernetes_namespace.consul[0].metadata[0].name : var.chart_namespace
  }

  type = "Opaque"

  data = {
    "tls.crt" = file(var.tls_server_cert)
    "tls.key" = file(var.tls_server_cert_key)
  }
}
