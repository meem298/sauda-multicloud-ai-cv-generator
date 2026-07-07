variable "project" {
  type    = string
  default = "sauda"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "enable_versioning" {
  type    = bool
  default = false
}

variable "pdf_expiry_days" {
  description = "Days before PDFs are auto-deleted from S3"
  type        = number
  default     = 7
}

variable "cloudfront_distribution_arn" {
  description = "CloudFront distribution ARN for OAC bucket policy"
  type        = string
  default     = ""
}

variable "tags" {
  type    = map(string)
  default = {}
}
