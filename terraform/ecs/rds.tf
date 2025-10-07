resource "aws_db_subnet_group" "this" {
  name = "${var.project}-db-subnets"

  subnet_ids = [
    for s in aws_subnet.private : s.id
  ]

  tags = var.tags
}

resource "random_password" "db_master" {
  length  = 20
  special = true
}

resource "aws_db_instance" "postgres" {
  identifier          = "${var.project}-pg"
  engine              = "postgres"
  engine_version      = "16.3"
  instance_class      = var.db_instance_class
  db_name             = var.db_name
  username            = var.db_username
  password            = random_password.db_master.result
  allocated_storage   = var.db_allocated_storage
  storage_type        = "gp3"
  multi_az            = var.db_multi_az
  publicly_accessible = false
  vpc_security_group_ids = [
    aws_security_group.rds.id
  ]
  db_subnet_group_name    = aws_db_subnet_group.this.name
  deletion_protection     = false
  skip_final_snapshot     = true
  backup_retention_period = 7

  tags = var.tags
}

resource "random_id" "secret_suffix" {
  byte_length = 3
}

resource "aws_secretsmanager_secret" "db_url" {
  name = "${var.project}-database-url-${random_id.secret_suffix.hex}"

  tags = var.tags
}

resource "aws_secretsmanager_secret_version" "db_url" {
  secret_id = aws_secretsmanager_secret.db_url.id

  secret_string = jsonencode(
    {
      DATABASE_URL = "postgresql://${var.db_username}:${urlencode(random_password.db_master.result)}@${aws_db_instance.postgres.address}:5432/${var.db_name}"
    }
  )
}
