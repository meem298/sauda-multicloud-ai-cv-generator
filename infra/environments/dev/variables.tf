variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "gcp_project_id" {
  description = "GCP Project ID — leave empty until GCP is available"
  type        = string
  default     = ""
}

variable "gcp_region" {
  type    = string
  default = "us-central1"
}

variable "domain" {
  description = "Custom domain (e.g. sauda.io) — leave empty to use auto-generated URLs"
  type        = string
  default     = ""
}

variable "acm_certificate_arn" {
  description = "ACM certificate ARN for HTTPS (us-east-1) — leave placeholder if no domain yet"
  type        = string
  default     = "<ACM_CERTIFICATE_ARN>"
}

variable "image_tag" {
  description = "Docker image tag to deploy — e.g. latest, v1.2.3, git-sha"
  type        = string
  default     = "latest"
}

variable "alert_email" {
  description = "Email for monitoring alerts"
  type        = string
  default     = "<YOUR_OPS_EMAIL>"
}
