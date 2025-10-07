output "alb_dns_name" {
  description = "Public URL of the frontend"
  value       = aws_lb.public.dns_name
}

output "service_discovery_namespace" {
  description = "Private DNS namespace used for service discovery"
  value       = aws_service_discovery_private_dns_namespace.ns.name
}

output "passgen_discovery_hostname" {
  description = "Backend hostname reachable from the frontend task"
  value       = "pass-gen.svc.local"
}

output "rds_endpoint" {
  description = "RDS PostgreSQL endpoint"
  value       = aws_db_instance.postgres.address
  sensitive   = false
}

output "database_secret_arn" {
  description = "Secrets Manager secret containing DATABASE_URL"
  value       = aws_secretsmanager_secret.db_url.arn
}
