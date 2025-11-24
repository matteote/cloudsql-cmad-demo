variable "project_id" {
  description = "The ID of the GCP project."
  type        = string
}

variable "region" {
  description = "The region for the network resources."
  type        = string
}

variable "compute_api_service_id" {
  description = "The ID of the compute API service resource."
  type = any
}