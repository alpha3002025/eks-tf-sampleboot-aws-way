# 1. KMS Key 생성
resource "aws_kms_key" "eks_app_key" {
  description             = "EKS App & SOPS Key"
  deletion_window_in_days = 7

  # 키 정책 명시적 정의 (필수)
  # 루트 사용자에게 모든 권한을 위임하여 IAM Policy로 제어 가능하게 함
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      }
    ]
  })
}

# 2. KMS Alias 생성
resource "aws_kms_alias" "eks_app_key_alias" {
  name          = "alias/eks-app-sops-key"
  target_key_id = aws_kms_key.eks_app_key.key_id
}

output "kms_key_arn" {
  value = aws_kms_key.eks_app_key.arn
}

# # 3. Secrets Manager 시크릿 생성
# 3. Secrets Manager 시크릿 생성 (secretsmanager 모듈에서 관리하므로 주석 처리)
# resource "aws_secretsmanager_secret" "app_secret" {
#   name        = "overtake-springbootsample/secret"
#   description = "Database credentials for Spring Boot App"
#   kms_key_id  = aws_kms_key.eks_app_key.id
# }

# resource "aws_secretsmanager_secret_version" "app_secret_ver" {
#   secret_id = aws_secretsmanager_secret.app_secret.id
#   secret_string = jsonencode({
#     secret = "Decrypted_Secret_Value_1234"
#   })
# }
