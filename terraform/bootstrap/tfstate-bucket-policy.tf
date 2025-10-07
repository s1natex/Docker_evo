data "aws_s3_bucket" "tfstate" {
  bucket = "docker-evo-tfstate-eu-central-1-430316"
}

data "aws_iam_policy_document" "tfstate_bucket_policy" {
  statement {
    sid = "AllowGHARoleListBucket"
    principals {
      type        = "AWS"
      identifiers = [data.aws_iam_role.gha_oidc_role.arn]
    }
    actions   = ["s3:ListBucket"]
    resources = [data.aws_s3_bucket.tfstate.arn]
    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = ["ecs", "ecs/*"]
    }
  }

  statement {
    sid = "AllowGHARoleObjectRW"
    principals {
      type        = "AWS"
      identifiers = [data.aws_iam_role.gha_oidc_role.arn]
    }
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:AbortMultipartUpload"
    ]
    resources = ["${data.aws_s3_bucket.tfstate.arn}/ecs/*"]
  }
}

resource "aws_s3_bucket_policy" "tfstate" {
  bucket = data.aws_s3_bucket.tfstate.id
  policy = data.aws_iam_policy_document.tfstate_bucket_policy.json
}
