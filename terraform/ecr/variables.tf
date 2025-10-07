variable "aws_region" {
  description = "AWS region to provision ECR repositories"
  type        = string
  default     = "eu-central-1"
}

variable "project" {
  description = "Project slug used for default repository names and tags"
  type        = string
  default     = "docker-evo"
}

variable "repo_names" {
  description = "List of ECR repository names to create"
  type        = list(string)
  default = [
    "docker-evo-frontend",
    "docker-evo-pass-gen"
  ]
}

variable "lifecycle_keep_tagged_most_recent" {
  description = "How many most-recent tagged images to keep per repo"
  type        = number
  default     = 30
}

variable "lifecycle_untagged_expire_days" {
  description = "Expire untagged images older than this many days"
  type        = number
  default     = 14
}

variable "tags" {
  description = "Common resource tags"
  type        = map(string)
  default = {
    app     = "docker-evo"
    managed = "terraform"
  }
}
