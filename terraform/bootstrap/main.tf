data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

locals {
  name_prefix = "${var.project}-${data.aws_region.current.name}"

  rand_suffix = substr(
    data.aws_caller_identity.current.account_id,
    length(data.aws_caller_identity.current.account_id) - 6,
    6
  )

  s3_bucket = lower("${var.project}-tfstate-${data.aws_region.current.name}-${local.rand_suffix}")
}

# -----------------------------
# Remote backend resources
# -----------------------------

resource "aws_s3_bucket" "tf_state" {
  bucket = local.s3_bucket

  tags = var.tags
}

resource "aws_s3_bucket_versioning" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_dynamodb_table" "tf_lock" {
  name         = "${local.name_prefix}-tf-lock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }

  tags = var.tags
}

# -----------------------------
# GitHub OIDC
# -----------------------------

resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    var.oidc_audience
  ]

  thumbprint_list = var.oidc_thumbprints
}

data "aws_iam_policy_document" "gha_assume_role" {
  statement {
    actions = [
      "sts:AssumeRoleWithWebIdentity"
    ]

    effect = "Allow"

    principals {
      type = "Federated"

      identifiers = [
        aws_iam_openid_connect_provider.github.arn
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"

      values = [
        var.oidc_audience
      ]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"

      values = [
        "repo:${var.repo_owner}/${var.repo_name}:*"
      ]
    }
  }
}

resource "aws_iam_role" "gha_role" {
  name        = "${local.name_prefix}-gha-oidc-role"
  description = "Role assumed via GitHub OIDC by ${var.repo_owner}/${var.repo_name}"

  assume_role_policy = data.aws_iam_policy_document.gha_assume_role.json

  tags = var.tags
}
