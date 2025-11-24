variable "project_id" {
  description = "The ID of the project in which to provision resources."
  type        = string
}

variable "region" {
  description = "The region in which to provision resources."
  type        = string
}

variable "network_id" {
  description = "The ID of the VPC network."
  type        = string
}

variable "private_vpc_connection_id" {
  description = "The ID of the private VPC connection."
  type        = string
}