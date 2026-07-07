variable "project" {
  type    = string
  default = "sauda"
}

variable "project_id" {
  type = string
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "location" {
  description = "GCS bucket location (e.g. US, EU, us-central1)"
  type        = string
  default     = "US"
}

variable "enable_versioning" {
  type    = bool
  default = false
}

variable "pdf_expiry_days" {
  type    = number
  default = 7
}

variable "labels" {
  type    = map(string)
  default = {}
}
