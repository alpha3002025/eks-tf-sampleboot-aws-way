# 1. Kubernetes Namespace & ServiceAccount
resource "kubernetes_namespace" "overtake" {
  metadata {
    name = "overtake"
  }
}

resource "kubernetes_service_account" "app_sa" {
  metadata {
    name      = "spring-boot-sa"
    namespace = kubernetes_namespace.overtake.metadata[0].name
  }
}

# 2. IAM Role (Pod Identity용)
resource "aws_iam_role" "app_role" {
  name = "EKSAppRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "pods.eks.amazonaws.com"
        }
        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
      }
    ]
  })
}

# 기존에 생성된 KMS Key 및 Secret 정보를 Data Source로 조회
data "aws_kms_key" "eks_app_key" {
  key_id = "alias/eks-app-sops-key" # KMS 생성 단계에서 만든 Alias 사용
}

data "aws_secretsmanager_secret" "app_secret" {
  name = "overtake-springbootsample/secret" # Secrets Manager 생성 단계에서 만든 이름 사용
}

# 권한 정책 연결 (Secrets Manager & KMS)
resource "aws_iam_role_policy" "app_policy" {
  name = "AppSecretsAccess"
  role = aws_iam_role.app_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "kms:Decrypt"
        ]
        Resource = [
          data.aws_secretsmanager_secret.app_secret.arn,
          data.aws_kms_key.eks_app_key.arn
        ]
      }
    ]
  })
}

# 3. Pod Identity Association (연결)
resource "aws_eks_pod_identity_association" "app" {
  cluster_name    = var.cluster_name
  namespace       = kubernetes_namespace.overtake.metadata[0].name
  service_account = kubernetes_service_account.app_sa.metadata[0].name
  role_arn        = aws_iam_role.app_role.arn
}

# 4. EKS Pod Identity Agent Addon (MUST be installed for Pod Identity to work)
resource "aws_eks_addon" "pod_identity" {
  cluster_name = var.cluster_name
  addon_name   = "eks-pod-identity-agent"
}
