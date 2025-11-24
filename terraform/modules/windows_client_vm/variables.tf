variable "project_id" {
  description = "The project ID to deploy to."
  type        = string
}

variable "zone" {
  description = "The zone to deploy to."
  type        = string
}

variable "network_name" {
  description = "The name of the network to deploy to."
  type        = string
}

variable "subnet_name" {
  description = "The name of the subnetwork to deploy to."
  type        = string
}

variable "admin_password" {
  description = "The password for the admin user."
  type        = string
  sensitive   = true
}

variable "windows_vm_ip_address" {
  description = "The IP address of the windows_vm."
  type        = string
}