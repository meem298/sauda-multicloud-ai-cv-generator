variable "project" {
  type    = string
  default = "sauda"
}

variable "project_id" {
  type = string
}

variable "cloudrun_domain" {
  description = "Cloud Run service URL (without https://) for uptime check"
  type        = string
}

variable "notification_channel_ids" {
  type    = list(string)
  default = []
}

variable "alert_email" {
  description = "Email address for monitoring alerts"
  type        = string
  default     = "<YOUR_OPS_EMAIL>"
}

variable "labels" {
  type    = map(string)
  default = {}
}
