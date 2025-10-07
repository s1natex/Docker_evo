# Reuse data.aws_iam_role.gha_oidc_role from your other bootstrap file

resource "aws_iam_policy" "gha_tf_lock_ddb" {
  name = "docker-evo-gha-terraform-lock-ddb"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "DDBLockRW",
        Effect = "Allow",
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem",
          "dynamodb:UpdateItem",
          "dynamodb:DescribeTable"
        ],
        Resource = "arn:aws:dynamodb:${local.region}:${local.account_id}:table/${local.ddb_lock_table}"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "gha_tf_lock_ddb_attach" {
  role       = data.aws_iam_role.gha_oidc_role.name
  policy_arn = aws_iam_policy.gha_tf_lock_ddb.arn
}
