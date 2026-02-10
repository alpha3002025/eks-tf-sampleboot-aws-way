# 0. KMS Key 조회 (다른 State에서 생성됨)
data "aws_kms_key" "eks_app_key" {
  key_id = "alias/eks-app-sops-key"
}

# 1. 시크릿 메타데이터 정의 (껍데기)
resource "aws_secretsmanager_secret" "app_secret" {
  name        = "overtake-springbootsample/secret"
  kms_key_id  = data.aws_kms_key.eks_app_key.arn
  description = "Application Runtime Secrets"
}

# 2. 실제 시크릿 값 저장 (내용물)
resource "aws_secretsmanager_secret_version" "app_secret_val" {
  secret_id = aws_secretsmanager_secret.app_secret.id
  secret_string = jsonencode({
    secret = "Decrypted_Secret_Value_1234"
  })
}
