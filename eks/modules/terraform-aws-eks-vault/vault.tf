resource "helm_release" "vault" {
  name             = var.release_name
  chart            = var.chart_name
  repository       = var.chart_repository
  version          = var.chart_version
  namespace        = var.create_namespace == true ? kubernetes_namespace.vault[0].metadata[0].name : var.chart_namespace
  create_namespace = false
  max_history      = var.max_history
  timeout          = var.chart_timeout
  cleanup_on_fail   = true
  dependency_update = true

  values = concat([local.chart_values], var.additional_chart_values)
}

locals {
  chart_values = templatefile("${path.module}/templates/values.yaml", local.vault_values)
  vault_values = {}
}

resource "kubernetes_namespace" "vault" {
  count = var.create_namespace == true ? 1 : 0
  metadata {
    name = var.chart_namespace
  }
}

resource "kubernetes_secret" "ca_certificate" {
  count = var.tls_ca_cert != "" && var.tls_ca_cert_key != "" ? 1 : 0

  metadata {
    name        = "${var.secret_name}-server-certificate"
    annotations = var.secret_annotation
    namespace   = var.create_namespace == true ? kubernetes_namespace.vault[0].metadata[0].name : var.chart_namespace
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
    namespace   = var.create_namespace == true ? kubernetes_namespace.vault[0].metadata[0].name : var.chart_namespace
  }

  type = "Opaque"

  data = {
    "tls.crt" = file(var.tls_server_cert)
    "tls.key" = file(var.tls_server_cert_key)
  }
}
