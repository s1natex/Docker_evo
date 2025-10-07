data "aws_iam_role" "gha_oidc_role" {
  name = "docker-evo-eu-central-1-gha-oidc-role"
}

resource "aws_iam_policy" "gha_ecr_push" {
  name = "docker-evo-gha-ecr-push"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = ["sts:GetCallerIdentity"],
        Resource = "*"
      },
      {
        Effect   = "Allow",
        Action   = ["ecr:GetAuthorizationToken"],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:PutImage",
          "ecr:BatchGetImage",
          "ecr:DescribeImages",
          "ecr:DescribeRepositories"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "gha_ecr_push_attach" {
  role       = data.aws_iam_role.gha_oidc_role.name
  policy_arn = aws_iam_policy.gha_ecr_push.arn
}
