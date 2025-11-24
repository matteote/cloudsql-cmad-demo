output "admin_password" {
  description = "The password for the admin user."
  value       = random_password.admin_password.result
  sensitive   = true
}

output "setupadmin_password" {
  description = "The password for the setupadmin user."
  value       = random_password.setupadmin_password.result
  sensitive   = true
}

output "instance_name" {
  description = "The name of the Windows VM."
  value       = google_compute_instance.windows_vm.name
}

output "zone" {

  description = "The zone of the Windows VM."

  value       = google_compute_instance.windows_vm.zone

}



output "ip_address" {

  description = "The IP address of the Windows VM."

  value       = google_compute_instance.windows_vm.network_interface[0].network_ip

}
