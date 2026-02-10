# 3. IAM Role 생성 (Trust Policy 포함)
resource "aws_iam_role" "github_actions" {
  name = "my-github-actions-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            # 본인의 github org와 repo로 수정 필수!
            "token.actions.githubusercontent.com:sub" = "repo:alpha3002025/overtake-springbootsample:*"
          }
        }
      }
    ]
  })
}

# 4. ECR 권한 정책 생성 및 연결
resource "aws_iam_role_policy" "ecr_policy" {
  name = "github-actions-ecr-policy"
  role = aws_iam_role.github_actions.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:PutImage"
        ]
        Resource = "*" # 특정 ECR ARN으로 제한 권장
      }
    ]
  })
}

# 5. 생성된 Role ARN 출력 (GitHub Secrets에 등록할 값)
output "role_arn" {
  value = aws_iam_role.github_actions.arn
}
