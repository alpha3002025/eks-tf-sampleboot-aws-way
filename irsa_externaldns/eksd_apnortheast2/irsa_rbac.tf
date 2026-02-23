
# 3. ExternalDNS RBAC (ClusterRole)
resource "kubernetes_cluster_role" "external_dns_sampleboot" {
  metadata {
    name = "external-dns-sampleboot"
  }

  rule {
    api_groups = [""]
    resources  = ["services", "endpoints", "pods"]
    verbs      = ["get", "watch", "list"]
  }

  rule {
    api_groups = ["extensions", "networking.k8s.io"]
    resources  = ["ingresses"]
    verbs      = ["get", "watch", "list"]
  }

  rule {
    api_groups = [""]
    resources  = ["nodes"]
    verbs      = ["list", "watch"]
  }
}

# 4. ExternalDNS RBAC (ClusterRoleBinding)
resource "kubernetes_cluster_role_binding" "external_dns_viewer_sampleboot" {
  metadata {
    name = "external-dns-viewer-sampleboot"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.external_dns_sampleboot.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.external_dns_sampleboot.metadata[0].name
    namespace = kubernetes_service_account.external_dns_sampleboot.metadata[0].namespace
  }
}
