data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

locals {
  repositories = toset(var.repo_names)
}

resource "aws_ecr_repository" "this" {
  for_each = local.repositories

  name                 = each.value
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = merge(
    var.tags,
    {
      repository = each.value
    }
  )
}

resource "aws_ecr_lifecycle_policy" "this" {
  for_each = local.repositories

  repository = aws_ecr_repository.this[each.key].name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Expire untagged images older than var.lifecycle_untagged_expire_days days"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = var.lifecycle_untagged_expire_days
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Retain only the most recent var.lifecycle_keep_tagged_most_recent tagged images"
        selection = {
          tagStatus     = "tagged"
          tagPatternList = [
            "*"
          ]
          countType     = "imageCountMoreThan"
          countNumber   = var.lifecycle_keep_tagged_most_recent
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}
