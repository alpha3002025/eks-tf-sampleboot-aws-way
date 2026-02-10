# 1. KMS Key 생성
resource "aws_kms_key" "eks_app_key" {
  description             = "EKS App & SOPS Key"
  deletion_window_in_days = 7
}

# 2. KMS Alias 생성
resource "aws_kms_alias" "eks_app_key_alias" {
  name          = "alias/eks-app-sops-key"
  target_key_id = aws_kms_key.eks_app_key.key_id
}

output "kms_key_arn" {
  value = aws_kms_key.eks_app_key.arn
}

# 3. Secrets Manager 시크릿 생성
resource "aws_secretsmanager_secret" "app_secret" {
  name        = "my-spring-app/secret"
  description = "Database credentials for Spring Boot App"
  kms_key_id  = aws_kms_key.eks_app_key.id
}

resource "aws_secretsmanager_secret_version" "app_secret_ver" {
  secret_id = aws_secretsmanager_secret.app_secret.id
  secret_string = jsonencode({
    username = "admin"
    password = "secret_password"
  })
}
