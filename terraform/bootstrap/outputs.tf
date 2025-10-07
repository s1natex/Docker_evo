output "backend_bucket" {
  description = "S3 bucket for Terraform remote backend"
  value       = aws_s3_bucket.tf_state.bucket
}

output "backend_dynamodb_table" {
  description = "DynamoDB table for Terraform state locking"
  value       = aws_dynamodb_table.tf_lock.name
}

output "github_oidc_provider_arn" {
  description = "IAM OIDC provider ARN for GitHub"
  value       = aws_iam_openid_connect_provider.github.arn
}

output "github_actions_role_arn" {
  description = "IAM role ARN that GitHub Actions can assume"
  value       = aws_iam_role.gha_role.arn
}

output "remote_backend_snippet" {
  description = "Paste into terraform { backend \"s3\" { ... } } of your real stacks"
  value       = <<EOT
backend "s3" {
  bucket         = "${aws_s3_bucket.tf_state.bucket}"
  key            = "terraform.tfstate"
  region         = "${var.aws_region}"
  dynamodb_table = "${aws_dynamodb_table.tf_lock.name}"
  encrypt        = true
}
EOT
}
