# 1. IAM Role (IRSA)
module "lb_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.52"

  role_name                              = "AmazonEKSLoadBalancerControllerRole"
  attach_load_balancer_controller_policy = true

  oidc_providers = {
    main = {
      provider_arn               = data.aws_iam_openid_connect_provider.oidc.arn
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
    }
  }
}

# 2. Kubernetes ServiceAccount
# Helm Chart가 자동 생성하는 SA를 사용하는 경우 이 부분은 생략하고 Helm Value에서 Role ARN만 주입할 수도 있습니다.
# 하지만 Terraform으로 명시적으로 관리하려면 아래와 같이 작성합니다.
resource "kubernetes_service_account" "aws_load_balancer_controller" {
  metadata {
    name      = "aws-load-balancer-controller"
    namespace = "kube-system"
    annotations = {
      "eks.amazonaws.com/role-arn" = module.lb_role.iam_role_arn
    }
  }
}
