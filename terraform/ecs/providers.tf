terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.57"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }

  backend "s3" {
    bucket         = "docker-evo-tfstate-eu-central-1-430316"
    key            = "ecs/terraform.tfstate"
    region         = "eu-central-1"
    dynamodb_table = "docker-evo-eu-central-1-tf-lock"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region
}
