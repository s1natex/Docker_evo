data "aws_iam_policy_document" "ecs_task_assume" {
  statement {
    actions = [
      "sts:AssumeRole"
    ]

    principals {
      type = "Service"
      identifiers = [
        "ecs-tasks.amazonaws.com"
      ]
    }
  }
}

resource "aws_iam_role_policy_attachment" "task_exec_secrets" {
  role       = aws_iam_role.task_execution.name
  policy_arn = aws_iam_policy.secrets_read.arn
}

resource "aws_iam_role" "task_execution" {
  name               = "${var.project}-task-exec-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume.json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "task_exec_ecr" {
  role       = aws_iam_role.task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "task_exec_cloudwatch" {
  role       = aws_iam_role.task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}

resource "aws_iam_role" "task_role" {
  name               = "${var.project}-task-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume.json

  tags = var.tags
}

data "aws_iam_policy_document" "secrets_read" {
  statement {
    actions = [
      "secretsmanager:GetSecretValue"
    ]

    resources = [
      aws_secretsmanager_secret.db_url.arn,
      "${aws_secretsmanager_secret.db_url.arn}:*"
    ]
  }
}

resource "aws_iam_policy" "secrets_read" {
  name   = "${var.project}-secrets-read"
  policy = data.aws_iam_policy_document.secrets_read.json
}

resource "aws_iam_role_policy_attachment" "task_role_secrets" {
  role       = aws_iam_role.task_role.name
  policy_arn = aws_iam_policy.secrets_read.arn
}
