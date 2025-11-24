output "instance_name" {
  description = "The name of the Windows client VM."
  value       = google_compute_instance.windows_client_vm.name
}
