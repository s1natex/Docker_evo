data "aws_iam_role" "ecs_task_exec_role" {
  name = "docker-evo-task-exec-role"
}

data "aws_iam_role" "ecs_task_role_main" {
  name = "docker-evo-task-role"
}

locals {
  tfstate_bucket        = "docker-evo-tfstate-eu-central-1-430316"
  tfstate_prefix        = "ecs"
  ddb_lock_table        = "docker-evo-eu-central-1-tf-lock"
  account_id            = "194722430316"
  region                = "eu-central-1"
  logs_group_arn_prefix = "arn:aws:logs:${local.region}:${local.account_id}:log-group:/ecs/docker-evo"
}

resource "aws_iam_policy" "gha_cd_perms" {
  name = "docker-evo-gha-cd-permissions"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid      = "S3ListBucketPrefix",
        Effect   = "Allow",
        Action   = ["s3:ListBucket"],
        Resource = "arn:aws:s3:::${local.tfstate_bucket}",
        Condition = {
          StringLike = {
            "s3:prefix" : [
              "${local.tfstate_prefix}",
              "${local.tfstate_prefix}/*"
            ]
          }
        }
      },
      {
        Sid    = "S3ObjectRW",
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:AbortMultipartUpload"
        ],
        Resource = "arn:aws:s3:::${local.tfstate_bucket}/${local.tfstate_prefix}/*"
      },
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
        Resource = "arn:aws:dynamodb:eu-central-1:${data.aws_caller_identity.current.account_id}:table/${local.ddb_lock_table}"
      },
      {
        Sid    = "EC2Describe",
        Effect = "Allow",
        Action = [
          "ec2:DescribeAvailabilityZones",
          "ec2:DescribeVpcs",
          "ec2:DescribeVpcAttribute",
          "ec2:DescribeSubnets",
          "ec2:DescribeRouteTables",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeNatGateways",
          "ec2:DescribeInternetGateways",
          "ec2:DescribeAddresses",
          "ec2:DescribeAddressesAttribute",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DescribeTags"
        ],
        Resource = "*"
      },
      {
        Sid    = "ELBv2Describe",
        Effect = "Allow",
        Action = [
          "elasticloadbalancing:DescribeLoadBalancers",
          "elasticloadbalancing:DescribeTargetGroups",
          "elasticloadbalancing:DescribeTargetHealth",
          "elasticloadbalancing:DescribeListeners",
          "elasticloadbalancing:DescribeRules",
          "elasticloadbalancing:DescribeTags"
        ],
        Resource = "*"
      },
      {
        Sid    = "LogsDescribe",
        Effect = "Allow",
        Action = [
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ],
        Resource = "*"
      },
      {
        Sid    = "LogsManageDockerEvo",
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:PutRetentionPolicy",
          "logs:DeleteLogGroup",
          "logs:TagLogGroup",
          "logs:UntagLogGroup",
          "logs:ListTagsForResource",
          "logs:TagResource",
          "logs:UntagResource"
        ],
        Resource = [
          "${local.logs_group_arn_prefix}",
          "${local.logs_group_arn_prefix}*"
        ]
      },
      {
        Sid    = "IAMRead",
        Effect = "Allow",
        Action = [
          "iam:GetRole",
          "iam:ListAttachedRolePolicies",
          "iam:ListRolePolicies",
          "iam:GetPolicy",
          "iam:GetPolicyVersion"
        ],
        Resource = "*"
      },
      {
        Sid    = "ECSDeploy",
        Effect = "Allow",
        Action = [
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
        Resource = "*"
      },
      {
        Sid    = "IAMPassTaskRoles",
        Effect = "Allow",
        Action = [
          "iam:PassRole",
          "iam:GetRole"
        ],
        Resource = [
          data.aws_iam_role.ecs_task_exec_role.arn,
          data.aws_iam_role.ecs_task_role_main.arn
        ]
      },
      {
        Sid    = "SecretsManagerDescribeOnly",
        Effect = "Allow",
        Action = [
          "secretsmanager:DescribeSecret",
          "secretsmanager:ListSecrets",
          "secretsmanager:ListSecretVersionIds",
          "secretsmanager:GetResourcePolicy"
        ],
        Resource = "*"
      }
    ]
  })
}
