output "sql_server_password" {
  description = "The password for the SQL Server instance."
  value       = random_password.sql_password.result
  sensitive   = true
}

output "sql_server_instance_name" {
  description = "The name of the SQL Server instance."
  value       = google_sql_database_instance.sql_server_instance.name
}

output "sql_server_ip_address" {
  description = "The private IP address of the SQL Server instance."
  value       = google_sql_database_instance.sql_server_instance.private_ip_address
}
