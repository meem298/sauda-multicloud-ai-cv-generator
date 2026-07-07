variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "gcp_project_id" {
  type = string
}

variable "gcp_region" {
  type    = string
  default = "us-central1"
}

variable "domain" {
  description = "Custom domain (e.g. sauda.io)"
  type        = string
  default     = ""
}

variable "acm_certificate_arn" {
  type    = string
  default = "<ACM_CERTIFICATE_ARN>"
}

variable "image_tag" {
  description = "Docker image tag to deploy — e.g. latest, v1.2.3, git-sha"
  type        = string
  default     = "latest"
}

variable "alert_email" {
  type    = string
  default = "<YOUR_OPS_EMAIL>"
}

variable "sns_alarm_arns" {
  description = "SNS topic ARNs for CloudWatch alarm notifications"
  type        = list(string)
  default     = []
}
