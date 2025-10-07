variable "project" {
  description = "Short project name (used in resource names/tags)"
  type        = string
  default     = "docker-evo"
}

variable "aws_region" {
  description = "AWS region to provision bootstrap resources"
  type        = string
  default     = "eu-central-1"
}

variable "repo_owner" {
  description = "GitHub repository owner"
  type        = string
  default     = "s1natex"
}

variable "repo_name" {
  description = "GitHub repository name"
  type        = string
  default     = "Docker_evo"
}

variable "oidc_audience" {
  description = "OIDC audience for GitHub Actions (usually sts.amazonaws.com)"
  type        = string
  default     = "sts.amazonaws.com"
}

variable "oidc_thumbprints" {
  description = "Thumbprints for token.actions.githubusercontent.com"
  type        = list(string)
  default = [
    "6938fd4d98bab03faadb97b34396831e3780aea1"
  ]
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default = {
    app     = "docker-evo"
    managed = "terraform"
  }
}
