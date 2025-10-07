data "aws_iam_role" "gha_oidc_role" {
  name = "docker-evo-eu-central-1-gha-oidc-role"
}

data "aws_iam_role" "ecs_task_exec" {
  name = "docker-evo-task-exec-role"
}

data "aws_iam_role" "ecs_task_role" {
  name = "docker-evo-task-role"
}

locals {
  tfstate_bucket = "docker-evo-tfstate-eu-central-1-430316"
  tfstate_prefix = "ecs"
  ddb_lock_table = "docker-evo-tflock"
}

resource "aws_iam_policy" "gha_cd_perms" {
  name = "docker-evo-gha-cd-permissions"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid: "S3ListBucketPrefix",
        Effect: "Allow",
        Action: ["s3:ListBucket"],
        Resource: "arn:aws:s3:::${local.tfstate_bucket}",
        Condition: {
          StringLike: {
            "s3:prefix": [
              "${local.tfstate_prefix}",
              "${local.tfstate_prefix}/*"
            ]
          }
        }
      },
      {
        Sid: "S3ObjectRW",
        Effect: "Allow",
        Action: [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:AbortMultipartUpload"
        ],
        Resource: "arn:aws:s3:::${local.tfstate_bucket}/${local.tfstate_prefix}/*"
      },

      {
        Sid: "DDBLockRW",
        Effect: "Allow",
        Action: [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem",
          "dynamodb:UpdateItem",
          "dynamodb:DescribeTable"
        ],
        Resource: "arn:aws:dynamodb:*:*:table/${local.ddb_lock_table}"
      },

      {
        Sid: "ECSRegisterAndDescribe",
        Effect: "Allow",
        Action: [
          "ecs:RegisterTaskDefinition",
          "ecs:DeregisterTaskDefinition",
          "ecs:DescribeTaskDefinition",
          "ecs:ListTaskDefinitions",
          "ecs:DescribeClusters",
          "ecs:DescribeServices",
          "ecs:UpdateService",
          "ecs:DescribeTasks",
          "ecs:ListServices"
        ],
        Resource: "*"
      },

      {
        Sid: "SecretsManagerDescribeOnly",
        Effect: "Allow",
        Action: [
          "secretsmanager:DescribeSecret",
          "secretsmanager:ListSecrets",
          "secretsmanager:ListSecretVersionIds",
          "secretsmanager:GetResourcePolicy"
        ],
        Resource: "*"
      },

      {
        Sid: "IAMPassTaskRoles",
        Effect: "Allow",
        Action: [
          "iam:PassRole",
          "iam:GetRole"
        ],
        Resource: [
          "${data.aws_iam_role.ecs_task_exec.arn}",
          "${data.aws_iam_role.ecs_task_role.arn}"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "gha_cd_perms_attach" {
  role       = data.aws_iam_role.gha_oidc_role.name
  policy_arn = aws_iam_policy.gha_cd_perms.arn
}
