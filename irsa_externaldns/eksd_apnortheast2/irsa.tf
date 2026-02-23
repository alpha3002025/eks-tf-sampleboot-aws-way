# 1. IAM Role (IRSA)
module "external_dns_irsa_sampleboot" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.52"

  role_name                     = "${var.cluster_name}-external-dns-sampleboot"
  attach_external_dns_policy    = true
  external_dns_hosted_zone_arns = ["arn:aws:route53:::hostedzone/Z01434532HN0SX4VDYLJG"]

  oidc_providers = {
    main = {
      provider_arn               = data.aws_iam_openid_connect_provider.oidc.arn
      namespace_service_accounts = ["kube-system:external-dns-sampleboot"]
    }
  }
}

# 2. Kubernetes ServiceAccount
resource "kubernetes_service_account" "external_dns_sampleboot" {
  metadata {
    name      = "external-dns-sampleboot"
    namespace = "kube-system"
    annotations = {
      "eks.amazonaws.com/role-arn" = module.external_dns_irsa_sampleboot.iam_role_arn
    }
  }
}
