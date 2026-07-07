variable "project" {
  type    = string
  default = "sauda"
}

variable "domain" {
  description = "Custom domain (e.g. sauda.io) — leave empty to skip Route 53 setup"
  type        = string
  default     = ""
}

variable "alb_dns_name" {
  type = string
}

variable "cloudfront_domain_name" {
  type = string
}

variable "cloudfront_hosted_zone_id" {
  type = string
}

variable "gcp_lb_ip" {
  description = "GCP Cloud Load Balancer static IP address"
  type        = string
  default     = "<GCP_LB_IP>"
}

variable "tags" {
  type    = map(string)
  default = {}
}
