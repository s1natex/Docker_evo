# Reuse existing:
# data "aws_iam_role" "gha_oidc_role" { name = "docker-evo-eu-central-1-gha-oidc-role" }

resource "aws_iam_role_policy_attachment" "gha_cd_ro_ec2" {
  role       = data.aws_iam_role.gha_oidc_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "gha_cd_ro_all" {
  role       = data.aws_iam_role.gha_oidc_role.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "gha_cd_ro_logs" {
  role       = data.aws_iam_role.gha_oidc_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsReadOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "gha_cd_ro_iam" {
  role       = data.aws_iam_role.gha_oidc_role.name
  policy_arn = "arn:aws:iam::aws:policy/IAMReadOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "gha_cd_ro_secrets" {
  role       = data.aws_iam_role.gha_oidc_role.name
  policy_arn = "arn:aws:iam::aws:policy/SecretsManagerReadWrite" # or SecretsManagerReadOnly if you don't create/update secrets via TF
}
