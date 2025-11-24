variable "project_id" {
  description = "The ID of the GCP project."
  type        = string
}

variable "region" {
  description = "The region for the GCP resources."
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "The zone for the GCP resources."
  type        = string
  default     = "us-central1-a"
}