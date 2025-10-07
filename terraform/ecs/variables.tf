variable "project" {
  description = "Project slug for names and tags"
  type        = string
  default     = "docker-evo"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-central-1"
}

variable "ecr_repo_frontend" {
  description = "ECR repo name for frontend"
  type        = string
  default     = "docker-evo-frontend"
}

variable "ecr_repo_pass_gen" {
  description = "ECR repo name for pass-gen"
  type        = string
  default     = "docker-evo-pass-gen"
}

variable "image_tag" {
  description = "Container image tag to deploy"
  type        = string
  default     = "initial"
}

variable "desired_count_frontend" {
  description = "Desired count for frontend ECS service"
  type        = number
  default     = 2
}

variable "desired_count_passgen" {
  description = "Desired count for pass-gen ECS service"
  type        = number
  default     = 2
}

variable "frontend_cpu" {
  description = "Frontend task CPU (Fargate)"
  type        = number
  default     = 256
}

variable "frontend_memory" {
  description = "Frontend task memory (MiB)"
  type        = number
  default     = 512
}

variable "passgen_cpu" {
  description = "Pass-gen task CPU (Fargate)"
  type        = number
  default     = 256
}

variable "passgen_memory" {
  description = "Pass-gen task memory (MiB)"
  type        = number
  default     = 512
}

variable "vpc_cidr" {
  description = "VPC CIDR"
  type        = string
  default     = "10.60.0.0/16"
}

variable "public_subnets" {
  description = "Public subnets CIDRs"
  type        = list(string)
  default = [
    "10.60.0.0/24",
    "10.60.1.0/24"
  ]
}

variable "private_subnets" {
  description = "Private subnets CIDRs"
  type        = list(string)
  default = [
    "10.60.10.0/24",
    "10.60.11.0/24"
  ]
}

variable "db_name" {
  description = "PostgreSQL database name"
  type        = string
  default     = "dockerevo"
}

variable "db_username" {
  description = "PostgreSQL master username"
  type        = string
  default     = "dockerevo"
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t4g.micro"
}

variable "db_allocated_storage" {
  description = "RDS storage in GiB"
  type        = number
  default     = 20
}

variable "db_multi_az" {
  description = "Enable Multi-AZ for RDS"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Common resource tags"
  type        = map(string)
  default = {
    app     = "docker-evo"
    managed = "terraform"
  }
}
