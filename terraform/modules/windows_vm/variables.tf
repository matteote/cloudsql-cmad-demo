variable "project_id" {
  description = "The ID of the GCP project."
  type        = string
}

variable "zone" {
  description = "The zone for the VM."
  type        = string
}

variable "network_name" {
  description = "The name of the VPC network."
  type        = string
}

variable "subnet_name" {
  description = "The name of the subnetwork."
  type        = string
}

variable "windows_image_family" {
  description = "The image family for the Windows Server."
  type        = string
  default     = "windows-2019-dc"
}

variable "domain_name" {
  description = "The name of the Active Directory domain."
  type        = string
  default     = "example.com"
}
