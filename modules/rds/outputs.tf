output "db_instance_endpoint" {
  description = "The connection endpoint for the database"
  value       = aws_db_instance.this.endpoint
}

output "db_instance_arn" {
  value = aws_db_instance.this.arn
}
