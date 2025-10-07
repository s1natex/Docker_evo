resource "aws_iam_policy" "gha_ecs_mutate" {
  name = "docker-evo-gha-ecs-mutate"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "ECSMutate",
        Effect = "Allow",
        Action = [
          "ecs:RegisterTaskDefinition",
          "ecs:DeregisterTaskDefinition",
          "ecs:UpdateService",
          "ecs:DescribeTaskDefinition",
          "ecs:DescribeClusters",
          "ecs:DescribeServices",
          "ecs:DescribeTasks",
          "ecs:ListTaskDefinitions",
          "ecs:ListServices",
          "ecs:TagResource",
          "ecs:UntagResource"
        ],
        Resource = "*"
      },
      {
        Sid    = "PassTaskRoles",
        Effect = "Allow",
        Action = [
          "iam:PassRole",
          "iam:GetRole"
        ],
        Resource = [
          "arn:aws:iam::194722430316:role/docker-evo-task-exec-role",
          "arn:aws:iam::194722430316:role/docker-evo-task-role"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "gha_ecs_mutate_attach" {
  role       = data.aws_iam_role.gha_oidc_role.name
  policy_arn = aws_iam_policy.gha_ecs_mutate.arn
}
