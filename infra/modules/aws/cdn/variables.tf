variable "project" {
  type    = string
  default = "sauda"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "frontend_bucket_regional_domain" {
  type = string
}

variable "alb_domain_name" {
  description = "ALB DNS name (no https://) — e.g. sauda-alb-123456.us-east-1.elb.amazonaws.com"
  type        = string
}

variable "domain" {
  description = "Custom domain (e.g. sauda.io) — leave empty to use CloudFront default URL"
  type        = string
  default     = ""
}

variable "acm_certificate_arn" {
  description = "ACM certificate ARN (must be in us-east-1 for CloudFront)"
  type        = string
  default     = ""
}

variable "waf_rate_limit" {
  type    = number
  default = 1000
}

variable "tags" {
  type    = map(string)
  default = {}
}
