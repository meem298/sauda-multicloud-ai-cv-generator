variable "project" {
  type    = string
  default = "sauda"
}

variable "project_id" {
  type = string
}

variable "rate_limit_count" {
  description = "Max requests per 5 minutes per IP before throttling"
  type        = number
  default     = 1000
}

variable "labels" {
  type    = map(string)
  default = {}
}
